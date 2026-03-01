import { createHmac, randomUUID, timingSafeEqual } from "node:crypto";

interface PendingOAuthState {
  redirectUri: string;
  expiresAt: number;
}

interface JwtPayload {
  sub: string;
  iat: number;
  exp: number;
  iss: string;
}

const pendingStates = new Map<string, PendingOAuthState>();

const stateTtlMs = 10 * 60 * 1000;
const tokenTtlSeconds = Number(process.env.AUTH_TOKEN_TTL_SECONDS || 60 * 60 * 24 * 30);
const jwtIssuer = String(process.env.JWT_ISSUER || "codemate-backend").trim();

function getJwtSecret(): string {
  return String(process.env.JWT_SECRET || process.env.GITHUB_CLIENT_SECRET || "").trim();
}

function toBase64Url(value: string): string {
  return Buffer.from(value, "utf8").toString("base64url");
}

function fromBase64Url(value: string): string {
  return Buffer.from(value, "base64url").toString("utf8");
}

function sign(input: string, secret: string): string {
  return createHmac("sha256", secret).update(input).digest("base64url");
}

function signaturesMatch(expected: string, actual: string): boolean {
  const expectedBuffer = Buffer.from(expected, "utf8");
  const actualBuffer = Buffer.from(actual, "utf8");
  if (expectedBuffer.length !== actualBuffer.length) {
    return false;
  }
  return timingSafeEqual(expectedBuffer, actualBuffer);
}

export function createOAuthState(redirectUri: string): string {
  const state = randomUUID();
  pendingStates.set(state, {
    redirectUri,
    expiresAt: Date.now() + stateTtlMs
  });
  return state;
}

export function consumeOAuthState(state: string): PendingOAuthState | null {
  const payload = pendingStates.get(state);
  if (!payload) {
    return null;
  }

  pendingStates.delete(state);
  if (payload.expiresAt < Date.now()) {
    return null;
  }

  return payload;
}

export function issueAccessToken(userId: string): string {
  const secret = getJwtSecret();
  if (!secret) {
    throw new Error("Missing JWT secret. Set JWT_SECRET on backend.");
  }

  const now = Math.floor(Date.now() / 1000);
  const payload: JwtPayload = {
    sub: userId,
    iat: now,
    exp: now + tokenTtlSeconds,
    iss: jwtIssuer
  };

  const headerBase64 = toBase64Url(JSON.stringify({ alg: "HS256", typ: "JWT" }));
  const payloadBase64 = toBase64Url(JSON.stringify(payload));
  const signature = sign(`${headerBase64}.${payloadBase64}`, secret);

  return `${headerBase64}.${payloadBase64}.${signature}`;
}

export function resolveUserIdFromToken(token: string): string | null {
  try {
    const secret = getJwtSecret();
    if (!secret) {
      return null;
    }

    const parts = token.split(".");
    if (parts.length !== 3) {
      return null;
    }

    const [headerBase64, payloadBase64, signature] = parts;
    const expectedSignature = sign(`${headerBase64}.${payloadBase64}`, secret);
    if (!signaturesMatch(expectedSignature, signature)) {
      return null;
    }

    const header = JSON.parse(fromBase64Url(headerBase64)) as { alg?: string; typ?: string };
    if (header.alg !== "HS256" || header.typ !== "JWT") {
      return null;
    }

    const payload = JSON.parse(fromBase64Url(payloadBase64)) as Partial<JwtPayload>;
    if (payload.iss !== jwtIssuer || typeof payload.sub !== "string") {
      return null;
    }

    const now = Math.floor(Date.now() / 1000);
    if (typeof payload.exp !== "number" || payload.exp <= now) {
      return null;
    }

    return payload.sub;
  } catch {
    return null;
  }
}
