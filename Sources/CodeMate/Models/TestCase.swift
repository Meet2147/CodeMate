import Foundation

/// A language-agnostic value (input argument or expected output) for the
/// test harness. Rendered into real Swift/Python literal syntax by
/// TestHarnessGenerator -- kept as this small closed set of cases (not raw
/// strings) so a problem's test data can drive multiple languages from one
/// definition instead of hand-writing syntax per language.
indirect enum TestValue: Codable, Hashable {
    case int(Int)
    case double(Double)
    case string(String)
    case bool(Bool)
    case array([TestValue])

    func literal(for language: ProgrammingLanguage) -> String {
        switch self {
        case .int(let v): return "\(v)"
        case .double(let v): return "\(v)"
        case .string(let v): return "\"\(TestValue.escape(v))\""
        case .bool(let v):
            switch language {
            case .python: return v ? "True" : "False"
            default: return v ? "true" : "false"
            }
        case .array(let items):
            return "[" + items.map { $0.literal(for: language) }.joined(separator: ", ") + "]"
        }
    }

    private static func escape(_ s: String) -> String {
        s.replacingOccurrences(of: "\\", with: "\\\\").replacingOccurrences(of: "\"", with: "\\\"")
    }
}

/// How to reach the student's function/type from generated test-driver code.
/// Every problem in this app's starter code uses fully positional
/// parameters (every label is `_` in Swift; Python has no labels), so the
/// harness only ever needs to know the callable's name per language --
/// never the parameter labels themselves.
struct FunctionSignature: Codable, Hashable {
    var swiftName: String
    var pythonName: String
    /// 0-based index of a parameter that's mutated in place (Swift `inout`)
    /// instead of being returned -- e.g. "Move Zeroes". The harness checks
    /// that argument's final value against `expected` rather than a return
    /// value. Python needs no special handling here (lists already mutate
    /// by reference), only the Swift driver branches on this.
    var inoutParamIndex: Int?

    init(swiftName: String, pythonName: String, inoutParamIndex: Int? = nil) {
        self.swiftName = swiftName
        self.pythonName = pythonName
        self.inoutParamIndex = inoutParamIndex
    }
}

struct StructuredTestCase: Codable, Hashable {
    var inputs: [TestValue]
    var expected: TestValue
}

/// Attached to a Problem to enable real grading: CodeRunnerService appends
/// generated driver code that calls the student's function against each
/// case and reports pass/fail, instead of just checking "did it crash".
/// Deliberately scoped to plain-value problems (Int/String/Bool/Double and
/// arrays of those) for now -- problems built around custom types
/// (ListNode, TreeNode, design classes like LRUCache) would need bespoke
/// construction/serialization support this doesn't have yet.
struct TestHarness: Codable, Hashable {
    var signature: FunctionSignature
    var cases: [StructuredTestCase]
}
