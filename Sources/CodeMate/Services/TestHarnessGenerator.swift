import Foundation

struct TestOutcome: Identifiable, Equatable {
    var id: Int { index }
    var index: Int
    var passed: Bool
    var detail: String?
}

enum TestHarnessGenerator {
    private static let beginMarker = "===CODEMATE_TESTS_BEGIN==="
    private static let passPrefix = "CODEMATE_TEST_PASS"
    private static let failPrefix = "CODEMATE_TEST_FAIL"

    /// Appends generated driver code (which calls the student's function
    /// against every case and prints a machine-readable pass/fail line) to
    /// their source. Returns unchanged code if this language/harness combo
    /// isn't supported.
    static func appendDriver(to code: String, harness: TestHarness, language: ProgrammingLanguage) -> String {
        switch language {
        case .swift: return code + "\n\n" + swiftDriver(harness)
        case .python: return code + "\n\n" + pythonDriver(harness)
        default: return code
        }
    }

    private static func swiftDriver(_ harness: TestHarness) -> String {
        var lines = ["// --- CodeMate test harness (auto-generated) ---", "print(\"\(beginMarker)\")"]
        for (i, testCase) in harness.cases.enumerated() {
            let n = i + 1
            var args = testCase.inputs.map { $0.literal(for: .swift) }
            let expected = testCase.expected.literal(for: .swift)

            if let inoutIndex = harness.signature.inoutParamIndex {
                let varName = "cmInput\(n)"
                lines.append("var \(varName) = \(args[inoutIndex])")
                args[inoutIndex] = "&\(varName)"
                lines.append("\(harness.signature.swiftName)(\(args.joined(separator: ", ")))")
                lines.append("let cmActual\(n) = \(varName)")
            } else {
                lines.append("let cmActual\(n) = \(harness.signature.swiftName)(\(args.joined(separator: ", ")))")
            }
            lines.append("let cmExpected\(n) = \(expected)")
            lines.append("""
            if cmActual\(n) == cmExpected\(n) {
                print("\(passPrefix) \(n)")
            } else {
                print("\(failPrefix) \(n) | expected: \\(cmExpected\(n)) | got: \\(cmActual\(n))")
            }
            """)
        }
        return lines.joined(separator: "\n")
    }

    private static func pythonDriver(_ harness: TestHarness) -> String {
        var lines = ["# --- CodeMate test harness (auto-generated) ---", "print(\"\(beginMarker)\")"]
        for (i, testCase) in harness.cases.enumerated() {
            let n = i + 1
            let args = testCase.inputs.map { $0.literal(for: .python) }
            let expected = testCase.expected.literal(for: .python)

            if let inoutIndex = harness.signature.inoutParamIndex {
                lines.append("cm_input\(n) = \(args[inoutIndex])")
                var callArgs = args
                callArgs[inoutIndex] = "cm_input\(n)"
                lines.append("\(harness.signature.pythonName)(\(callArgs.joined(separator: ", ")))")
                lines.append("cm_actual\(n) = cm_input\(n)")
            } else {
                lines.append("cm_actual\(n) = \(harness.signature.pythonName)(\(args.joined(separator: ", ")))")
            }
            lines.append("cm_expected\(n) = \(expected)")
            lines.append("""
            if cm_actual\(n) == cm_expected\(n):
                print("\(passPrefix) \(n)")
            else:
                print(f"\(failPrefix) \(n) | expected: {cm_expected\(n)} | got: {cm_actual\(n)}")
            """)
        }
        return lines.joined(separator: "\n")
    }

    /// Splits raw process output into (everything printed before the
    /// harness ran, parsed per-test outcomes). If the harness never even
    /// started (a compile error, a crash before the marker), `outcomes` is
    /// empty and the raw output already contains whatever explains why.
    static func parseOutput(_ rawOutput: String, expectedCount: Int) -> (preamble: String, outcomes: [TestOutcome]) {
        guard let markerRange = rawOutput.range(of: beginMarker) else {
            return (rawOutput, [])
        }
        let preamble = String(rawOutput[rawOutput.startIndex..<markerRange.lowerBound])
            .trimmingCharacters(in: .whitespacesAndNewlines)
        let resultsText = rawOutput[markerRange.upperBound...]

        var outcomes: [TestOutcome] = []
        for rawLine in resultsText.split(separator: "\n", omittingEmptySubsequences: true) {
            let line = String(rawLine)
            if line.hasPrefix(passPrefix) {
                let index = Int(line.dropFirst(passPrefix.count).trimmingCharacters(in: .whitespaces)) ?? (outcomes.count + 1)
                outcomes.append(TestOutcome(index: index, passed: true, detail: nil))
            } else if line.hasPrefix(failPrefix) {
                let rest = line.dropFirst(failPrefix.count).trimmingCharacters(in: .whitespaces)
                let parts = rest.split(separator: "|", maxSplits: 1).map { $0.trimmingCharacters(in: .whitespaces) }
                let index = Int(parts.first ?? "") ?? (outcomes.count + 1)
                let detail = parts.count > 1 ? parts[1] : nil
                outcomes.append(TestOutcome(index: index, passed: false, detail: detail))
            }
        }
        return (preamble, outcomes)
    }
}
