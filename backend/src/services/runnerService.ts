import { access, mkdir, mkdtemp, rm, writeFile } from "node:fs/promises";
import { tmpdir } from "node:os";
import { join } from "node:path";
import { spawn } from "node:child_process";

interface ExecuteCodeInput {
  language: "python3" | "cpp";
  code: string;
  input: string;
  roomCode?: string;
}

interface InstallPackageInput {
  language: "python3";
  packageName: string;
  roomCode: string;
}

interface CommandResult {
  stdout: string;
  stderr: string;
  exitCode: number | null;
  timedOut: boolean;
}

interface ExecuteCodeResult {
  ok: boolean;
  language: "python3" | "cpp";
  stdout: string;
  stderr: string;
  compileStdout?: string;
  compileStderr?: string;
  exitCode: number | null;
}

interface InstallResult {
  ok: boolean;
  roomCode: string;
  packageName: string;
  stdout: string;
  stderr: string;
  exitCode: number | null;
}

const maxOutputChars = 12000;
const roomEnvBase = join(tmpdir(), "codemate-room-envs");

function trimOutput(value: string): string {
  if (value.length <= maxOutputChars) {
    return value;
  }
  return `${value.slice(0, maxOutputChars)}\n...[truncated]`;
}

function normalizeRoomCode(roomCode?: string): string {
  const raw = String(roomCode || "default").trim().toLowerCase();
  if (/^[a-z0-9_-]{1,40}$/.test(raw)) {
    return raw;
  }
  return "default";
}

function pythonBinaryPath(venvPath: string): string {
  if (process.platform === "win32") {
    return join(venvPath, "Scripts", "python.exe");
  }
  return join(venvPath, "bin", "python3");
}

function pipBinaryPath(venvPath: string): string {
  if (process.platform === "win32") {
    return join(venvPath, "Scripts", "pip.exe");
  }
  return join(venvPath, "bin", "pip");
}

function runCommand(
  command: string,
  args: string[],
  cwd: string,
  stdinInput: string,
  timeoutMs: number
): Promise<CommandResult> {
  return new Promise((resolve, reject) => {
    const child = spawn(command, args, { cwd });

    let stdout = "";
    let stderr = "";
    let timedOut = false;

    const timer = setTimeout(() => {
      timedOut = true;
      child.kill("SIGKILL");
    }, timeoutMs);

    child.stdout.on("data", (chunk) => {
      stdout += String(chunk);
    });

    child.stderr.on("data", (chunk) => {
      stderr += String(chunk);
    });

    child.on("error", (error: NodeJS.ErrnoException) => {
      clearTimeout(timer);
      if (error.code === "ENOENT") {
        reject(new Error(`Runtime not available: ${command} not found on server.`));
        return;
      }
      reject(error);
    });

    child.on("close", (exitCode) => {
      clearTimeout(timer);
      resolve({
        stdout: trimOutput(stdout),
        stderr: trimOutput(
          timedOut ? `${stderr}\nExecution timed out after ${timeoutMs}ms.` : stderr
        ),
        exitCode,
        timedOut
      });
    });

    if (stdinInput) {
      child.stdin.write(stdinInput);
    }
    child.stdin.end();
  });
}

async function ensureRoomVenv(roomCode?: string): Promise<{ room: string; venvPath: string }> {
  const room = normalizeRoomCode(roomCode);
  const roomPath = join(roomEnvBase, room);
  const venvPath = join(roomPath, "venv");
  const pyPath = pythonBinaryPath(venvPath);

  await mkdir(roomPath, { recursive: true });

  try {
    await access(pyPath);
    return { room, venvPath };
  } catch {
    await runCommand("python3", ["-m", "venv", venvPath], roomPath, "", 10000);
    return { room, venvPath };
  }
}

export async function installPythonPackage(payload: InstallPackageInput): Promise<InstallResult> {
  const packageSpec = String(payload.packageName || "").trim();
  if (!/^[a-zA-Z0-9_.-]+(==[a-zA-Z0-9_.-]+)?$/.test(packageSpec)) {
    throw new Error("Invalid package name. Use letters/numbers/._- and optional ==version");
  }

  const env = await ensureRoomVenv(payload.roomCode);
  const pipPath = pipBinaryPath(env.venvPath);

  const installResult = await runCommand(pipPath, ["install", packageSpec], join(roomEnvBase, env.room), "", 30000);

  return {
    ok: installResult.exitCode === 0 && !installResult.timedOut,
    roomCode: env.room,
    packageName: packageSpec,
    stdout: installResult.stdout,
    stderr: installResult.stderr,
    exitCode: installResult.exitCode
  };
}

export async function executeCode(payload: ExecuteCodeInput): Promise<ExecuteCodeResult> {
  const workspace = await mkdtemp(join(tmpdir(), "codemate-run-"));

  try {
    if (payload.language === "python3") {
      const sourcePath = join(workspace, "main.py");
      await writeFile(sourcePath, payload.code, "utf8");

      const env = await ensureRoomVenv(payload.roomCode);
      const pyPath = pythonBinaryPath(env.venvPath);
      const runResult = await runCommand(pyPath, [sourcePath], workspace, payload.input, 5000);

      return {
        ok: runResult.exitCode === 0 && !runResult.timedOut,
        language: payload.language,
        stdout: runResult.stdout,
        stderr: runResult.stderr,
        exitCode: runResult.exitCode
      };
    }

    const sourcePath = join(workspace, "main.cpp");
    const binaryPath = join(workspace, "main");
    await writeFile(sourcePath, payload.code, "utf8");

    const compileResult = await runCommand(
      "g++",
      ["-std=c++17", "-O2", sourcePath, "-o", binaryPath],
      workspace,
      "",
      8000
    );

    if (compileResult.exitCode !== 0 || compileResult.timedOut) {
      return {
        ok: false,
        language: payload.language,
        stdout: "",
        stderr: "Compilation failed.",
        compileStdout: compileResult.stdout,
        compileStderr: compileResult.stderr,
        exitCode: compileResult.exitCode
      };
    }

    const runResult = await runCommand(binaryPath, [], workspace, payload.input, 5000);

    return {
      ok: runResult.exitCode === 0 && !runResult.timedOut,
      language: payload.language,
      stdout: runResult.stdout,
      stderr: runResult.stderr,
      compileStdout: compileResult.stdout,
      compileStderr: compileResult.stderr,
      exitCode: runResult.exitCode
    };
  } finally {
    await rm(workspace, { recursive: true, force: true });
  }
}
