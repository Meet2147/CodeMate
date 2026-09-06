import { Router } from "express";
import { AuthenticatedRequest } from "../middleware/auth.js";
import { getDsaProblem, listDsaProblems, submitDsaSolution } from "../services/dsaService.js";
import { recordDsaSubmission } from "../services/profileService.js";

const router = Router();

router.get("/problems", (_req, res) => {
  return res.json(listDsaProblems());
});

router.get("/problems/:problemId", (req, res) => {
  const problem = getDsaProblem(String(req.params.problemId || "").trim());
  if (!problem) {
    return res.status(404).json({ error: "Problem not found" });
  }
  return res.json({ problem });
});

router.post("/submit", async (req, res) => {
  try {
    const problemId = String(req.body?.problemId || "").trim();
    const language = String(req.body?.language || "").trim() as "python3" | "cpp";
    const code = String(req.body?.code || "");
    const userId = (req as AuthenticatedRequest).auth.userId;

    if (!problemId || !language || !code) {
      return res.status(400).json({ error: "problemId, language and code are required" });
    }

    if (language !== "python3" && language !== "cpp") {
      return res.status(400).json({ error: "language must be python3 or cpp" });
    }

    const result = await submitDsaSolution(problemId, language, code);
    recordDsaSubmission(userId, problemId, result.status);
    return res.json(result);
  } catch (error) {
    const message = error instanceof Error ? error.message : "Submission failed";
    return res.status(400).json({ error: message });
  }
});

export default router;
