import { Router } from "express";
import { AuthenticatedRequest } from "../middleware/auth.js";
import { getLeaderboard, getProfile } from "../services/profileService.js";

const router = Router();

router.get("/me", (req, res) => {
  const userId = (req as AuthenticatedRequest).auth.userId;

  const profile = getProfile(userId);
  if (!profile) {
    return res.status(404).json({ error: "User not found" });
  }

  return res.json({ profile });
});

router.get("/leaderboard", (req, res) => {
  const limit = Number(req.query.limit || 20);
  return res.json({ leaderboard: getLeaderboard(Number.isFinite(limit) ? limit : 20) });
});

export default router;
