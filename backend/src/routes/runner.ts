import { Router } from "express";
import { AuthenticatedRequest } from "../middleware/auth.js";
import { ensureSessionParticipant } from "../services/sessionService.js";
import { executeCode, installPythonPackage } from "../services/runnerService.js";

const router = Router();

router.post("/execute", async (req, res) => {
  try {
    const language = String(req.body?.language || "").trim();
    const code = String(req.body?.code || "");
    const input = String(req.body?.input || "");
    const roomCode = String(req.body?.roomCode || "").trim();

    if (!language || !code) {
      return res.status(400).json({ error: "language and code are required" });
    }

    if (language !== "python3" && language !== "cpp") {
      return res.status(400).json({ error: "language must be python3 or cpp" });
    }

    if (roomCode) {
      ensureSessionParticipant(roomCode, (req as AuthenticatedRequest).auth.userId);
    }

    const result = await executeCode({ language, code, input, roomCode });
    return res.json(result);
  } catch (error) {
    return res.status(400).json({ error: (error as Error).message });
  }
});

router.post("/install", async (req, res) => {
  try {
    const language = String(req.body?.language || "").trim();
    const packageName = String(req.body?.packageName || "").trim();
    const roomCode = String(req.body?.roomCode || "").trim();

    if (!language || !packageName || !roomCode) {
      return res.status(400).json({ error: "language, packageName, and roomCode are required" });
    }

    if (language !== "python3") {
      return res.status(400).json({ error: "Package install is currently supported only for python3" });
    }

    ensureSessionParticipant(roomCode, (req as AuthenticatedRequest).auth.userId);

    const result = await installPythonPackage({ language, packageName, roomCode });
    return res.json(result);
  } catch (error) {
    return res.status(400).json({ error: (error as Error).message });
  }
});

export default router;
