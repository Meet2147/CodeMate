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

const trackMetaNode = document.querySelector("#trackMeta");
const problemListNode = document.querySelector("#problemList");
const difficultyFilterNode = document.querySelector("#difficultyFilter");
const searchInputNode = document.querySelector("#searchInput");

let allProblems = [];

function candidateApiBases() {
  const list = [API_BASE, "http://localhost:8080"];
  return [...new Set(list.map((base) => String(base || "").replace(/\/+$/, "")))].filter(Boolean);
}

async function fetchJsonWithFallback(path) {
  let lastError = "Unknown error";
  const authRaw = localStorage.getItem("pairpulse_auth");
  let auth = null;
  try {
    auth = authRaw ? JSON.parse(authRaw) : null;
  } catch {
    auth = null;
  }
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

function startGitHubAuth() {
  const redirectUri = `${window.location.origin}${window.location.pathname}`;
  window.location.href = `${API_BASE}/auth/github/start?redirect_uri=${encodeURIComponent(redirectUri)}`;
}

function renderProblems() {
  const difficulty = difficultyFilterNode.value;
  const search = searchInputNode.value.trim().toLowerCase();

  const filtered = allProblems.filter((problem) => {
    if (difficulty !== "all" && problem.difficulty !== difficulty) return false;
    if (!search) return true;
    return `${problem.title} ${problem.topic}`.toLowerCase().includes(search);
  });

  if (!filtered.length) {
    problemListNode.innerHTML = '<p class="empty">No problems match your filter.</p>';
    return;
  }

  problemListNode.innerHTML = filtered
    .map(
      (problem) => `
      <article class="problem-card card">
        <h3>${problem.title}</h3>
        <div class="tag-row">
          <span class="tag ${problem.difficulty}">${problem.difficulty.toUpperCase()}</span>
          <span class="tag">${problem.topic}</span>
        </div>
        <a href="./dsa-problem.html?problemId=${encodeURIComponent(problem.id)}">Link With Room</a>
      </article>
    `
    )
    .join("");
}

async function loadProblems() {
  const data = await fetchJsonWithFallback("/dsa/problems");

  allProblems = Array.isArray(data.problems) ? data.problems : [];
  trackMetaNode.textContent = `${data.availableCount}/${data.targetCount} problems currently live. More are being added continuously.`;
  renderProblems();
}

storeAuthFromUrlIfPresent();
loadProblems().catch((error) => {
  trackMetaNode.textContent = error.message || "Could not load DSA track.";
  problemListNode.innerHTML = '<p class="empty">Failed to load problems.</p>';
});

difficultyFilterNode.addEventListener("change", renderProblems);
searchInputNode.addEventListener("input", renderProblems);
document.querySelector("#loginBtn").addEventListener("click", startGitHubAuth);
