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
const params = new URLSearchParams(window.location.search);
const problemId = (params.get("problemId") || "").trim();

const problemHeaderNode = document.querySelector("#problemHeader h1");
const problemMetaNode = document.querySelector("#problemMeta");
const promptNode = document.querySelector("#prompt");
const inputFormatNode = document.querySelector("#inputFormat");
const outputFormatNode = document.querySelector("#outputFormat");
const constraintsNode = document.querySelector("#constraints");
const examplesNode = document.querySelector("#examples");
const partnerUsernameNode = document.querySelector("#partnerUsername");
const linkStatusNode = document.querySelector("#linkStatus");

let currentProblem = null;

function candidateApiBases() {
  const list = [API_BASE, "http://localhost:8080"];
  return [...new Set(list.map((base) => String(base || "").replace(/\/+$/, "")))].filter(Boolean);
}

async function fetchJsonWithFallback(path, init) {
  let lastError = "Unknown error";
  const auth = getAuth();
  const headers = new Headers(init?.headers || {});
  if (auth?.token) {
    headers.set("Authorization", `Bearer ${auth.token}`);
  }
  for (const base of candidateApiBases()) {
    try {
      const response = await fetch(`${base}${path}`, { ...init, headers });
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
  const authParams = new URLSearchParams(window.location.search);
  const token = authParams.get("token");
  const userId = authParams.get("user_id");
  const githubUsername = authParams.get("github_username");

  if (!token || !userId || !githubUsername) return;
  localStorage.setItem("pairpulse_auth", JSON.stringify({ token, userId, githubUsername }));
  window.history.replaceState({}, "", `${window.location.origin}${window.location.pathname}?problemId=${encodeURIComponent(problemId)}`);
}

function startGitHubAuth() {
  const redirectUri = `${window.location.origin}${window.location.pathname}?problemId=${encodeURIComponent(problemId)}`;
  window.location.href = `${API_BASE}/auth/github/start?redirect_uri=${encodeURIComponent(redirectUri)}`;
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

function openPairSession(roomCode, problemIdForRoom) {
  const auth = getAuth();
  if (!auth?.userId || !auth?.githubUsername) {
    throw new Error("Sign in first.");
  }

  const sessionUrl = new URL("./session.html", window.location.href);
  sessionUrl.searchParams.set("roomCode", roomCode);
  sessionUrl.searchParams.set("userId", auth.userId);
  sessionUrl.searchParams.set("githubUsername", auth.githubUsername);
  if (problemIdForRoom) {
    sessionUrl.searchParams.set("problemId", problemIdForRoom);
  }
  window.location.href = sessionUrl.toString();
}

function renderProblem(problem) {
  problemHeaderNode.textContent = problem.title;
  problemMetaNode.textContent = `${problem.difficulty.toUpperCase()} • ${problem.topic} • ${problem.publicTestsCount} public + ${problem.hiddenTestsCount} hidden tests`;
  promptNode.textContent = problem.prompt;
  inputFormatNode.textContent = problem.inputFormat;
  outputFormatNode.textContent = problem.outputFormat;
  constraintsNode.innerHTML = problem.constraints.map((item) => `<li>${item}</li>`).join("");

  examplesNode.innerHTML = problem.examples
    .map(
      (example, index) => `
      <div class="example-box">
        <p><strong>Example ${index + 1}</strong></p>
        <pre>Input\n${example.input}</pre>
        <pre>Output\n${example.output}</pre>
      </div>
    `
    )
    .join("");

}

async function loadProblem() {
  if (!problemId) {
    throw new Error("Missing problemId in URL");
  }

  const data = await fetchJsonWithFallback(`/dsa/problems/${encodeURIComponent(problemId)}`);

  currentProblem = data.problem;
  renderProblem(currentProblem);
}

async function startPairSessionForProblem() {
  const auth = getAuth();
  if (!auth?.userId) {
    alert("Sign in first.");
    return;
  }
  if (!currentProblem?.id) {
    alert("Problem is not loaded yet.");
    return;
  }

  const partnerGithubUsername = String(partnerUsernameNode.value || "").trim();

  const sessionData = await fetchJsonWithFallback("/pairing/sessions/start", {
    method: "POST",
    headers: { "Content-Type": "application/json" },
    body: JSON.stringify({})
  });

  const roomCode = sessionData?.session?.roomCode;
  if (!roomCode) {
    throw new Error("Could not create room");
  }

  if (partnerGithubUsername) {
    await fetchJsonWithFallback("/pairing/invite", {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify({
        receiverGithubUsername: partnerGithubUsername,
        roomCode,
        problemId: currentProblem.id
      })
    });
  }

  linkStatusNode.textContent = "Room linked. Redirecting...";
  openPairSession(roomCode, currentProblem.id);
}

storeAuthFromUrlIfPresent();
loadProblem().catch((error) => {
  problemHeaderNode.textContent = "Problem not found";
  problemMetaNode.textContent = error.message || "Could not load problem";
});

document.querySelector("#startPairBtn").addEventListener("click", () => {
  startPairSessionForProblem().catch((error) => {
    linkStatusNode.textContent = `Pair room failed: ${error.message || "Unknown error"}`;
  });
});

document.querySelector("#loginBtn").addEventListener("click", startGitHubAuth);
