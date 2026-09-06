const vscode = require("vscode");

const AUTH_KEY = "codemate.auth";

let activeSidebarView = null;
let activeSessionPanel = null;
let pendingAuthResolve = null;
let currentSessionState = null;
let applyingRemoteEdit = false;

class CodeMateViewProvider {
  constructor(context) {
    this.context = context;
  }

  resolveWebviewView(webviewView) {
    activeSidebarView = webviewView;
    const { webview } = webviewView;

    webview.options = {
      enableScripts: true
    };

    webview.html = getSidebarHtml(webview);

    webview.onDidReceiveMessage(async (message) => {
      try {
        if (message.type === "oauth-login") {
          await startGitHubLogin(this.context);
          postAuthState(this.context);
          await pushInviteInbox(this.context);
          return;
        }

        if (message.type === "load-invites") {
          await pushInviteInbox(this.context);
          return;
        }

        if (message.type === "accept-invite") {
          const auth = this.context.globalState.get(AUTH_KEY);
          if (!auth?.githubUsername) {
            throw new Error("Sign in first.");
          }
          const inviteId = String(message.inviteId || "").trim();
          if (!inviteId) {
            throw new Error("Invite ID is required.");
          }

          const response = await fetch(`${getApiBase()}/pairing/accept`, {
            method: "POST",
            headers: { "Content-Type": "application/json" },
            body: JSON.stringify({ inviteId, receiverGithubUsername: auth.githubUsername })
          });
          const data = await response.json();
          if (!response.ok) {
            throw new Error(data.error || "Could not accept invite.");
          }

          webview.postMessage({ type: "status", text: "Invite accepted." });
          await pushInviteInbox(this.context);
          return;
        }

        if (message.type === "decline-invite") {
          const auth = this.context.globalState.get(AUTH_KEY);
          if (!auth?.githubUsername) {
            throw new Error("Sign in first.");
          }
          const inviteId = String(message.inviteId || "").trim();
          if (!inviteId) {
            throw new Error("Invite ID is required.");
          }

          const response = await fetch(`${getApiBase()}/pairing/decline`, {
            method: "POST",
            headers: { "Content-Type": "application/json" },
            body: JSON.stringify({ inviteId, receiverGithubUsername: auth.githubUsername })
          });
          const data = await response.json();
          if (!response.ok) {
            throw new Error(data.error || "Could not decline invite.");
          }

          webview.postMessage({ type: "status", text: "Invite declined." });
          await pushInviteInbox(this.context);
          return;
        }

        if (message.type === "invite") {
          const auth = this.context.globalState.get(AUTH_KEY);
          if (!auth?.userId) {
            throw new Error("Sign in first.");
          }
          if (!message.partnerUsername) {
            throw new Error("Partner GitHub username is required.");
          }

          const response = await fetch(`${getApiBase()}/pairing/invite`, {
            method: "POST",
            headers: { "Content-Type": "application/json" },
            body: JSON.stringify({
              senderUserId: auth.userId,
              receiverGithubUsername: String(message.partnerUsername).trim()
            })
          });
          const data = await response.json();
          if (!response.ok) {
            throw new Error(data.error || "Invite failed.");
          }
          webview.postMessage({ type: "status", text: `Invite sent: ${data.invite.id.slice(0, 8)}...` });
          await pushInviteInbox(this.context);
          return;
        }

        if (message.type === "create-room") {
          const auth = this.context.globalState.get(AUTH_KEY);
          if (!auth?.userId) {
            throw new Error("Sign in first.");
          }

          const response = await fetch(`${getApiBase()}/pairing/sessions/start`, {
            method: "POST",
            headers: { "Content-Type": "application/json" },
            body: JSON.stringify({ ownerUserId: auth.userId })
          });
          const data = await response.json();
          if (!response.ok) {
            throw new Error(data.error || "Could not create room.");
          }

          openSessionPanel(data.session.roomCode, auth);
          webview.postMessage({ type: "status", text: `Room created: ${data.session.roomCode}` });
          return;
        }

        if (message.type === "join-room") {
          const auth = this.context.globalState.get(AUTH_KEY);
          if (!auth?.userId) {
            throw new Error("Sign in first.");
          }

          const roomCode = String(message.roomCode || "").trim();
          if (!roomCode) {
            throw new Error("Room code is required.");
          }

          const response = await fetch(`${getApiBase()}/pairing/sessions/join-by-room`, {
            method: "POST",
            headers: { "Content-Type": "application/json" },
            body: JSON.stringify({ roomCode, userId: auth.userId })
          });
          const data = await response.json();
          if (!response.ok) {
            throw new Error(data.error || "Could not join room.");
          }

          openSessionPanel(data.session.roomCode, auth);
          webview.postMessage({ type: "status", text: `Joined room: ${data.session.roomCode}` });
          return;
        }
      } catch (error) {
        webview.postMessage({ type: "status", text: error.message || "Unexpected error." });
      }
    });

    postAuthState(this.context);
    postSessionState();
    pushInviteInbox(this.context).catch((error) => {
      webview.postMessage({ type: "status", text: error.message || "Unable to load invites." });
    });
  }
}

function createNonce() {
  const chars = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789";
  let value = "";
  for (let i = 0; i < 32; i += 1) {
    value += chars.charAt(Math.floor(Math.random() * chars.length));
  }
  return value;
}

function getApiBase() {
  const configured = vscode.workspace.getConfiguration("codemate").get("apiBase");
  const base = typeof configured === "string" && configured.trim() ? configured.trim() : "http://localhost:8080";
  return base.replace(/\/+$/, "");
}

function getWsBaseFromHttpBase(httpBase) {
  const url = new URL(httpBase);
  const wsProtocol = url.protocol === "https:" ? "wss:" : "ws:";
  return `${wsProtocol}//${url.host}`;
}

function formatUserId(userId) {
  return userId.replace(/^user_/, "@");
}

function getRedirectUri() {
  return `${vscode.env.uriScheme}://meetjethwa.codemate/auth-callback`;
}

async function pushInviteInbox(context) {
  if (!activeSidebarView) return;

  const auth = context.globalState.get(AUTH_KEY);
  if (!auth?.githubUsername) {
    activeSidebarView.webview.postMessage({ type: "invites", invites: [] });
    return;
  }

  const response = await fetch(
    `${getApiBase()}/pairing/invites?receiverGithubUsername=${encodeURIComponent(auth.githubUsername)}`
  );
  const data = await response.json();
  if (!response.ok) {
    throw new Error(data.error || "Unable to load invites.");
  }

  activeSidebarView.webview.postMessage({ type: "invites", invites: data.invites || [] });
}

async function startGitHubLogin(context) {
  const redirectUri = getRedirectUri();
  const authStartUrl = `${getApiBase()}/auth/github/start?redirect_uri=${encodeURIComponent(redirectUri)}`;

  const callbackPromise = new Promise((resolve, reject) => {
    pendingAuthResolve = { resolve, reject };
    setTimeout(() => {
      if (pendingAuthResolve) {
        pendingAuthResolve = null;
        reject(new Error("GitHub login timed out."));
      }
    }, 120000);
  });

  await vscode.env.openExternal(vscode.Uri.parse(authStartUrl));
  const auth = await callbackPromise;
  await context.globalState.update(AUTH_KEY, auth);
}

function postAuthState(context) {
  if (!activeSidebarView) return;
  const auth = context.globalState.get(AUTH_KEY) || null;
  activeSidebarView.webview.postMessage({ type: "auth", auth });
}

function postSessionState() {
  if (!activeSidebarView) return;

  const payload = currentSessionState
    ? {
        roomCode: currentSessionState.roomCode,
        participants: currentSessionState.participants.map((id) => ({
          rawId: id,
          display: formatUserId(id)
        }))
      }
    : null;

  activeSidebarView.webview.postMessage({ type: "session-state", session: payload });
}

function getSidebarHtml(webview) {
  const scriptUri = webview.asWebviewUri(vscode.Uri.joinPath(vscode.Uri.file(__dirname), "webview.js"));
  const styleUri = webview.asWebviewUri(vscode.Uri.joinPath(vscode.Uri.file(__dirname), "webview.css"));

  return `<!doctype html>
<html>
  <head>
    <meta charset="UTF-8" />
    <meta http-equiv="Content-Security-Policy" content="default-src 'none'; style-src ${webview.cspSource}; script-src ${webview.cspSource};" />
    <meta name="viewport" content="width=device-width, initial-scale=1.0" />
    <link rel="stylesheet" href="${styleUri}">
    <title>CodeMate</title>
  </head>
  <body>
    <main>
      <h2>CodeMate</h2>
      <button id="loginBtn">Sign In with GitHub</button>
      <p id="authState">Not signed in</p>

      <section>
        <h3>Active Session</h3>
        <div id="sessionState" class="empty">No active room.</div>
      </section>

      <hr>
      <input id="partnerUsername" placeholder="Partner GitHub username" />
      <button id="inviteBtn">Send Invite</button>
      <hr>
      <section>
        <h3>Invite Inbox</h3>
        <button id="refreshInvitesBtn">Refresh Invites</button>
        <div id="inviteInbox"></div>
      </section>
      <hr>
      <button id="createRoomBtn">Create Video Room</button>
      <input id="roomCode" placeholder="Room code" />
      <button id="joinRoomBtn">Join Room</button>
      <p id="status"></p>
    </main>
    <script src="${scriptUri}"></script>
  </body>
</html>`;
}

function openSessionPanel(roomCode, auth) {
  const apiBase = getApiBase();

  currentSessionState = {
    roomCode,
    participants: [auth.userId],
    sharedDocUri: null
  };
  postSessionState();
  ensureSharedEditorOpen(roomCode).catch(() => {});

  if (activeSessionPanel) {
    activeSessionPanel.reveal(vscode.ViewColumn.Beside);
    activeSessionPanel.webview.postMessage({ type: "session-init", roomCode, auth, apiBase });
    return;
  }

  const panel = vscode.window.createWebviewPanel(
    "codemate.session",
    `CodeMate Session: ${roomCode}`,
    vscode.ViewColumn.Beside,
    {
      enableScripts: true,
      retainContextWhenHidden: true
    }
  );

  activeSessionPanel = panel;
  panel.onDidDispose(() => {
    activeSessionPanel = null;
    currentSessionState = null;
    postSessionState();
  });

  panel.webview.onDidReceiveMessage(async (message) => {
    if (message.type === "session-participants") {
      if (currentSessionState) {
        currentSessionState.participants = Array.isArray(message.participants)
          ? message.participants
          : currentSessionState.participants;
        postSessionState();
      }
      return;
    }

    if (message.type === "request-current-editor") {
      pushCurrentEditorToSession();
      return;
    }

    if (message.type === "remote-code-update") {
      await applyRemoteCodeUpdate(message.payload);
      return;
    }

    if (message.type === "session-status" && activeSidebarView) {
      activeSidebarView.webview.postMessage({ type: "status", text: message.text || "" });
    }
  });

  panel.webview.html = getSessionHtml(panel.webview, roomCode, auth, apiBase);
}

function getSessionHtml(webview, roomCode, auth, apiBase) {
  const scriptUri = webview.asWebviewUri(
    vscode.Uri.joinPath(vscode.Uri.file(__dirname), "sessionWebview.js")
  );
  const styleUri = webview.asWebviewUri(
    vscode.Uri.joinPath(vscode.Uri.file(__dirname), "sessionWebview.css")
  );
  const nonce = createNonce();
  const wsBase = getWsBaseFromHttpBase(apiBase);

  return `<!doctype html>
<html>
  <head>
    <meta charset="UTF-8" />
    <meta http-equiv="Content-Security-Policy" content="default-src 'none'; img-src ${webview.cspSource} blob: data:; style-src ${webview.cspSource}; script-src 'nonce-${nonce}'; connect-src ${apiBase} ${wsBase}; media-src blob:;" />
    <meta name="viewport" content="width=device-width, initial-scale=1.0" />
    <meta id="codemate-session-config" data-room-code="${roomCode}" data-user-id="${auth.userId}" data-github-username="${auth.githubUsername}" data-api-base="${apiBase}" />
    <link rel="stylesheet" href="${styleUri}" />
    <title>CodeMate Session</title>
  </head>
  <body>
    <main class="session-wrap">
      <header class="session-header">
        <h1>CodeMate Live Session</h1>
        <p id="sessionMeta"></p>
      </header>

      <section class="video-grid">
        <article class="video-card">
          <h2>You</h2>
          <video id="localVideo" autoplay playsinline muted></video>
        </article>
        <article class="video-card">
          <h2>Partner</h2>
          <video id="remoteVideo" autoplay playsinline></video>
        </article>
      </section>

      <footer class="session-footer">
        <div class="status-wrap">
          <p id="status">Initializing camera and mic...</p>
          <p id="mediaDiagnostics">Media: checking permissions...</p>
        </div>
        <div class="actions">
          <button id="toggleCameraBtn">Camera Off</button>
          <button id="toggleMicBtn">Mic Off</button>
          <button id="retryMediaBtn">Retry Camera/Mic</button>
          <button id="leaveBtn">Leave Call</button>
        </div>
      </footer>
    </main>
    <script nonce="${nonce}" src="${scriptUri}"></script>
  </body>
</html>`;
}

function getActiveEditorPayload() {
  if (currentSessionState?.sharedDocUri) {
    const sharedEditor = vscode.window.visibleTextEditors.find(
      (editor) => editor.document.uri.toString() === currentSessionState.sharedDocUri
    );
    if (sharedEditor) {
      return {
        text: sharedEditor.document.getText(),
        languageId: sharedEditor.document.languageId,
        fileName: sharedEditor.document.fileName || "CodeMate Shared Buffer"
      };
    }
  }

  const editor = vscode.window.activeTextEditor;
  if (!editor) {
    return null;
  }

  return {
    text: editor.document.getText(),
    languageId: editor.document.languageId,
    fileName: editor.document.fileName || "CodeMate Live Buffer"
  };
}

function pushCurrentEditorToSession() {
  if (!activeSessionPanel || !currentSessionState) return;

  const payload = getActiveEditorPayload();
  if (!payload) return;

  activeSessionPanel.webview.postMessage({ type: "local-code-update", payload });
}

async function ensureSharedEditorOpen(roomCode) {
  if (!currentSessionState) return;

  const title = `CodeMate Room ${roomCode}`;
  const existing = vscode.workspace.textDocuments.find(
    (doc) => doc.isUntitled && doc.getText().startsWith(`// ${title}`)
  );

  if (existing) {
    currentSessionState.sharedDocUri = existing.uri.toString();
    await vscode.window.showTextDocument(existing, { preview: false, viewColumn: vscode.ViewColumn.One });
    return;
  }

  const document = await vscode.workspace.openTextDocument({
    language: "javascript",
    content: `// ${title}\n// Shared collaborative buffer\n\n`
  });
  currentSessionState.sharedDocUri = document.uri.toString();
  await vscode.window.showTextDocument(document, { preview: false, viewColumn: vscode.ViewColumn.One });
}

async function applyRemoteCodeUpdate(payload) {
  if (!payload || typeof payload.text !== "string") return;

  let editor = null;
  if (currentSessionState?.sharedDocUri) {
    editor =
      vscode.window.visibleTextEditors.find(
        (candidate) => candidate.document.uri.toString() === currentSessionState.sharedDocUri
      ) || null;
  }
  if (!editor) {
    editor = vscode.window.activeTextEditor;
  }

  if (!editor) {
    const document = await vscode.workspace.openTextDocument({
      content: payload.text,
      language: payload.languageId || "plaintext"
    });
    editor = await vscode.window.showTextDocument(document, { preview: false });
    if (currentSessionState) {
      currentSessionState.sharedDocUri = document.uri.toString();
    }
    return;
  }

  const currentText = editor.document.getText();
  if (currentText === payload.text) {
    return;
  }

  applyingRemoteEdit = true;
  try {
    const fullRange = new vscode.Range(
      editor.document.positionAt(0),
      editor.document.positionAt(currentText.length)
    );

    await editor.edit((editBuilder) => {
      editBuilder.replace(fullRange, payload.text);
    });

    if (payload.languageId && editor.document.languageId !== payload.languageId) {
      await vscode.languages.setTextDocumentLanguage(editor.document, payload.languageId);
    }
  } finally {
    applyingRemoteEdit = false;
  }
}

function activate(context) {
  const provider = new CodeMateViewProvider(context);

  context.subscriptions.push(vscode.window.registerWebviewViewProvider("codemate.sidebar", provider));

  context.subscriptions.push(
    vscode.commands.registerCommand("codemate.openPanel", async () => {
      await vscode.commands.executeCommand("workbench.view.extension.codemate");
    })
  );

  context.subscriptions.push(
    vscode.workspace.onDidChangeTextDocument((event) => {
      if (applyingRemoteEdit) return;
      const activeEditor = vscode.window.activeTextEditor;
      if (!activeEditor) return;
      if (event.document !== activeEditor.document) return;
      pushCurrentEditorToSession();
    })
  );

  context.subscriptions.push(
    vscode.window.onDidChangeActiveTextEditor(() => {
      pushCurrentEditorToSession();
    })
  );

  context.subscriptions.push(
    vscode.window.registerUriHandler({
      handleUri(uri) {
        const params = new URLSearchParams(uri.query);
        const token = params.get("token") || "";
        const userId = params.get("user_id") || "";
        const githubUsername = params.get("github_username") || "";

        if (!pendingAuthResolve) {
          return;
        }

        if (!token || !userId || !githubUsername) {
          pendingAuthResolve.reject(new Error("OAuth callback missing auth fields."));
          pendingAuthResolve = null;
          return;
        }

        pendingAuthResolve.resolve({ token, userId, githubUsername });
        pendingAuthResolve = null;
      }
    })
  );
}

function deactivate() {}

module.exports = {
  activate,
  deactivate
};
