const API_BASE = (
  localStorage.getItem("codemate_api_base") ||
  (typeof window.CODEMATE_API_BASE === "string" ? window.CODEMATE_API_BASE : "") ||
  "http://localhost:8080"
).replace(/\/+$/, "");
const params = new URLSearchParams(window.location.search);
const roomCode = (params.get("roomCode") || "").trim();
const problemId = (params.get("problemId") || "").trim();

const statusNode = document.querySelector("#status");
const mediaDiagnosticsNode = document.querySelector("#mediaDiagnostics");
const sessionMetaNode = document.querySelector("#sessionMeta");
const problemContextNode = document.querySelector("#problemContext");
const participantsListNode = document.querySelector("#participantsList");
const codeEditorNode = document.querySelector("#codeEditor");
const runOutputNode = document.querySelector("#runOutput");
const languageSelectNode = document.querySelector("#languageSelect");
const packageInputNode = document.querySelector("#packageInput");
const installPackageBtn = document.querySelector("#installPackageBtn");
const runTestsBtn = document.querySelector("#runTestsBtn");
const runCodeBtn = document.querySelector("#runCodeBtn");
const localVideo = document.querySelector("#localVideo");
const remoteVideo = document.querySelector("#remoteVideo");
const leaveBtn = document.querySelector("#leaveBtn");
const retryMediaBtn = document.querySelector("#retryMediaBtn");
const toggleCameraBtn = document.querySelector("#toggleCameraBtn");
const toggleMicBtn = document.querySelector("#toggleMicBtn");
const copyRoomBtn = document.querySelector("#copyRoomBtn");
const backToLobbyBtn = document.querySelector("#backToLobbyBtn");

const peerConnections = new Map();
let socket = null;
let localStream = null;
let participants = [];
let cameraEnabled = true;
let micEnabled = true;
let suppressEditorBroadcast = false;
let suppressLanguageBroadcast = false;
let editorDebounce = null;
let linkedProblem = null;
let needsRemotePlaybackRetry = false;

function getAuth() {
  const raw = localStorage.getItem("pairpulse_auth");
  if (!raw) return null;
  try {
    return JSON.parse(raw);
  } catch {
    return null;
  }
}

const auth = getAuth();
const userId = String(auth?.userId || params.get("userId") || "").trim();
const githubUsername = String(auth?.githubUsername || params.get("githubUsername") || "").trim();

function candidateApiBases() {
  const list = [API_BASE, "http://localhost:8080"];
  return [...new Set(list.map((base) => String(base || "").replace(/\/+$/, "")))].filter(Boolean);
}

async function fetchJsonWithFallback(path, init) {
  let lastError = "Unknown error";
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

function setStatus(message) {
  statusNode.textContent = message;
}

function renderParticipants() {
  participantsListNode.innerHTML = participants
    .map((id) => `<li>${id.replace(/^user_/, "@")} ${id === userId ? "(you)" : ""}</li>`)
    .join("");
}

function updateMediaButtons() {
  toggleCameraBtn.textContent = cameraEnabled ? "Camera Off" : "Camera On";
  toggleMicBtn.textContent = micEnabled ? "Mic Off" : "Mic On";
}

function setRunOutput(text) {
  runOutputNode.textContent = text;
}

async function loadLinkedProblem() {
  if (!problemId) {
    problemContextNode.textContent = "No linked DSA problem for this room.";
    return;
  }

  try {
    const data = await fetchJsonWithFallback(`/dsa/problems/${encodeURIComponent(problemId)}`);
    if (!data?.problem) throw new Error("Problem not found");

    linkedProblem = data.problem;
    problemContextNode.innerHTML = `Linked DSA: <strong>${linkedProblem.title}</strong> (${linkedProblem.difficulty.toUpperCase()}) - <a href="./dsa-problem.html?problemId=${encodeURIComponent(problemId)}" target="_blank" rel="noreferrer">open details</a>`;
    languageSelectNode.value = "python3";
    codeEditorNode.value = linkedProblem.starter?.python3 || codeEditorNode.value;
  } catch (error) {
    problemContextNode.textContent = `Linked DSA problem could not load: ${error.message || "Unknown error"}`;
  }
}

async function refreshMediaDiagnostics(permissionHint = "unknown") {
  let camPermission = permissionHint;
  let micPermission = permissionHint;

  if (navigator.permissions?.query) {
    try {
      const [cam, mic] = await Promise.all([
        navigator.permissions.query({ name: "camera" }),
        navigator.permissions.query({ name: "microphone" })
      ]);
      camPermission = cam.state;
      micPermission = mic.state;
    } catch {
      // Ignore permission API failure.
    }
  }

  const camTrack = localStream?.getVideoTracks()?.[0] || null;
  const micTrack = localStream?.getAudioTracks()?.[0] || null;
  const camState = camTrack ? `${camTrack.enabled ? "on" : "off"}/${camTrack.readyState}` : "missing";
  const micState = micTrack ? `${micTrack.enabled ? "on" : "off"}/${micTrack.readyState}` : "missing";
  const preview = localVideo.srcObject ? "attached" : "detached";

  mediaDiagnosticsNode.textContent = `Media: camera ${camPermission}/${camState}, mic ${micPermission}/${micState}, preview ${preview}`;
}

function signalingUrl() {
  const parsed = new URL(API_BASE);
  const url = new URL(`${parsed.protocol === "https:" ? "wss:" : "ws:"}//${parsed.host}/ws`);
  if (auth?.token) {
    url.searchParams.set("token", auth.token);
  }
  return url.toString();
}

function shouldInitiateOffer(peerId) {
  return String(userId) < String(peerId);
}

function requestRemotePlaybackRetry() {
  if (!needsRemotePlaybackRetry) {
    return;
  }
  remoteVideo.play().then(
    () => {
      needsRemotePlaybackRetry = false;
      setStatus("Partner media connected.");
    },
    () => {}
  );
}

function createPeerConnection(targetUserId) {
  const pc = new RTCPeerConnection({
    iceServers: [
      { urls: "stun:stun.l.google.com:19302" },
      { urls: "stun:stun1.l.google.com:19302" }
    ]
  });

  if (localStream) {
    localStream.getTracks().forEach((track) => pc.addTrack(track, localStream));
  }

  pc.ontrack = (event) => {
    const [stream] = event.streams;
    if (stream) {
      remoteVideo.srcObject = stream;
      remoteVideo.muted = false;
      remoteVideo.play().then(
        () => {
          needsRemotePlaybackRetry = false;
          setStatus("Partner media connected.");
        },
        () => {
          needsRemotePlaybackRetry = true;
          setStatus("Partner media received. Click anywhere once to enable playback.");
        }
      );
    }
  };

  pc.onicecandidate = (event) => {
    if (!event.candidate || !socket || socket.readyState !== WebSocket.OPEN) return;
    socket.send(
      JSON.stringify({
        type: "ice-candidate",
        roomCode,
        fromUserId: userId,
        targetUserId,
        payload: event.candidate
      })
    );
  };

  peerConnections.set(targetUserId, pc);
  return pc;
}

async function makeOffer(targetUserId) {
  const pc = peerConnections.get(targetUserId) || createPeerConnection(targetUserId);
  const offer = await pc.createOffer();
  await pc.setLocalDescription(offer);

  if (!socket || socket.readyState !== WebSocket.OPEN) return;
  socket.send(
    JSON.stringify({
      type: "offer",
      roomCode,
      fromUserId: userId,
      targetUserId,
      payload: offer
    })
  );
}

async function handleOffer(fromUserId, offer) {
  const pc = peerConnections.get(fromUserId) || createPeerConnection(fromUserId);
  await pc.setRemoteDescription(new RTCSessionDescription(offer));
  const answer = await pc.createAnswer();
  await pc.setLocalDescription(answer);

  if (!socket || socket.readyState !== WebSocket.OPEN) return;
  socket.send(
    JSON.stringify({
      type: "answer",
      roomCode,
      fromUserId: userId,
      targetUserId: fromUserId,
      payload: answer
    })
  );
}

async function handleAnswer(fromUserId, answer) {
  const pc = peerConnections.get(fromUserId);
  if (!pc) return;
  await pc.setRemoteDescription(new RTCSessionDescription(answer));
}

async function handleIceCandidate(fromUserId, candidate) {
  const pc = peerConnections.get(fromUserId) || createPeerConnection(fromUserId);
  await pc.addIceCandidate(new RTCIceCandidate(candidate));
}

function broadcastEditorState() {
  if (!socket || socket.readyState !== WebSocket.OPEN) return;
  socket.send(
    JSON.stringify({
      type: "sync-code",
      roomCode,
      fromUserId: userId,
      payload: {
        text: codeEditorNode.value,
        language: languageSelectNode.value,
        updatedAt: Date.now()
      }
    })
  );
}

function openSocket() {
  socket = new WebSocket(signalingUrl());

  socket.onopen = () => {
    socket.send(JSON.stringify({ type: "join-room", roomCode, userId }));
    setStatus("Connected. Waiting for partner...");
    broadcastEditorState();
  };

  socket.onmessage = async (event) => {
    const message = JSON.parse(event.data);

    if (message.type === "room-state") {
      participants = Array.isArray(message.participants) ? message.participants : [];
      renderParticipants();
      const peers = participants.filter((id) => id !== userId);
      for (const peerId of peers) {
        if (shouldInitiateOffer(peerId)) {
          await makeOffer(peerId);
        }
      }
      return;
    }

    if (message.type === "participant-joined") {
      if (!participants.includes(message.userId)) {
        participants.push(message.userId);
        renderParticipants();
      }

      if (message.userId !== userId) {
        if (shouldInitiateOffer(message.userId)) {
          await makeOffer(message.userId);
        }
        setStatus(`@${message.userId.replace("user_", "")} joined.`);
        broadcastEditorState();
      }
      return;
    }

    if (message.type === "participant-left") {
      participants = participants.filter((id) => id !== message.userId);
      renderParticipants();

      const pc = peerConnections.get(message.userId);
      if (pc) {
        pc.close();
        peerConnections.delete(message.userId);
      }

      remoteVideo.srcObject = null;
      setStatus("Partner left the session.");
      return;
    }

    if (message.type === "offer") {
      await handleOffer(message.fromUserId, message.payload);
      return;
    }

    if (message.type === "answer") {
      await handleAnswer(message.fromUserId, message.payload);
      return;
    }

    if (message.type === "ice-candidate") {
      await handleIceCandidate(message.fromUserId, message.payload);
      return;
    }

    if (message.type === "sync-code") {
      const text = message.payload?.text;
      const language = message.payload?.language;

      if (typeof text === "string" && text !== codeEditorNode.value) {
        suppressEditorBroadcast = true;
        codeEditorNode.value = text;
        suppressEditorBroadcast = false;
      }

      if (typeof language === "string" && language !== languageSelectNode.value) {
        suppressLanguageBroadcast = true;
        languageSelectNode.value = language;
        suppressLanguageBroadcast = false;
      }
      return;
    }

    if (message.type === "error") {
      setStatus(message.message || "Session error.");
    }
  };

  socket.onerror = () => {
    setStatus("Signaling connection failed.");
  };
}

function cleanupSession() {
  if (socket && socket.readyState === WebSocket.OPEN) {
    socket.send(JSON.stringify({ type: "leave-room", roomCode, userId }));
    socket.close();
  }

  peerConnections.forEach((pc) => pc.close());
  peerConnections.clear();

  if (localStream) {
    localStream.getTracks().forEach((track) => track.stop());
  }
}

async function initMedia() {
  try {
    localStream = await navigator.mediaDevices.getUserMedia({ video: true, audio: true });
    localVideo.srcObject = localStream;
    await localVideo.play().catch(() => {});
    cameraEnabled = true;
    micEnabled = true;
    updateMediaButtons();
    await refreshMediaDiagnostics("granted");
    setStatus("Local media ready. Waiting for partner...");
  } catch (error) {
    const name = error?.name || "UnknownError";
    const reason =
      name === "NotAllowedError"
        ? "Permission denied. Allow camera/microphone and retry."
        : name === "NotFoundError"
          ? "No camera/mic found."
          : `Media error: ${name}`;

    await refreshMediaDiagnostics(name === "NotAllowedError" ? "denied" : "unknown");
    setStatus(`${reason} You can still collaborate on code.`);
  }
}

async function toggleCamera() {
  if (!localStream) {
    setStatus("No local stream. Retry media first.");
    return;
  }
  const tracks = localStream.getVideoTracks();
  if (!tracks.length) return;
  cameraEnabled = !cameraEnabled;
  tracks.forEach((track) => {
    track.enabled = cameraEnabled;
  });
  updateMediaButtons();
  await refreshMediaDiagnostics();
}

async function toggleMic() {
  if (!localStream) {
    setStatus("No local stream. Retry media first.");
    return;
  }
  const tracks = localStream.getAudioTracks();
  if (!tracks.length) return;
  micEnabled = !micEnabled;
  tracks.forEach((track) => {
    track.enabled = micEnabled;
  });
  updateMediaButtons();
  await refreshMediaDiagnostics();
}

async function runCode() {
  const language = languageSelectNode.value;
  const code = codeEditorNode.value;

  runCodeBtn.disabled = true;
  setRunOutput("Running code...");

  try {
    const result = await fetchJsonWithFallback("/runner/execute", {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify({ language, code, input: "", roomCode })
    });

    const outputParts = [];

    if (result.compileStderr || result.compileStdout) {
      outputParts.push("== Compilation ==");
      if (result.compileStdout) outputParts.push(result.compileStdout);
      if (result.compileStderr) outputParts.push(result.compileStderr);
    }

    outputParts.push("== Program Output ==");
    outputParts.push(result.stdout || "(no stdout)");

    if (result.stderr) {
      outputParts.push("== Errors ==");
      outputParts.push(result.stderr);
    }

    outputParts.push(`== Exit Code: ${result.exitCode ?? "null"} ==`);
    setRunOutput(outputParts.join("\n\n"));
  } catch (error) {
    setRunOutput(`Run failed: ${error.message || "Unknown error"}`);
  } finally {
    runCodeBtn.disabled = false;
  }
}

async function runLinkedProblemTests() {
  if (!problemId) {
    setRunOutput("No linked DSA problem in this room.");
    return;
  }

  const language = languageSelectNode.value;
  const code = codeEditorNode.value;
  runTestsBtn.disabled = true;
  setRunOutput("Running linked DSA tests...");

  try {
    const result = await fetchJsonWithFallback("/dsa/submit", {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify({ problemId, language, code })
    });

    const lines = [
      `== DSA Judge ==`,
      `Problem: ${problemId}`,
      `Status: ${result.status}`,
      `Passed: ${result.passed}/${result.total}`,
      ""
    ];

    for (const test of result.tests || []) {
      lines.push(
        `Test #${test.id} (${test.visibility}): ${test.passed ? "PASS" : "FAIL"} | ${test.durationMs}ms`
      );
      if (!test.passed) {
        lines.push(`Expected: ${test.expected || "(empty)"}`);
        lines.push(`Actual: ${test.actual || "(empty)"}`);
      }
      if (test.stderr) {
        lines.push(`stderr: ${test.stderr}`);
      }
      lines.push("");
    }

    setRunOutput(lines.join("\n"));
  } catch (error) {
    setRunOutput(`Judge failed: ${error.message || "Unknown error"}`);
  } finally {
    runTestsBtn.disabled = false;
  }
}

async function installPackage() {
  const language = languageSelectNode.value;
  const packageName = packageInputNode.value.trim();

  if (language !== "python3") {
    setRunOutput("Package install is only supported for Python 3.");
    return;
  }

  if (!packageName) {
    setRunOutput("Enter a package name first (example: requests or numpy==1.26.4).");
    return;
  }

  installPackageBtn.disabled = true;
  setRunOutput(`Installing package: ${packageName} ...`);

  try {
    const result = await fetchJsonWithFallback("/runner/install", {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify({ language, packageName, roomCode })
    });

    const lines = [
      `== Package Install (${result.ok ? "OK" : "FAILED"}) ==`,
      `Package: ${result.packageName}`,
      `Room: ${result.roomCode}`,
      "",
      result.stdout || "",
      result.stderr ? `\n== Errors ==\n${result.stderr}` : "",
      `\n== Exit Code: ${result.exitCode ?? "null"} ==`
    ];
    setRunOutput(lines.join("\n"));
  } catch (error) {
    setRunOutput(`Install failed: ${error.message || "Unknown error"}`);
  } finally {
    installPackageBtn.disabled = false;
  }
}

async function init() {
  if (!auth?.token || !roomCode || !userId) {
    setStatus("Missing auth token or room identity.");
    return;
  }

  sessionMetaNode.textContent = `Room ${roomCode} | @${githubUsername || userId.replace("user_", "")}`;
  codeEditorNode.value = `# Room ${roomCode}\n# Shared browser editor\n\nprint(\"Hello from CodeMate\")\n`;
  languageSelectNode.value = "python3";
  await loadLinkedProblem();

  await initMedia();
  openSocket();
}

codeEditorNode.addEventListener("input", () => {
  if (suppressEditorBroadcast) return;

  if (editorDebounce) {
    clearTimeout(editorDebounce);
  }
  editorDebounce = setTimeout(() => {
    broadcastEditorState();
  }, 120);
});

languageSelectNode.addEventListener("change", () => {
  if (!suppressLanguageBroadcast && linkedProblem?.starter?.[languageSelectNode.value]) {
    codeEditorNode.value = linkedProblem.starter[languageSelectNode.value];
  }
  if (suppressLanguageBroadcast) return;
  broadcastEditorState();
});

runCodeBtn.addEventListener("click", () => {
  runCode();
});

runTestsBtn.addEventListener("click", () => {
  runLinkedProblemTests();
});

installPackageBtn.addEventListener("click", () => {
  installPackage();
});

copyRoomBtn.addEventListener("click", async () => {
  try {
    await navigator.clipboard.writeText(roomCode);
    setStatus("Room code copied.");
  } catch {
    setStatus(`Room code: ${roomCode}`);
  }
});

retryMediaBtn.addEventListener("click", async () => {
  if (localStream) {
    localStream.getTracks().forEach((track) => track.stop());
    localStream = null;
  }
  localVideo.srcObject = null;
  await initMedia();
});

toggleCameraBtn.addEventListener("click", () => {
  toggleCamera();
});

toggleMicBtn.addEventListener("click", () => {
  toggleMic();
});

leaveBtn.addEventListener("click", () => {
  cleanupSession();
  window.location.href = "./index.html";
});

backToLobbyBtn.addEventListener("click", () => {
  cleanupSession();
  window.location.href = "./app.html";
});

window.addEventListener("beforeunload", cleanupSession);
window.addEventListener("pointerdown", requestRemotePlaybackRetry);

updateMediaButtons();
refreshMediaDiagnostics();
init();
