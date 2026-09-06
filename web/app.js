const queryParams = new URLSearchParams(window.location.search);
const apiBaseFromQuery = (queryParams.get("apiBase") || "").trim();
if (apiBaseFromQuery) {
  localStorage.setItem("codemate_api_base", apiBaseFromQuery);
}

const API_BASE = (
  localStorage.getItem("codemate_api_base") ||
  (typeof window.CODEMATE_API_BASE === "string" ? window.CODEMATE_API_BASE : "") ||
  "http://localhost:8080"
).replace(/\/+$/, "");

function storeAuthFromUrlIfPresent() {
  const params = new URLSearchParams(window.location.search);
  const token = params.get("token");
  const userId = params.get("user_id");
  const githubUsername = params.get("github_username");

  if (!token || !userId || !githubUsername) return;

  localStorage.setItem("pairpulse_auth", JSON.stringify({ token, userId, githubUsername }));
  window.history.replaceState({}, "", `${window.location.origin}${window.location.pathname}`);
}

function getAuth() {
  const raw = localStorage.getItem("pairpulse_auth");
  if (!raw) return null;
  try {
    return JSON.parse(raw);
  } catch {
    return null;
  }
}

async function refreshAuthTokenIfPossible() {
  const auth = getAuth();
  if (!auth?.token) return;
  try {
    const response = await fetch(`${API_BASE}/auth/refresh`, {
      method: "POST",
      headers: {
        Authorization: `Bearer ${auth.token}`
      }
    });
    if (!response.ok) return;
    const data = await response.json();
    if (!data?.token || !data?.user?.id || !data?.user?.githubUsername) return;
    localStorage.setItem(
      "pairpulse_auth",
      JSON.stringify({
        token: data.token,
        userId: data.user.id,
        githubUsername: data.user.githubUsername
      })
    );
  } catch {
    // Ignore refresh failure and keep existing auth.
  }
}

function startGitHubAuth() {
  const redirectUri = `${window.location.origin}${window.location.pathname}`;
  window.location.href = `${API_BASE}/auth/github/start?redirect_uri=${encodeURIComponent(redirectUri)}`;
}

storeAuthFromUrlIfPresent();
refreshAuthTokenIfPossible();

const authStatus = document.querySelector("#authStatus");
const auth = getAuth();
if (authStatus) {
  authStatus.textContent = auth?.githubUsername ? `Signed in as @${auth.githubUsername}` : "Not signed in";
}

document.querySelector("#loginBtn").addEventListener("click", startGitHubAuth);
document.querySelector("#heroLoginBtn")?.addEventListener("click", startGitHubAuth);
