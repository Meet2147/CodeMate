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

const authStatus = document.querySelector("#authStatus");
const inviteListNode = document.querySelector("#inviteList");
const recentRoomsNode = document.querySelector("#recentRooms");
const recentRoomsKey = "codemate_recent_rooms";

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
    // Keep current token.
  }
}

function getRecentRooms() {
  const raw = localStorage.getItem(recentRoomsKey);
  if (!raw) return [];
  try {
    const items = JSON.parse(raw);
    return Array.isArray(items) ? items : [];
  } catch {
    return [];
  }
}

function rememberRoom(roomCode, problemId) {
  if (!roomCode) return;
  const items = getRecentRooms().filter((item) => item?.roomCode !== roomCode);
  items.unshift({
    roomCode,
    problemId: problemId || "",
    updatedAt: Date.now()
  });
  localStorage.setItem(recentRoomsKey, JSON.stringify(items.slice(0, 10)));
}

function renderRecentRooms() {
  if (!recentRoomsNode) return;
  const items = getRecentRooms();
  if (!items.length) {
    recentRoomsNode.innerHTML = "<p>No recent rooms yet.</p>";
    return;
  }

  recentRoomsNode.innerHTML = items
    .map((item) => {
      const date = new Date(Number(item.updatedAt || Date.now())).toLocaleString();
      return `
      <article class="invite-item">
        <p><strong>Room ${item.roomCode}</strong></p>
        ${item.problemId ? `<p class="invite-meta">Problem: ${item.problemId}</p>` : ""}
        <p class="invite-meta">${date}</p>
        <button data-rejoin-room="${item.roomCode}" data-problem-id="${item.problemId || ""}">Rejoin Room</button>
      </article>
    `;
    })
    .join("");
}

function openVideoRoom(roomCode, problemId) {
  const auth = getAuth();
  if (!auth?.userId || !auth?.githubUsername) {
    alert("Sign in first.");
    return;
  }

  const sessionUrl = new URL("./session.html", window.location.href);
  sessionUrl.searchParams.set("roomCode", roomCode);
  sessionUrl.searchParams.set("userId", auth.userId);
  sessionUrl.searchParams.set("githubUsername", auth.githubUsername);
  if (problemId) {
    sessionUrl.searchParams.set("problemId", problemId);
  }
  rememberRoom(roomCode, problemId);
  renderRecentRooms();
  window.location.href = sessionUrl.toString();
}

function startGitHubAuth() {
  const redirectUri = `${window.location.origin}${window.location.pathname}`;
  window.location.href = `${API_BASE}/auth/github/start?redirect_uri=${encodeURIComponent(redirectUri)}`;
}

function renderAuthState() {
  const auth = getAuth();
  authStatus.textContent = auth?.githubUsername ? `Signed in as @${auth.githubUsername}` : "Not signed in";
}

function renderInviteList(invites) {
  if (!invites.length) {
    inviteListNode.innerHTML = '<p>No pending invites.</p>';
    return;
  }

  inviteListNode.innerHTML = invites
    .map(
      (invite) => `
      <article class="invite-item">
        <p><strong>@${invite.senderGithubUsername}</strong> invited you</p>
        ${invite.problemId ? `<p class="invite-meta">Problem: ${invite.problemId}</p>` : ""}
        <p class="invite-meta">${new Date(invite.createdAt).toLocaleString()}</p>
        <button data-accept-invite="${invite.id}" data-room-code="${invite.roomCode || ""}" data-problem-id="${invite.problemId || ""}">Accept & Join</button>
      </article>
    `
    )
    .join("");
}

async function loadInvites() {
  const auth = getAuth();
  if (!auth?.githubUsername) {
    renderInviteList([]);
    return;
  }

  const data = await fetchJsonWithFallback("/pairing/invites?status=pending");
  renderInviteList(data.invites || []);
}

storeAuthFromUrlIfPresent();
renderRecentRooms();
refreshAuthTokenIfPossible().finally(() => {
  renderAuthState();
  loadInvites().catch(() => renderInviteList([]));
});

document.addEventListener("click", async (event) => {
  const target = event.target;
  if (!(target instanceof HTMLElement)) return;

  if (target.id === "githubSignIn") {
    startGitHubAuth();
  }

  if (target.id === "inviteAndCreateRoom") {
    const auth = getAuth();
    const inviteUsernameInput = document.querySelector("#inviteUsername");
    const receiverGithubUsername = inviteUsernameInput.value.trim();

    if (!auth?.userId) {
      alert("Sign in first.");
      return;
    }
    if (!receiverGithubUsername) {
      alert("Enter partner GitHub username.");
      return;
    }

    try {
      const sessionData = await fetchJsonWithFallback("/pairing/sessions/start", {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({})
      });

      await fetchJsonWithFallback("/pairing/invite", {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({
          receiverGithubUsername,
          roomCode: sessionData.session.roomCode
        })
      });

      openVideoRoom(sessionData.session.roomCode);
    } catch (error) {
      alert(error.message || "Could not start invite flow");
    }
  }

  if (target.id === "joinVideoRoom") {
    const auth = getAuth();
    const joinRoomCodeInput = document.querySelector("#joinRoomCode");
    const roomCode = joinRoomCodeInput.value.trim();

    if (!auth?.userId) {
      alert("Sign in first.");
      return;
    }
    if (!roomCode) {
      alert("Enter a room code.");
      return;
    }

    try {
      const data = await fetchJsonWithFallback("/pairing/sessions/join-by-room", {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({ roomCode })
      });
      openVideoRoom(data.session.roomCode);
    } catch (error) {
      alert(error.message || "Could not join room");
    }
  }

  if (target.dataset.acceptInvite) {
    const auth = getAuth();
    const inviteId = String(target.dataset.acceptInvite || "").trim();
    const inviteRoomCode = String(target.dataset.roomCode || "").trim();
    const inviteProblemId = String(target.dataset.problemId || "").trim();

    if (!auth?.userId || !auth?.githubUsername) {
      alert("Sign in first.");
      return;
    }

    if (!inviteId || !inviteRoomCode) {
      alert("Invite is missing room code.");
      return;
    }

    try {
      await fetchJsonWithFallback("/pairing/accept", {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({ inviteId })
      });

      const joinData = await fetchJsonWithFallback("/pairing/sessions/join-by-room", {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({ roomCode: inviteRoomCode })
      });

      openVideoRoom(joinData.session.roomCode, inviteProblemId || undefined);
    } catch (error) {
      alert(error.message || "Could not accept and join");
    }
  }

  if (target.dataset.rejoinRoom) {
    const auth = getAuth();
    const roomCodeToJoin = String(target.dataset.rejoinRoom || "").trim();
    const problemIdToJoin = String(target.dataset.problemId || "").trim();
    if (!auth?.userId) {
      alert("Sign in first.");
      return;
    }
    if (!roomCodeToJoin) {
      alert("Missing room code.");
      return;
    }
    try {
      const data = await fetchJsonWithFallback("/pairing/sessions/join-by-room", {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({ roomCode: roomCodeToJoin })
      });
      openVideoRoom(data.session.roomCode, problemIdToJoin || undefined);
    } catch (error) {
      alert(error.message || "Could not rejoin room");
    }
  }

  if (target.id === "refreshInvites") {
    loadInvites().catch((error) => {
      alert(error.message || "Could not load invites");
    });
  }
});
