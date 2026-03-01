import { PlanCode, PlanLimits } from "../types/domain.js";

export const planCatalog: Record<PlanCode, PlanLimits> = {
  trial: {
    maxPeoplePerSession: 2,
    maxSessionsPerPeriod: 30,
    period: "trial",
    priceUsd: 0
  },
  pro_monthly: {
    maxPeoplePerSession: 2,
    maxSessionsPerPeriod: 300,
    period: "month",
    priceUsd: 29.99
  },
  pro_yearly: {
    maxPeoplePerSession: 2,
    maxSessionsPerPeriod: 300,
    period: "year",
    priceUsd: 99
  },
  premium_monthly: {
    maxPeoplePerSession: 2,
    maxSessionsPerPeriod: 500,
    period: "month",
    priceUsd: 199
  },
  premium_yearly: {
    maxPeoplePerSession: 2,
    maxSessionsPerPeriod: 500,
    period: "year",
    priceUsd: 349
  },
  lifetime: {
    maxPeoplePerSession: 2,
    maxSessionsPerPeriod: "unlimited",
    period: "lifetime",
    priceUsd: 499
  }
};

export function canStartAnotherSession(plan: PlanCode, sessionsUsed: number): boolean {
  const limits = planCatalog[plan];
  if (limits.maxSessionsPerPeriod === "unlimited") {
    return true;
  }
  return sessionsUsed < limits.maxSessionsPerPeriod;
}
