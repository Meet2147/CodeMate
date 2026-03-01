export type PlanCode =
  | "trial"
  | "pro_monthly"
  | "pro_yearly"
  | "premium_monthly"
  | "premium_yearly"
  | "lifetime";

export type InviteStatus = "pending" | "accepted" | "declined";

export interface PlanLimits {
  maxPeoplePerSession: number;
  maxSessionsPerPeriod: number | "unlimited";
  period: "month" | "year" | "lifetime" | "trial";
  priceUsd: number;
}

export interface User {
  id: string;
  githubUsername: string;
  githubId?: string;
  trialEndsAt?: string;
  planCode: PlanCode;
  sessionsUsed: number;
}

export interface PairInvite {
  id: string;
  senderUserId: string;
  receiverGithubUsername: string;
  roomCode?: string;
  problemId?: string;
  status: InviteStatus;
  createdAt: string;
}

export interface CodingSession {
  id: string;
  ownerUserId: string;
  roomCode: string;
  participants: string[];
  startedAt: string;
  endedAt?: string;
}
