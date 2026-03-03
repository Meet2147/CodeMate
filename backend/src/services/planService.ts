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
  pro_monthly: {
    maxPeoplePerSession: 2,
    maxSessionsPerPeriod: 300,
    maxSessionsPerDay: 5,
    sessionDurationMinutes: 50,
    maxHoursTotal: 300,
    carryForwardUnusedMinutes: true,
    period: "month",
    priceUsd: 29.99
  },
  pro_yearly: {
    maxPeoplePerSession: 2,
    maxSessionsPerPeriod: "unlimited",
    maxSessionsPerDay: "unlimited",
    sessionDurationMinutes: 50,
    maxHoursTotal: 500,
    softLimitHoursBeforeDailyThrottle: 300,
    dailyThrottleSessionsAfterSoftLimit: 1,
    period: "year",
    priceUsd: 99
  },
  premium_monthly: {
    maxPeoplePerSession: 10,
    maxSessionsPerPeriod: "unlimited",
    maxSessionsPerDay: 15,
    sessionDurationMinutes: 50,
    maxHoursTotal: 750,
    period: "month",
    priceUsd: 199
  },
  premium_yearly: {
    maxPeoplePerSession: 10,
    maxSessionsPerPeriod: "unlimited",
    maxSessionsPerDay: "unlimited",
    sessionDurationMinutes: 50,
    maxHoursTotal: 1050,
    period: "year",
    priceUsd: 349
  },
  lifetime: {
    maxPeoplePerSession: 10,
    maxSessionsPerPeriod: "unlimited",
    maxSessionsPerDay: "unlimited",
    sessionDurationMinutes: "unlimited",
    maxHoursTotal: "unlimited",
    period: "lifetime",
    priceUsd: 499
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
      throw new Error("Not enough remaining plan time for another 50-minute session.");
    }
  }
}
