import Foundation

struct RunResult {
    var output: String
    var exitCode: Int32
    var durationMs: Int
}

enum RunnerError: LocalizedError {
    case unsupportedLanguage(ProgrammingLanguage)
    case toolchainNotFound(String)

    var errorDescription: String? {
        switch self {
        case .unsupportedLanguage(let lang):
            return "\(lang.rawValue) can't run locally yet -- try Swift, Python, or JavaScript, or use an online judge for now."
        case .toolchainNotFound(let tool):
            return "Couldn't find `\(tool)` on this Mac. Install it (e.g. via Xcode Command Line Tools or Homebrew) to run \(tool) code locally."
        }
    }
}

/// Executes the student's own code locally via the system toolchain, purely
/// for quick sanity-checking against the examples on this machine. This is
/// intentionally NOT a sandboxed judge -- it runs with the current user's
/// permissions, exactly like running the same file from Terminal would.
/// A production "Run against hidden tests" feature should instead go
/// through a server-side sandboxed executor.
actor CodeRunnerService {
    func run(code: String, language: ProgrammingLanguage) async throws -> RunResult {
        guard language.isLocallyRunnable else { throw RunnerError.unsupportedLanguage(language) }

        let tmpDir = FileManager.default.temporaryDirectory
            .appendingPathComponent("CodeMateRun-\(UUID().uuidString)", isDirectory: true)
        try FileManager.default.createDirectory(at: tmpDir, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: tmpDir) }

        let fileURL = tmpDir.appendingPathComponent("main.\(language.fileExtension)")
        try code.write(to: fileURL, atomically: true, encoding: .utf8)

        let (executable, arguments) = try launchCommand(for: language, fileURL: fileURL)
        guard FileManager.default.isExecutableFile(atPath: executable) else {
            throw RunnerError.toolchainNotFound((executable as NSString).lastPathComponent)
        }

        let process = Process()
        process.executableURL = URL(fileURLWithPath: executable)
        process.arguments = arguments

        let outPipe = Pipe()
        let errPipe = Pipe()
        process.standardOutput = outPipe
        process.standardError = errPipe

        let start = Date()
        try process.run()
        process.waitUntilExit()
        let duration = Int(Date().timeIntervalSince(start) * 1000)

        let outData = outPipe.fileHandleForReading.readDataToEndOfFile()
        let errData = errPipe.fileHandleForReading.readDataToEndOfFile()
        var combined = String(data: outData, encoding: .utf8) ?? ""
        if let errText = String(data: errData, encoding: .utf8), !errText.isEmpty {
            combined += (combined.isEmpty ? "" : "\n") + errText
        }

        return RunResult(output: combined.isEmpty ? "(no output)" : combined,
                          exitCode: process.terminationStatus,
                          durationMs: duration)
    }

    private func launchCommand(for language: ProgrammingLanguage, fileURL: URL) throws -> (String, [String]) {
        switch language {
        case .swift:
            return ("/usr/bin/env", ["swift", fileURL.path])
        case .python:
            return ("/usr/bin/env", ["python3", fileURL.path])
        case .javascript:
            return ("/usr/bin/env", ["node", fileURL.path])
        case .java, .cpp:
            throw RunnerError.unsupportedLanguage(language)
        }
    }
}
