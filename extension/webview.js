const vscode = acquireVsCodeApi();

const authState = document.querySelector("#authState");
const statusNode = document.querySelector("#status");
const inviteInboxNode = document.querySelector("#inviteInbox");
const sessionStateNode = document.querySelector("#sessionState");

function setStatus(text) {
  statusNode.textContent = text;
}

function renderSessionState(session) {
  if (!session || !session.roomCode) {
    sessionStateNode.innerHTML = '<p class="empty">No active room.</p>';
    return;
  }

  const participants = Array.isArray(session.participants) ? session.participants : [];
  const participantHtml = participants
    .map((participant) => `<li>${participant.display || participant.rawId || "unknown"}</li>`)
    .join("");

  sessionStateNode.innerHTML = `
    <p class="session-meta">Room: <strong>${session.roomCode}</strong></p>
    <ul class="participant-list">${participantHtml || "<li>No participants</li>"}</ul>
  `;
}

function renderInvites(invites) {
  if (!invites.length) {
    inviteInboxNode.innerHTML = '<p class="empty">No pending invites.</p>';
    return;
  }

  inviteInboxNode.innerHTML = invites
    .map(
      (invite) => `
      <article class="invite-item">
        <p class="invite-title">@${invite.senderGithubUsername} invited you</p>
        <p class="invite-meta">${new Date(invite.createdAt).toLocaleString()}</p>
        <div class="invite-actions">
          <button data-action="accept" data-id="${invite.id}">Accept</button>
          <button data-action="decline" data-id="${invite.id}">Decline</button>
        </div>
      </article>
    `
    )
    .join("");
}

document.querySelector("#loginBtn").addEventListener("click", () => {
  setStatus("Opening GitHub login...");
  vscode.postMessage({ type: "oauth-login" });
});

document.querySelector("#inviteBtn").addEventListener("click", () => {
  const partnerUsername = document.querySelector("#partnerUsername").value.trim();
  vscode.postMessage({ type: "invite", partnerUsername });
});

document.querySelector("#createRoomBtn").addEventListener("click", () => {
  vscode.postMessage({ type: "create-room" });
});

document.querySelector("#joinRoomBtn").addEventListener("click", () => {
  const roomCode = document.querySelector("#roomCode").value.trim();
  vscode.postMessage({ type: "join-room", roomCode });
});

document.querySelector("#refreshInvitesBtn").addEventListener("click", () => {
  vscode.postMessage({ type: "load-invites" });
});

inviteInboxNode.addEventListener("click", (event) => {
  const target = event.target;
  if (!(target instanceof HTMLElement)) return;

  const inviteId = target.dataset.id || "";
  const action = target.dataset.action || "";
  if (!inviteId || !action) return;

  if (action === "accept") {
    vscode.postMessage({ type: "accept-invite", inviteId });
  } else if (action === "decline") {
    vscode.postMessage({ type: "decline-invite", inviteId });
  }
});

window.addEventListener("message", (event) => {
  const message = event.data;

  if (message.type === "auth") {
    if (message.auth?.githubUsername) {
      authState.textContent = `Signed in as @${message.auth.githubUsername}`;
      vscode.postMessage({ type: "load-invites" });
    } else {
      authState.textContent = "Not signed in";
      renderInvites([]);
    }
  }

  if (message.type === "status") {
    setStatus(message.text || "");
  }

  if (message.type === "invites") {
    renderInvites(message.invites || []);
  }

  if (message.type === "session-state") {
    renderSessionState(message.session || null);
  }
});
