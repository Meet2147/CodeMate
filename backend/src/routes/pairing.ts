import { Router } from "express";
import { AuthenticatedRequest } from "../middleware/auth.js";
import {
  acceptInvite,
  createInvite,
  declineInvite,
  ensureSessionOwner,
  endSession,
  getSessionByRoomCode,
  getUserById,
  joinSession,
  listInvitesForReceiver,
  startSession
} from "../services/sessionService.js";

const router = Router();

router.post("/invite", (req, res) => {
  try {
    const senderUserId = (req as AuthenticatedRequest).auth.userId;
    const receiverGithubUsername = String(req.body?.receiverGithubUsername || "").trim();
    const roomCode = String(req.body?.roomCode || "").trim();
    const problemId = String(req.body?.problemId || "").trim();

    if (!receiverGithubUsername) {
      return res.status(400).json({ error: "receiverGithubUsername is required" });
    }

    const invite = createInvite(
      senderUserId,
      receiverGithubUsername,
      roomCode || undefined,
      problemId || undefined
    );
    return res.status(201).json({ invite });
  } catch (error) {
    return res.status(400).json({ error: (error as Error).message });
  }
});

router.post("/accept", (req, res) => {
  try {
    const inviteId = String(req.body?.inviteId || "").trim();
    const authUser = getUserById((req as AuthenticatedRequest).auth.userId);
    const receiverGithubUsername = authUser?.githubUsername || "";
    if (!receiverGithubUsername) {
      return res.status(404).json({ error: "Authenticated user not found." });
    }
    const invite = acceptInvite(inviteId, receiverGithubUsername);
    return res.json({ invite });
  } catch (error) {
    return res.status(400).json({ error: (error as Error).message });
  }
});

router.post("/decline", (req, res) => {
  try {
    const inviteId = String(req.body?.inviteId || "").trim();
    const authUser = getUserById((req as AuthenticatedRequest).auth.userId);
    const receiverGithubUsername = authUser?.githubUsername || "";
    if (!receiverGithubUsername) {
      return res.status(404).json({ error: "Authenticated user not found." });
    }
    const invite = declineInvite(inviteId, receiverGithubUsername);
    return res.json({ invite });
  } catch (error) {
    return res.status(400).json({ error: (error as Error).message });
  }
});

router.get("/invites", (req, res) => {
  try {
    const authUser = getUserById((req as AuthenticatedRequest).auth.userId);
    const receiverGithubUsername = authUser?.githubUsername || "";
    const status = String(req.query.status || "pending").trim() as
      | "pending"
      | "accepted"
      | "declined"
      | "all";

    if (!receiverGithubUsername) {
      return res.status(400).json({ error: "receiverGithubUsername is required" });
    }

    const invites = listInvitesForReceiver(receiverGithubUsername, status).map((invite) => {
      const sender = getUserById(invite.senderUserId);
      return {
        ...invite,
        senderGithubUsername: sender?.githubUsername || "unknown"
      };
    });

    return res.json({ invites });
  } catch (error) {
    return res.status(400).json({ error: (error as Error).message });
  }
});

router.post("/sessions/start", (req, res) => {
  try {
    const ownerUserId = (req as AuthenticatedRequest).auth.userId;
    const session = startSession(ownerUserId);
    return res.status(201).json({ session });
  } catch (error) {
    return res.status(400).json({ error: (error as Error).message });
  }
});

router.post("/sessions/join", (req, res) => {
  try {
    const sessionId = String(req.body?.sessionId || "").trim();
    const userId = (req as AuthenticatedRequest).auth.userId;
    const session = joinSession(sessionId, userId);
    return res.json({ session });
  } catch (error) {
    return res.status(400).json({ error: (error as Error).message });
  }
});

router.post("/sessions/join-by-room", (req, res) => {
  try {
    const roomCode = String(req.body?.roomCode || "").trim();
    const userId = (req as AuthenticatedRequest).auth.userId;

    if (!roomCode) {
      return res.status(400).json({ error: "roomCode is required" });
    }

    const session = getSessionByRoomCode(roomCode);
    if (!session) {
      return res.status(404).json({ error: "Session not found for roomCode" });
    }

    const joined = joinSession(session.id, userId);
    return res.json({ session: joined });
  } catch (error) {
    return res.status(400).json({ error: (error as Error).message });
  }
});

router.post("/sessions/end", (req, res) => {
  try {
    const sessionId = String(req.body?.sessionId || "").trim();
    ensureSessionOwner(sessionId, (req as AuthenticatedRequest).auth.userId);
    const session = endSession(sessionId);
    return res.json({ session });
  } catch (error) {
    return res.status(400).json({ error: (error as Error).message });
  }
});

export default router;
