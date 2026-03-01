import { mkdtemp, rm, writeFile } from "node:fs/promises";
import { tmpdir } from "node:os";
import { join } from "node:path";
import { spawn } from "node:child_process";
import { DsaDifficulty, DsaLanguage, DsaTestCase, dsaProblems, getProblemById } from "./dsaCatalog.js";

interface CommandResult {
  stdout: string;
  stderr: string;
  exitCode: number | null;
  timedOut: boolean;
  durationMs: number;
}

export interface DsaProblemSummary {
  id: string;
  title: string;
  difficulty: DsaDifficulty;
  topic: string;
}

export interface DsaProblemDetails {
  id: string;
  title: string;
  difficulty: DsaDifficulty;
  topic: string;
  prompt: string;
  inputFormat: string;
  outputFormat: string;
  constraints: string[];
  examples: Array<{ input: string; output: string }>;
  starter: Record<DsaLanguage, string>;
  publicTestsCount: number;
  hiddenTestsCount: number;
}

export interface DsaSubmitResult {
  problemId: string;
  language: DsaLanguage;
  passed: number;
  total: number;
  status: "accepted" | "wrong_answer" | "runtime_error" | "compile_error" | "time_limit_exceeded";
  tests: Array<{
    id: number;
    visibility: "public" | "hidden";
    passed: boolean;
    expected: string;
    actual: string;
    stderr: string;
    durationMs: number;
  }>;
}

function trimOutput(value: string, limit = 10000): string {
  if (value.length <= limit) return value;
  return `${value.slice(0, limit)}\n...[truncated]`;
}

function normalizeOutput(value: string): string {
  return value
    .trim()
    .split("\n")
    .map((line) => line.trim())
    .join("\n");
}

function runCommand(command: string, args: string[], cwd: string, stdinInput: string, timeoutMs: number): Promise<CommandResult> {
  return new Promise((resolve, reject) => {
    const started = Date.now();
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
        stderr: trimOutput(timedOut ? `${stderr}\nExecution timed out after ${timeoutMs}ms.` : stderr),
        exitCode,
        timedOut,
        durationMs: Date.now() - started
      });
    });

    if (stdinInput) {
      child.stdin.write(stdinInput);
    }
    child.stdin.end();
  });
}

function classifyStatus(compileFailed: boolean, timedOut: boolean, hadRuntimeError: boolean, passed: number, total: number): DsaSubmitResult["status"] {
  if (compileFailed) return "compile_error";
  if (timedOut) return "time_limit_exceeded";
  if (hadRuntimeError) return "runtime_error";
  if (passed === total) return "accepted";
  return "wrong_answer";
}

export function listDsaProblems(): { trackName: string; targetCount: number; availableCount: number; problems: DsaProblemSummary[] } {
  return {
    trackName: "CodeMate Top 150 DSA",
    targetCount: 150,
    availableCount: dsaProblems.length,
    problems: dsaProblems.map((problem) => ({
      id: problem.id,
      title: problem.title,
      difficulty: problem.difficulty,
      topic: problem.topic
    }))
  };
}

export function getDsaProblem(problemId: string): DsaProblemDetails | null {
  const problem = getProblemById(problemId);
  if (!problem) return null;

  return {
    id: problem.id,
    title: problem.title,
    difficulty: problem.difficulty,
    topic: problem.topic,
    prompt: problem.prompt,
    inputFormat: problem.inputFormat,
    outputFormat: problem.outputFormat,
    constraints: problem.constraints,
    examples: problem.examples,
    starter: problem.starter,
    publicTestsCount: problem.publicTests.length,
    hiddenTestsCount: problem.hiddenTests.length
  };
}

async function runPython(problemTests: Array<{ visibility: "public" | "hidden"; case: DsaTestCase }>, code: string): Promise<DsaSubmitResult["tests"]> {
  const workspace = await mkdtemp(join(tmpdir(), "codemate-dsa-py-"));
  try {
    const sourcePath = join(workspace, "main.py");
    await writeFile(sourcePath, code, "utf8");

    const results: DsaSubmitResult["tests"] = [];
    for (let index = 0; index < problemTests.length; index += 1) {
      const test = problemTests[index];
      const run = await runCommand("python3", [sourcePath], workspace, `${test.case.input}\n`, 3500);
      const actual = normalizeOutput(run.stdout);
      const expected = normalizeOutput(test.case.expected);
      const passed = run.exitCode === 0 && !run.timedOut && actual === expected;

      results.push({
        id: index + 1,
        visibility: test.visibility,
        passed,
        expected,
        actual,
        stderr: run.stderr,
        durationMs: run.durationMs
      });

      if (run.timedOut || run.exitCode !== 0) {
        break;
      }
    }

    return results;
  } finally {
    await rm(workspace, { recursive: true, force: true });
  }
}

async function runCpp(problemTests: Array<{ visibility: "public" | "hidden"; case: DsaTestCase }>, code: string): Promise<{ tests: DsaSubmitResult["tests"]; compileError: string }> {
  const workspace = await mkdtemp(join(tmpdir(), "codemate-dsa-cpp-"));
  try {
    const sourcePath = join(workspace, "main.cpp");
    const binaryPath = join(workspace, "main");
    await writeFile(sourcePath, code, "utf8");

    const compile = await runCommand("g++", ["-std=c++17", "-O2", sourcePath, "-o", binaryPath], workspace, "", 8000);
    if (compile.exitCode !== 0 || compile.timedOut) {
      return {
        tests: [
          {
            id: 1,
            visibility: "public",
            passed: false,
            expected: "",
            actual: "",
            stderr: compile.stderr || "Compilation failed.",
            durationMs: compile.durationMs
          }
        ],
        compileError: compile.stderr || "Compilation failed"
      };
    }

    const results: DsaSubmitResult["tests"] = [];
    for (let index = 0; index < problemTests.length; index += 1) {
      const test = problemTests[index];
      const run = await runCommand(binaryPath, [], workspace, `${test.case.input}\n`, 3500);
      const actual = normalizeOutput(run.stdout);
      const expected = normalizeOutput(test.case.expected);
      const passed = run.exitCode === 0 && !run.timedOut && actual === expected;

      results.push({
        id: index + 1,
        visibility: test.visibility,
        passed,
        expected,
        actual,
        stderr: run.stderr,
        durationMs: run.durationMs
      });

      if (run.timedOut || run.exitCode !== 0) {
        break;
      }
    }

    return { tests: results, compileError: "" };
  } finally {
    await rm(workspace, { recursive: true, force: true });
  }
}

export async function submitDsaSolution(problemId: string, language: DsaLanguage, code: string): Promise<DsaSubmitResult> {
  const problem = getProblemById(problemId);
  if (!problem) {
    throw new Error("Problem not found");
  }

  const trimmedCode = String(code || "").trim();
  if (!trimmedCode) {
    throw new Error("Code is required");
  }

  const testSet = [
    ...problem.publicTests.map((test) => ({ visibility: "public" as const, case: test })),
    ...problem.hiddenTests.map((test) => ({ visibility: "hidden" as const, case: test }))
  ];

  let tests: DsaSubmitResult["tests"] = [];
  let compileFailed = false;

  if (language === "python3") {
    tests = await runPython(testSet, code);
  } else {
    const cpp = await runCpp(testSet, code);
    tests = cpp.tests;
    compileFailed = Boolean(cpp.compileError);
  }

  const passed = tests.filter((test) => test.passed).length;
  const total = testSet.length;
  const timedOut = tests.some((test) => /timed out/i.test(test.stderr));
  const runtimeErr = tests.some((test) => Boolean(test.stderr) && !/timed out/i.test(test.stderr));

  return {
    problemId,
    language,
    passed,
    total,
    status: classifyStatus(compileFailed, timedOut, runtimeErr, passed, total),
    tests
  };
}
