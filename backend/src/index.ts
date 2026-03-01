import "dotenv/config";
import { createServer } from "node:http";
import cors from "cors";
import express from "express";
import authRoutes from "./routes/auth.js";
import pairingRoutes from "./routes/pairing.js";
import billingRoutes from "./routes/billing.js";
import runnerRoutes from "./routes/runner.js";
import profileRoutes from "./routes/profile.js";
import dsaRoutes from "./routes/dsa.js";
import { requireAuth } from "./middleware/auth.js";
import { rateLimitMiddleware } from "./middleware/rateLimit.js";
import { securityHeaders } from "./middleware/securityHeaders.js";
import { setupSignalingServer } from "./services/signalingService.js";

const app = express();
const port = Number(process.env.PORT || 8080);

const allowedOrigins = String(process.env.ALLOWED_AUTH_REDIRECTS || "")
  .split(",")
  .map((item) => item.trim().replace(/\/+$/, ""))
  .filter(Boolean);

function isAllowedOrigin(origin: string): boolean {
  const normalized = origin.replace(/\/+$/, "");
  if (allowedOrigins.includes(normalized)) {
    return true;
  }
  if (/^http:\/\/(localhost|127\.0\.0\.1):\d+$/i.test(normalized)) {
    return true;
  }
  return /^https:\/\/.+\.ngrok-free\.app$/i.test(normalized);
}

app.set("trust proxy", 1);
app.use(securityHeaders);
app.use(rateLimitMiddleware);
app.use(
  cors({
    origin(origin, callback) {
      if (!origin) {
        callback(null, true);
        return;
      }

      if (isAllowedOrigin(origin)) {
        callback(null, true);
        return;
      }

      callback(new Error("CORS blocked for this origin."));
    },
    methods: ["GET", "POST", "OPTIONS"],
    allowedHeaders: ["Authorization", "Content-Type"],
    credentials: false,
    maxAge: 86400
  })
);
app.use(express.json({ limit: "256kb" }));

app.get("/health", (_req, res) => {
  res.json({ ok: true, service: "pair-programming-backend" });
});

app.use("/auth", authRoutes);
app.use("/pairing", requireAuth, pairingRoutes);
app.use("/billing", requireAuth, billingRoutes);
app.use("/runner", requireAuth, runnerRoutes);
app.use("/profile", requireAuth, profileRoutes);
app.use("/dsa", requireAuth, dsaRoutes);

app.use((error: Error, _req: express.Request, res: express.Response, _next: express.NextFunction) => {
  if (error.message.toLowerCase().includes("cors")) {
    res.status(403).json({ error: error.message });
    return;
  }
  res.status(500).json({ error: "Internal server error" });
});

const server = createServer(app);
setupSignalingServer(server);

server.listen(port, () => {
  // eslint-disable-next-line no-console
  console.log(`Backend running at http://localhost:${port}`);
});
