import { IncomingMessage } from "node:http";
import { Server as HttpServer } from "node:http";
import { WebSocketServer, WebSocket } from "ws";
import { resolveUserIdFromToken } from "./authService.js";
import { ensureSessionParticipant } from "./sessionService.js";

interface JoinRoomMessage {
  type: "join-room";
  roomCode: string;
}

interface RelayMessage {
  type: "offer" | "answer" | "ice-candidate";
  roomCode: string;
  targetUserId: string;
  payload: unknown;
}

interface RoomBroadcastMessage {
  type: "sync-code";
  roomCode: string;
  payload: unknown;
}

interface LeaveRoomMessage {
  type: "leave-room";
  roomCode: string;
}

type ClientMessage = JoinRoomMessage | RelayMessage | RoomBroadcastMessage | LeaveRoomMessage;

type RoomMembers = Map<string, WebSocket>;
interface RoomCodeSnapshot {
  text: string;
  language: string;
  updatedAt: number;
  fromUserId: string;
}
const rooms = new Map<string, RoomMembers>();
const roomSnapshots = new Map<string, RoomCodeSnapshot>();
const socketIdentity = new WeakMap<WebSocket, { roomCode: string; userId: string }>();
const socketUsers = new WeakMap<WebSocket, { userId: string }>();
const socketAlive = new WeakMap<WebSocket, boolean>();

function sendJson(socket: WebSocket, payload: object): void {
  if (socket.readyState === WebSocket.OPEN) {
    socket.send(JSON.stringify(payload));
  }
}

function getQueryParam(req: IncomingMessage, name: string): string {
  const base = "http://localhost";
  const parsed = new URL(req.url || "/", base);
  return String(parsed.searchParams.get(name) || "").trim();
}

function isAllowedWsOrigin(origin: string): boolean {
  const normalized = origin.replace(/\/+$/, "");
  const configuredOrigins = String(process.env.ALLOWED_AUTH_REDIRECTS || "")
    .split(",")
    .map((item) => item.trim().replace(/\/+$/, ""))
    .filter(Boolean);

  if (configuredOrigins.includes(normalized)) {
    return true;
  }
  if (/^http:\/\/(localhost|127\.0\.0\.1):\d+$/i.test(normalized)) {
    return true;
  }
  return /^https:\/\/.+\.ngrok-free\.app$/i.test(normalized);
}

function broadcastRoom(roomCode: string, payload: object, exceptUserId?: string): void {
  const members = rooms.get(roomCode);
  if (!members) return;
  for (const [userId, socket] of members.entries()) {
    if (exceptUserId && userId === exceptUserId) continue;
    sendJson(socket, payload);
  }
}

function leaveRoom(roomCode: string, userId: string): void {
  const members = rooms.get(roomCode);
  if (!members) return;
  members.delete(userId);
  broadcastRoom(roomCode, { type: "participant-left", roomCode, userId }, userId);
  if (members.size === 0) {
    rooms.delete(roomCode);
  }
}

function resolveAuthenticatedUserId(socket: WebSocket): string {
  const identity = socketUsers.get(socket);
  if (!identity?.userId) {
    throw new Error("Socket is not authenticated.");
  }
  return identity.userId;
}

function ensureJoinedRoom(socket: WebSocket, roomCode: string): { roomCode: string; userId: string } {
  const identity = socketIdentity.get(socket);
  if (!identity || identity.roomCode !== roomCode) {
    throw new Error("Socket is not joined to this room.");
  }
  return identity;
}

export function setupSignalingServer(server: HttpServer): void {
  const wss = new WebSocketServer({ server, path: "/ws" });
  const heartbeatInterval = setInterval(() => {
    for (const client of wss.clients) {
      const isAlive = socketAlive.get(client);
      if (isAlive === false) {
        client.terminate();
        continue;
      }
      socketAlive.set(client, false);
      client.ping();
    }
  }, 25000);

  wss.on("connection", (socket, req) => {
    const origin = String(req.headers.origin || "").trim();
    if (origin && !isAllowedWsOrigin(origin)) {
      sendJson(socket, { type: "error", message: "WebSocket origin blocked." });
      socket.close(1008, "Origin blocked");
      return;
    }

    const token = getQueryParam(req, "token");
    const userId = resolveUserIdFromToken(token);

    if (!userId) {
      sendJson(socket, { type: "error", message: "Unauthorized websocket connection." });
      socket.close(1008, "Unauthorized");
      return;
    }

    socketUsers.set(socket, { userId });
    socketAlive.set(socket, true);
    sendJson(socket, { type: "connected", userId });
    socket.on("pong", () => {
      socketAlive.set(socket, true);
    });

    socket.on("message", (rawMessage) => {
      try {
        const message = JSON.parse(String(rawMessage)) as ClientMessage;

        if (message.type === "join-room") {
          const roomCode = String(message.roomCode || "").trim();
          const authUserId = resolveAuthenticatedUserId(socket);
          if (!roomCode) {
            sendJson(socket, { type: "error", message: "roomCode is required." });
            return;
          }

          ensureSessionParticipant(roomCode, authUserId);

          const existingIdentity = socketIdentity.get(socket);
          if (existingIdentity && existingIdentity.roomCode !== roomCode) {
            leaveRoom(existingIdentity.roomCode, existingIdentity.userId);
          }

          let members = rooms.get(roomCode);
          if (!members) {
            members = new Map<string, WebSocket>();
            rooms.set(roomCode, members);
          }

          members.set(authUserId, socket);
          socketIdentity.set(socket, { roomCode, userId: authUserId });

          sendJson(socket, {
            type: "room-state",
            roomCode,
            participants: [...members.keys()]
          });
          const snapshot = roomSnapshots.get(roomCode);
          if (snapshot) {
            sendJson(socket, {
              type: "code-snapshot",
              roomCode,
              fromUserId: snapshot.fromUserId,
              payload: snapshot
            });
          }

          broadcastRoom(roomCode, { type: "participant-joined", roomCode, userId: authUserId }, authUserId);
          return;
        }

        if (message.type === "leave-room") {
          const identity = ensureJoinedRoom(socket, message.roomCode);
          leaveRoom(identity.roomCode, identity.userId);
          socketIdentity.delete(socket);
          return;
        }

        if (
          message.type === "offer" ||
          message.type === "answer" ||
          message.type === "ice-candidate"
        ) {
          const identity = ensureJoinedRoom(socket, message.roomCode);
          const members = rooms.get(identity.roomCode);
          const targetSocket = members?.get(message.targetUserId);
          if (!targetSocket) {
            sendJson(socket, {
              type: "error",
              message: `Target user ${message.targetUserId} is not connected.`
            });
            return;
          }
          sendJson(targetSocket, {
            type: message.type,
            roomCode: identity.roomCode,
            fromUserId: identity.userId,
            payload: message.payload
          });
          return;
        }

        if (message.type === "sync-code") {
          const identity = ensureJoinedRoom(socket, message.roomCode);
          const payload = message.payload as Partial<RoomCodeSnapshot> | null;
          const text = typeof payload?.text === "string" ? payload.text : "";
          const language = typeof payload?.language === "string" ? payload.language : "python3";
          const updatedAt = Number(payload?.updatedAt || Date.now());
          roomSnapshots.set(identity.roomCode, {
            text,
            language,
            updatedAt: Number.isFinite(updatedAt) ? updatedAt : Date.now(),
            fromUserId: identity.userId
          });
          broadcastRoom(
            identity.roomCode,
            {
              type: "sync-code",
              roomCode: identity.roomCode,
              fromUserId: identity.userId,
              payload: message.payload
            },
            identity.userId
          );
        }
      } catch (error) {
        sendJson(socket, {
          type: "error",
          message: (error as Error)?.message || "Invalid websocket payload."
        });
      }
    });

    socket.on("close", () => {
      const identity = socketIdentity.get(socket);
      socketAlive.delete(socket);
      if (!identity) return;
      leaveRoom(identity.roomCode, identity.userId);
      socketIdentity.delete(socket);
    });
  });

  wss.on("close", () => {
    clearInterval(heartbeatInterval);
  });
}
