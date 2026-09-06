import { NextFunction, Request, Response } from "express";
import { resolveUserIdFromToken } from "../services/authService.js";

export interface AuthContext {
  userId: string;
}

export interface AuthenticatedRequest extends Request {
  auth: AuthContext;
}

export function getBearerToken(header: string | undefined): string {
  if (!header?.startsWith("Bearer ")) {
    return "";
  }
  return header.slice("Bearer ".length).trim();
}

export function requireAuth(req: Request, res: Response, next: NextFunction): void {
  const token = getBearerToken(req.headers.authorization);
  if (!token) {
    res.status(401).json({ error: "Missing bearer token." });
    return;
  }

  const userId = resolveUserIdFromToken(token);
  if (!userId) {
    res.status(401).json({ error: "Token invalid or expired." });
    return;
  }

  (req as AuthenticatedRequest).auth = { userId };
  next();
}
