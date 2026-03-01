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

const profileTitleNode = document.querySelector("#profileTitle");
const profileSubNode = document.querySelector("#profileSub");
const statsGridNode = document.querySelector("#statsGrid");
const leaderboardListNode = document.querySelector("#leaderboardList");

function candidateApiBases() {
  const list = [API_BASE, "http://localhost:8080"];
  return [...new Set(list.map((base) => String(base || "").replace(/\/+$/, "")))].filter(Boolean);
}

async function fetchJsonWithFallback(path) {
  let lastError = "Unknown error";
  const auth = getAuth();
  const headers = new Headers();
  if (auth?.token) {
    headers.set("Authorization", `Bearer ${auth.token}`);
  }
  for (const base of candidateApiBases()) {
    try {
      const response = await fetch(`${base}${path}`, { headers });
      const text = await response.text();
      let data = null;
      try {
        data = JSON.parse(text);
      } catch {
        throw new Error(`API ${base} returned non-JSON response`);
      }
      if (!response.ok) {
        throw new Error(data?.error || "Request failed");
      }
      return data;
    } catch (error) {
      lastError = error instanceof Error ? error.message : String(error);
    }
  }
  throw new Error(lastError);
}

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

function startGitHubAuth() {
  const redirectUri = `${window.location.origin}${window.location.pathname}`;
  window.location.href = `${API_BASE}/auth/github/start?redirect_uri=${encodeURIComponent(redirectUri)}`;
}

function statCard(label, value) {
  return `<article class="stat-card"><p>${label}</p><h3>${value}</h3></article>`;
}

function renderProfile(profile) {
  profileTitleNode.textContent = `@${profile.githubUsername}`;
  profileSubNode.textContent = `Last solved date: ${profile.lastSolvedDate || "N/A"}`;

  statsGridNode.innerHTML = [
    statCard("Current Streak", profile.currentStreak),
    statCard("Longest Streak", profile.longestStreak),
    statCard("Solved Problems", profile.solvedCount),
    statCard("Accepted Submissions", profile.acceptedSubmissions)
  ].join("");
}

function renderLeaderboard(rows, authUserId) {
  if (!rows.length) {
    leaderboardListNode.innerHTML = '<p class="empty">No leaderboard data yet.</p>';
    return;
  }

  leaderboardListNode.innerHTML = rows
    .map((row) => {
      const you = authUserId && row.userId === authUserId ? " (you)" : "";
      return `
        <article class="leader-row">
          <strong>#${row.rank}</strong>
          <div>
            <strong>@${row.githubUsername}${you}</strong>
            <p class="muted">Solved: ${row.solvedCount}</p>
          </div>
          <div><strong>${row.currentStreak}</strong><p class="muted">Streak</p></div>
          <div><strong>${row.longestStreak}</strong><p class="muted">Best</p></div>
          <div class="hide-mobile"><strong>${row.acceptedSubmissions}</strong><p class="muted">Accepted</p></div>
        </article>
      `;
    })
    .join("");
}

async function loadProfileAndLeaderboard() {
  const auth = getAuth();
  if (!auth?.userId) {
    profileTitleNode.textContent = "Sign in required";
    profileSubNode.textContent = "Login to track your streak and see your rank.";
    statsGridNode.innerHTML = [statCard("Current Streak", 0), statCard("Longest Streak", 0), statCard("Solved Problems", 0), statCard("Accepted Submissions", 0)].join("");
    const leaderboardData = await fetchJsonWithFallback("/profile/leaderboard?limit=25");
    renderLeaderboard(leaderboardData.leaderboard || [], "");
    return;
  }

  const [profileData, leaderboardData] = await Promise.all([
    fetchJsonWithFallback("/profile/me"),
    fetchJsonWithFallback("/profile/leaderboard?limit=25")
  ]);

  renderProfile(profileData.profile);
  renderLeaderboard(leaderboardData.leaderboard || [], auth.userId);
}

storeAuthFromUrlIfPresent();
loadProfileAndLeaderboard().catch((error) => {
  profileTitleNode.textContent = "Profile unavailable";
  profileSubNode.textContent = error.message || "Could not load profile";
  leaderboardListNode.innerHTML = '<p class="empty">Could not load leaderboard.</p>';
});

document.querySelector("#loginBtn").addEventListener("click", startGitHubAuth);
document.querySelector("#refreshBtn").addEventListener("click", () => {
  loadProfileAndLeaderboard().catch((error) => {
    profileSubNode.textContent = error.message || "Could not refresh";
  });
});
