const vscode = acquireVsCodeApi();

const configNode = document.querySelector("#codemate-session-config");
let roomCode = configNode?.dataset.roomCode || "";
let userId = configNode?.dataset.userId || "";
let githubUsername = configNode?.dataset.githubUsername || "";
let apiBase = configNode?.dataset.apiBase || "http://localhost:8080";

const statusNode = document.querySelector("#status");
const mediaDiagnosticsNode = document.querySelector("#mediaDiagnostics");
const sessionMetaNode = document.querySelector("#sessionMeta");
const localVideo = document.querySelector("#localVideo");
const remoteVideo = document.querySelector("#remoteVideo");
const leaveBtn = document.querySelector("#leaveBtn");
const retryMediaBtn = document.querySelector("#retryMediaBtn");
const toggleCameraBtn = document.querySelector("#toggleCameraBtn");
const toggleMicBtn = document.querySelector("#toggleMicBtn");

const peerConnections = new Map();
let socket = null;
let localStream = null;
let participants = [];
let isInitializing = false;
let cameraEnabled = true;
let micEnabled = true;

function setStatus(message) {
  statusNode.textContent = message;
  vscode.postMessage({ type: "session-status", text: message });
}

function updateMediaButtons() {
  toggleCameraBtn.textContent = cameraEnabled ? "Camera Off" : "Camera On";
  toggleMicBtn.textContent = micEnabled ? "Mic Off" : "Mic On";
}

function publishParticipants() {
  vscode.postMessage({ type: "session-participants", participants });
}

async function refreshMediaDiagnostics(permissionHint) {
  let cameraPermission = permissionHint || "unknown";
  let micPermission = permissionHint || "unknown";

  if (navigator.permissions?.query) {
    try {
      const [cam, mic] = await Promise.all([
        navigator.permissions.query({ name: "camera" }),
        navigator.permissions.query({ name: "microphone" })
      ]);
      cameraPermission = cam.state;
      micPermission = mic.state;
    } catch {
      // Keep fallback values if Permissions API is unavailable in this webview.
    }
  }

  const camTrack = localStream?.getVideoTracks()?.[0] || null;
  const micTrack = localStream?.getAudioTracks()?.[0] || null;

  const camState = camTrack ? (camTrack.enabled ? "on" : "off") : "missing";
  const micState = micTrack ? (micTrack.enabled ? "on" : "off") : "missing";
  const camReady = camTrack?.readyState || "n/a";
  const micReady = micTrack?.readyState || "n/a";
  const previewState = localVideo.srcObject ? "attached" : "detached";

  mediaDiagnosticsNode.textContent =
    `Media: camera ${cameraPermission}/${camState}/${camReady}, mic ${micPermission}/${micState}/${micReady}, preview ${previewState}`;
}

function signalingUrl() {
  const parsed = new URL(apiBase);
  const protocol = parsed.protocol === "https:" ? "wss:" : "ws:";
  return `${protocol}//${parsed.host}/ws`;
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
      setStatus("Video and audio connected.");
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

function openSocket() {
  socket = new WebSocket(signalingUrl());

  socket.onopen = () => {
    socket.send(JSON.stringify({ type: "join-room", roomCode, userId }));
    const hasLocalPreview = Boolean(localStream && localVideo.srcObject);
    setStatus(
      hasLocalPreview
        ? "Connected to session. Local preview on. Waiting for partner..."
        : "Connected to session. Waiting for partner..."
    );
    vscode.postMessage({ type: "request-current-editor" });
  };

  socket.onmessage = async (event) => {
    const message = JSON.parse(event.data);

    if (message.type === "room-state") {
      participants = Array.isArray(message.participants) ? message.participants : [];
      publishParticipants();

      const peers = participants.filter((id) => id !== userId);
      for (const peerId of peers) {
        await makeOffer(peerId);
      }
      return;
    }

    if (message.type === "participant-joined") {
      if (!participants.includes(message.userId)) {
        participants.push(message.userId);
        publishParticipants();
      }

      if (message.userId !== userId) {
        await makeOffer(message.userId);
        setStatus(`Partner joined (${message.userId.replace("user_", "")}).`);
      }
      return;
    }

    if (message.type === "participant-left") {
      participants = participants.filter((id) => id !== message.userId);
      publishParticipants();

      const pc = peerConnections.get(message.userId);
      if (pc) {
        pc.close();
        peerConnections.delete(message.userId);
      }
      remoteVideo.srcObject = null;
      setStatus("Partner left the call.");
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
      vscode.postMessage({ type: "remote-code-update", payload: message.payload });
      return;
    }

    if (message.type === "error") {
      setStatus(message.message || "Signaling error.");
    }
  };

  socket.onerror = () => {
    setStatus("Signaling connection failed.");
  };
}

async function cleanup() {
  if (socket && socket.readyState === WebSocket.OPEN) {
    socket.send(JSON.stringify({ type: "leave-room", roomCode, userId }));
    socket.close();
  }

  socket = null;
  participants = [];
  publishParticipants();

  peerConnections.forEach((pc) => pc.close());
  peerConnections.clear();

  if (localStream) {
    localStream.getTracks().forEach((track) => track.stop());
    localStream = null;
  }

  localVideo.srcObject = null;
  cameraEnabled = true;
  micEnabled = true;
  updateMediaButtons();
  await refreshMediaDiagnostics();
}

async function initSession() {
  if (isInitializing) return;
  isInitializing = true;

  if (!roomCode || !userId) {
    setStatus("Missing room code or user identity.");
    isInitializing = false;
    return;
  }

  sessionMetaNode.textContent = `Room ${roomCode} | @${githubUsername || userId.replace("user_", "")}`;

  await cleanup();

  try {
    localStream = await navigator.mediaDevices.getUserMedia({ video: true, audio: true });
    localVideo.srcObject = localStream;
    localVideo.onloadedmetadata = () => {
      localVideo.play().catch(() => {});
    };
    await localVideo.play().catch(() => {});
    cameraEnabled = true;
    micEnabled = true;
    updateMediaButtons();
    await refreshMediaDiagnostics("granted");
    setStatus("Local camera/mic ready. Waiting for partner...");
  } catch (error) {
    const errorName = error?.name || "UnknownError";
    const reason =
      errorName === "NotAllowedError"
        ? "Permission denied by OS/browser. Allow camera and microphone for VS Code."
        : errorName === "NotFoundError"
          ? "No camera/microphone device found."
          : `Media error: ${errorName}`;
    await refreshMediaDiagnostics(errorName === "NotAllowedError" ? "denied" : "unknown");
    setStatus(`${reason} Call continues without local media. Use Retry Camera/Mic.`);
  }

  openSocket();
  isInitializing = false;
}

async function toggleCamera() {
  if (!localStream) {
    setStatus("No local media stream. Click Retry Camera/Mic first.");
    return;
  }
  const tracks = localStream.getVideoTracks();
  if (!tracks.length) {
    setStatus("No camera track found.");
    return;
  }
  cameraEnabled = !cameraEnabled;
  tracks.forEach((track) => {
    track.enabled = cameraEnabled;
  });
  updateMediaButtons();
  await refreshMediaDiagnostics();
}

async function toggleMic() {
  if (!localStream) {
    setStatus("No local media stream. Click Retry Camera/Mic first.");
    return;
  }
  const tracks = localStream.getAudioTracks();
  if (!tracks.length) {
    setStatus("No microphone track found.");
    return;
  }
  micEnabled = !micEnabled;
  tracks.forEach((track) => {
    track.enabled = micEnabled;
  });
  updateMediaButtons();
  await refreshMediaDiagnostics();
}

leaveBtn.addEventListener("click", async () => {
  await cleanup();
  setStatus("You left the call.");
});

retryMediaBtn.addEventListener("click", () => {
  initSession();
});

toggleCameraBtn.addEventListener("click", () => {
  toggleCamera();
});

toggleMicBtn.addEventListener("click", () => {
  toggleMic();
});

window.addEventListener("unload", () => {
  cleanup();
});

window.addEventListener("message", (event) => {
  const message = event.data;
  if (!message) return;

  if (message.type === "session-init") {
    roomCode = message.roomCode || roomCode;
    userId = message.auth?.userId || userId;
    githubUsername = message.auth?.githubUsername || githubUsername;
    apiBase = message.apiBase || apiBase;
    initSession();
    return;
  }

  if (message.type === "local-code-update") {
    if (!socket || socket.readyState !== WebSocket.OPEN) return;

    socket.send(
      JSON.stringify({
        type: "sync-code",
        roomCode,
        fromUserId: userId,
        payload: message.payload
      })
    );
  }
});

initSession();
updateMediaButtons();
refreshMediaDiagnostics();
