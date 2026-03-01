import { randomUUID } from "node:crypto";
import { canStartAnotherSession, planCatalog } from "./planService.js";
import { CodingSession, InviteStatus, PairInvite, User } from "../types/domain.js";

const users = new Map<string, User>();
const invites = new Map<string, PairInvite>();
const sessions = new Map<string, CodingSession>();

function seedUser(username: string): User {
  const id = `user_${username}`;
  const existing = users.get(id);
  if (existing) {
    return existing;
  }

  const user: User = {
    id,
    githubUsername: username,
    planCode: "trial",
    sessionsUsed: 0,
    trialEndsAt: new Date(Date.now() + 7 * 24 * 60 * 60 * 1000).toISOString()
  };
  users.set(id, user);
  return user;
}

export function getOrCreateUser(githubUsername: string): User {
  return seedUser(githubUsername.toLowerCase());
}

export function getUserById(userId: string): User | null {
  return users.get(userId) || null;
}

export function createInvite(
  senderUserId: string,
  receiverGithubUsername: string,
  roomCode?: string,
  problemId?: string
): PairInvite {
  const invite: PairInvite = {
    id: randomUUID(),
    senderUserId,
    receiverGithubUsername: receiverGithubUsername.toLowerCase(),
    roomCode: roomCode?.trim() || undefined,
    problemId: problemId?.trim() || undefined,
    status: "pending",
    createdAt: new Date().toISOString()
  };
  invites.set(invite.id, invite);
  return invite;
}

export function acceptInvite(inviteId: string, receiverGithubUsername: string): PairInvite {
  const invite = invites.get(inviteId);
  if (!invite) {
    throw new Error("Invite not found.");
  }
  if (invite.receiverGithubUsername !== receiverGithubUsername.toLowerCase()) {
    throw new Error("Invite receiver does not match current GitHub user.");
  }
  invite.status = "accepted";
  invites.set(invite.id, invite);
  return invite;
}

export function declineInvite(inviteId: string, receiverGithubUsername: string): PairInvite {
  const invite = invites.get(inviteId);
  if (!invite) {
    throw new Error("Invite not found.");
  }
  if (invite.receiverGithubUsername !== receiverGithubUsername.toLowerCase()) {
    throw new Error("Invite receiver does not match current GitHub user.");
  }
  invite.status = "declined";
  invites.set(invite.id, invite);
  return invite;
}

export function listInvitesForReceiver(
  receiverGithubUsername: string,
  status: InviteStatus | "all" = "pending"
): PairInvite[] {
  const normalized = receiverGithubUsername.toLowerCase();
  return [...invites.values()]
    .filter((invite) => invite.receiverGithubUsername === normalized)
    .filter((invite) => status === "all" || invite.status === status)
    .sort((a, b) => b.createdAt.localeCompare(a.createdAt));
}

export function startSession(ownerUserId: string): CodingSession {
  const owner = users.get(ownerUserId);
  if (!owner) {
    throw new Error("Owner not found.");
  }

  if (!canStartAnotherSession(owner.planCode, owner.sessionsUsed)) {
    throw new Error("Session limit reached for current plan.");
  }

  const limits = planCatalog[owner.planCode];
  const session: CodingSession = {
    id: randomUUID(),
    ownerUserId,
    roomCode: randomUUID().slice(0, 8),
    participants: [ownerUserId],
    startedAt: new Date().toISOString()
  };

  if (limits.maxPeoplePerSession < 2) {
    throw new Error("Plan does not allow paired programming.");
  }

  owner.sessionsUsed += 1;
  users.set(owner.id, owner);
  sessions.set(session.id, session);
  return session;
}

export function joinSession(sessionId: string, userId: string): CodingSession {
  const session = sessions.get(sessionId);
  const user = users.get(userId);

  if (!session || !user) {
    throw new Error("Session or user not found.");
  }

  const owner = users.get(session.ownerUserId);
  if (!owner) {
    throw new Error("Session owner not found.");
  }

  const limits = planCatalog[owner.planCode];
  if (session.participants.length >= limits.maxPeoplePerSession) {
    throw new Error("Session is full for the owner's subscription plan.");
  }

  if (!session.participants.includes(userId)) {
    session.participants.push(userId);
    sessions.set(session.id, session);
  }

  return session;
}

export function endSession(sessionId: string): CodingSession {
  const session = sessions.get(sessionId);
  if (!session) {
    throw new Error("Session not found.");
  }
  session.endedAt = new Date().toISOString();
  sessions.set(session.id, session);
  return session;
}

export function listPlans() {
  return planCatalog;
}

export function getSessionByRoomCode(roomCode: string): CodingSession | null {
  const normalized = roomCode.trim().toLowerCase();
  for (const session of sessions.values()) {
    if (session.roomCode.toLowerCase() === normalized) {
      return session;
    }
  }
  return null;
}

export function getSessionById(sessionId: string): CodingSession | null {
  return sessions.get(sessionId) || null;
}

export function isSessionParticipant(roomCode: string, userId: string): boolean {
  const session = getSessionByRoomCode(roomCode);
  if (!session) {
    return false;
  }
  return session.participants.includes(userId);
}

export function ensureSessionParticipant(roomCode: string, userId: string): void {
  if (!isSessionParticipant(roomCode, userId)) {
    throw new Error("User is not an active participant for this room.");
  }
}

export function ensureSessionOwner(sessionId: string, userId: string): void {
  const session = getSessionById(sessionId);
  if (!session) {
    throw new Error("Session not found.");
  }
  if (session.ownerUserId !== userId) {
    throw new Error("Only the session owner can perform this action.");
  }
}
