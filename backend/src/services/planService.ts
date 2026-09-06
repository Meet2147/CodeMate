import { PlanCode, PlanLimits, User } from "../types/domain.js";

export const planCatalog: Record<PlanCode, PlanLimits> = {
  trial: {
    maxPeoplePerSession: 2,
    maxSessionsPerPeriod: 30,
    maxSessionsPerDay: 3,
    sessionDurationMinutes: 50,
    maxHoursTotal: 25,
    period: "trial",
    priceUsd: 0
  },
  starter_monthly: {
    maxPeoplePerSession: 2,
    maxSessionsPerPeriod: "unlimited",
    maxSessionsPerDay: 3,
    sessionDurationMinutes: 50,
    maxHoursTotal: "unlimited",
    period: "month",
    priceUsd: 39
  },
  starter_yearly: {
    maxPeoplePerSession: 2,
    maxSessionsPerPeriod: "unlimited",
    maxSessionsPerDay: 3,
    sessionDurationMinutes: 50,
    maxHoursTotal: "unlimited",
    period: "year",
    priceUsd: 299
  },
  pro_monthly: {
    maxPeoplePerSession: 5,
    maxSessionsPerPeriod: "unlimited",
    maxSessionsPerDay: 10,
    sessionDurationMinutes: 100,
    maxHoursTotal: "unlimited",
    period: "month",
    priceUsd: 149
  },
  pro_yearly: {
    maxPeoplePerSession: 5,
    maxSessionsPerPeriod: "unlimited",
    maxSessionsPerDay: 10,
    sessionDurationMinutes: 100,
    maxHoursTotal: "unlimited",
    period: "year",
    priceUsd: 1199
  },
  team_monthly: {
    maxPeoplePerSession: 20,
    maxSessionsPerPeriod: "unlimited",
    maxSessionsPerDay: "unlimited",
    sessionDurationMinutes: "unlimited",
    maxHoursTotal: "unlimited",
    period: "month",
    priceUsd: 499
  },
  team_yearly: {
    maxPeoplePerSession: 20,
    maxSessionsPerPeriod: "unlimited",
    maxSessionsPerDay: "unlimited",
    sessionDurationMinutes: "unlimited",
    maxHoursTotal: "unlimited",
    period: "year",
    priceUsd: 4999
  },
  founder_lifetime: {
    maxPeoplePerSession: 20,
    maxSessionsPerPeriod: "unlimited",
    maxSessionsPerDay: "unlimited",
    sessionDurationMinutes: "unlimited",
    maxHoursTotal: "unlimited",
    period: "lifetime",
    priceUsd: 999
  }
};

function sessionsStartedToday(history: string[], now: Date): number {
  const today = now.toISOString().slice(0, 10);
  return history.filter((value) => String(value || "").slice(0, 10) === today).length;
}

export function validateSessionStart(plan: PlanCode, user: User, now: Date = new Date()): void {
  const limits = planCatalog[plan];

  if (limits.maxSessionsPerPeriod !== "unlimited" && user.sessionsUsed >= limits.maxSessionsPerPeriod) {
    throw new Error("Session limit reached for current plan.");
  }

  let maxSessionsToday = limits.maxSessionsPerDay;
  if (
    limits.softLimitHoursBeforeDailyThrottle &&
    limits.dailyThrottleSessionsAfterSoftLimit &&
    user.minutesConsumed >= limits.softLimitHoursBeforeDailyThrottle * 60
  ) {
    maxSessionsToday = limits.dailyThrottleSessionsAfterSoftLimit;
  }

  if (maxSessionsToday !== "unlimited") {
    const todayCount = sessionsStartedToday(user.sessionsStartedHistory, now);
    if (todayCount >= maxSessionsToday) {
      throw new Error("Daily session limit reached for current plan.");
    }
  }

  if (limits.maxHoursTotal !== "unlimited" && limits.sessionDurationMinutes !== "unlimited") {
    if (user.minutesConsumed >= limits.maxHoursTotal * 60) {
      throw new Error("Total plan hours exhausted. Upgrade required.");
    }
    if (user.minutesConsumed + limits.sessionDurationMinutes > limits.maxHoursTotal * 60) {
      throw new Error("Not enough remaining plan time for another session.");
    }
  }
}
