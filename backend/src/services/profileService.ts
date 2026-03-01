import { getUserById } from "./sessionService.js";

interface ProfileProgress {
  userId: string;
  attempts: number;
  acceptedSubmissions: number;
  solvedProblemIds: Set<string>;
  currentStreak: number;
  longestStreak: number;
  lastSolvedDate?: string;
}

const progressByUser = new Map<string, ProfileProgress>();

function todayUtcDate(): string {
  return new Date().toISOString().slice(0, 10);
}

function previousUtcDate(date: string): string {
  const d = new Date(`${date}T00:00:00.000Z`);
  d.setUTCDate(d.getUTCDate() - 1);
  return d.toISOString().slice(0, 10);
}

function ensureProgress(userId: string): ProfileProgress {
  const existing = progressByUser.get(userId);
  if (existing) return existing;

  const created: ProfileProgress = {
    userId,
    attempts: 0,
    acceptedSubmissions: 0,
    solvedProblemIds: new Set<string>(),
    currentStreak: 0,
    longestStreak: 0
  };
  progressByUser.set(userId, created);
  return created;
}

export function recordDsaSubmission(userId: string, problemId: string, status: string): void {
  const progress = ensureProgress(userId);
  progress.attempts += 1;

  if (status !== "accepted") {
    progressByUser.set(userId, progress);
    return;
  }

  progress.acceptedSubmissions += 1;

  const beforeSolved = progress.solvedProblemIds.size;
  progress.solvedProblemIds.add(problemId);
  const solvedNewProblem = progress.solvedProblemIds.size > beforeSolved;

  if (solvedNewProblem) {
    const today = todayUtcDate();
    const last = progress.lastSolvedDate;

    if (!last) {
      progress.currentStreak = 1;
    } else if (last === today) {
      // Keep streak same.
    } else if (last === previousUtcDate(today)) {
      progress.currentStreak += 1;
    } else {
      progress.currentStreak = 1;
    }

    progress.lastSolvedDate = today;
    progress.longestStreak = Math.max(progress.longestStreak, progress.currentStreak);
  }

  progressByUser.set(userId, progress);
}

export function getProfile(userId: string): {
  userId: string;
  githubUsername: string;
  attempts: number;
  acceptedSubmissions: number;
  solvedCount: number;
  currentStreak: number;
  longestStreak: number;
  lastSolvedDate?: string;
} | null {
  const user = getUserById(userId);
  if (!user) return null;

  const progress = ensureProgress(userId);
  return {
    userId,
    githubUsername: user.githubUsername,
    attempts: progress.attempts,
    acceptedSubmissions: progress.acceptedSubmissions,
    solvedCount: progress.solvedProblemIds.size,
    currentStreak: progress.currentStreak,
    longestStreak: progress.longestStreak,
    lastSolvedDate: progress.lastSolvedDate
  };
}

export function getLeaderboard(limit = 20): Array<{
  rank: number;
  userId: string;
  githubUsername: string;
  solvedCount: number;
  currentStreak: number;
  longestStreak: number;
  acceptedSubmissions: number;
}> {
  const rows = [...progressByUser.values()]
    .map((progress) => {
      const user = getUserById(progress.userId);
      if (!user) return null;
      return {
        userId: progress.userId,
        githubUsername: user.githubUsername,
        solvedCount: progress.solvedProblemIds.size,
        currentStreak: progress.currentStreak,
        longestStreak: progress.longestStreak,
        acceptedSubmissions: progress.acceptedSubmissions
      };
    })
    .filter((row): row is NonNullable<typeof row> => Boolean(row))
    .sort((a, b) => {
      if (b.solvedCount !== a.solvedCount) return b.solvedCount - a.solvedCount;
      if (b.currentStreak !== a.currentStreak) return b.currentStreak - a.currentStreak;
      return b.acceptedSubmissions - a.acceptedSubmissions;
    })
    .slice(0, Math.max(1, Math.min(limit, 100)));

  return rows.map((row, index) => ({
    rank: index + 1,
    ...row
  }));
}
