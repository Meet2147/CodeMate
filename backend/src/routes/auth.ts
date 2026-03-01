import { Router } from "express";
import { getBearerToken } from "../middleware/auth.js";
import {
  createOAuthState,
  consumeOAuthState,
  issueAccessToken,
  resolveUserIdFromToken
} from "../services/authService.js";
import { getOrCreateUser, getUserById } from "../services/sessionService.js";

const router = Router();
const githubClientId = process.env.GITHUB_CLIENT_ID || "";
const githubClientSecret = process.env.GITHUB_CLIENT_SECRET || "";
const githubScope = process.env.GITHUB_SCOPE || "read:user user:email";
const callbackUrl = process.env.GITHUB_CALLBACK_URL || "http://localhost:8080/auth/github/callback";

function isAllowedRedirectUri(redirectUri: string): boolean {
  const configured = String(process.env.ALLOWED_AUTH_REDIRECTS || "")
    .split(",")
    .map((item) => item.trim())
    .filter(Boolean);

  if (configured.some((prefix) => redirectUri.startsWith(prefix))) {
    return true;
  }

  if (redirectUri.startsWith("http://localhost:") || redirectUri.startsWith("http://127.0.0.1:")) {
    return true;
  }

  if (/^vscode:\/\/[a-z0-9._-]+(?:\/.*)?$/i.test(redirectUri)) {
    return true;
  }

  return /^https:\/\/[a-z0-9]+\.chromiumapp\.org\/?/i.test(redirectUri);
}

router.get("/github/start", (req, res) => {
  if (!githubClientId || !githubClientSecret) {
    return res.status(500).json({ error: "GitHub OAuth is not configured on the backend." });
  }

  const redirectUri = String(
    req.query.redirect_uri || process.env.DEFAULT_AUTH_REDIRECT_URI || ""
  ).trim();

  if (!redirectUri) {
    return res.status(400).json({ error: "redirect_uri query param is required." });
  }
  if (!isAllowedRedirectUri(redirectUri)) {
    return res.status(400).json({ error: "redirect_uri is not allowed." });
  }

  const state = createOAuthState(redirectUri);
  const githubAuthUrl = new URL("https://github.com/login/oauth/authorize");
  githubAuthUrl.searchParams.set("client_id", githubClientId);
  githubAuthUrl.searchParams.set("redirect_uri", callbackUrl);
  githubAuthUrl.searchParams.set("scope", githubScope);
  githubAuthUrl.searchParams.set("state", state);

  if (String(req.query.format || "").toLowerCase() === "json") {
    return res.json({ authUrl: githubAuthUrl.toString(), state });
  }

  return res.redirect(githubAuthUrl.toString());
});

router.get("/github/callback", async (req, res) => {
  try {
    const code = String(req.query.code || "").trim();
    const state = String(req.query.state || "").trim();

    if (!code || !state) {
      return res.status(400).send("Missing code/state.");
    }

    const statePayload = consumeOAuthState(state);
    if (!statePayload) {
      return res.status(400).send("OAuth state invalid or expired.");
    }

    const tokenResponse = await fetch("https://github.com/login/oauth/access_token", {
      method: "POST",
      headers: {
        Accept: "application/json",
        "Content-Type": "application/json"
      },
      body: JSON.stringify({
        client_id: githubClientId,
        client_secret: githubClientSecret,
        code,
        redirect_uri: callbackUrl
      })
    });

    const tokenJson = (await tokenResponse.json()) as { access_token?: string; error?: string };
    if (!tokenResponse.ok || !tokenJson.access_token) {
      return res
        .status(400)
        .send(`Unable to exchange GitHub code for access token (${tokenJson.error || "unknown"}).`);
    }

    const userResponse = await fetch("https://api.github.com/user", {
      headers: {
        Authorization: `Bearer ${tokenJson.access_token}`,
        Accept: "application/vnd.github+json",
        "User-Agent": "pair-programming-platform"
      }
    });

    const userJson = (await userResponse.json()) as { login?: string };
    if (!userResponse.ok || !userJson.login) {
      return res.status(400).send("Unable to fetch GitHub profile.");
    }

    const appUser = getOrCreateUser(userJson.login);
    const token = issueAccessToken(appUser.id);

    const redirect = new URL(statePayload.redirectUri);
    redirect.searchParams.set("token", token);
    redirect.searchParams.set("github_username", appUser.githubUsername);
    redirect.searchParams.set("user_id", appUser.id);
    return res.redirect(redirect.toString());
  } catch (error) {
    return res.status(500).send((error as Error).message);
  }
});

router.get("/me", (req, res) => {
  const token = getBearerToken(req.headers.authorization);
  if (!token) {
    return res.status(401).json({ error: "Missing bearer token." });
  }

  const userId = resolveUserIdFromToken(token);
  if (!userId) {
    return res.status(401).json({ error: "Token invalid or expired." });
  }

  const user = getUserById(userId);
  if (!user) {
    return res.status(404).json({ error: "User not found." });
  }

  return res.json({ user });
});

export default router;
