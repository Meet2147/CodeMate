import Foundation

struct Example: Identifiable, Codable, Hashable {
    var id = UUID()
    var input: String
    var output: String
    var explanation: String?
}

/// One candidate approach to solving a problem, ordered roughly from
/// naive to optimal. Shown in the "Choose an approach" panel so the
/// student learns to reason about trade-offs before writing code.
struct Approach: Identifiable, Codable, Hashable {
    var id = UUID()
    var name: String
    var summary: String
    var timeComplexity: String
    var spaceComplexity: String
    var whenToUse: String
    var steps: [String]
}

struct Problem: Identifiable, Codable, Hashable {
    var id: String            // stable slug, e.g. "two-sum"
    var title: String
    var difficulty: Difficulty
    var topics: [Topic]
    var companies: [Company]
    var prompt: String
    var constraints: [String]
    var examples: [Example]
    var hints: [String]       // progressive hints, revealed one at a time
    var approaches: [Approach]
    var starterCode: [ProgrammingLanguage: String]
    var followUp: String?     // e.g. "Could you solve this in O(1) space?"

    var estimatedMinutes: Int {
        switch difficulty {
        case .easy: return 15
        case .medium: return 30
        case .hard: return 50
        }
    }
}

enum ProgrammingLanguage: String, CaseIterable, Identifiable, Codable {
    case swift = "Swift"
    case python = "Python"
    case javascript = "JavaScript"
    case java = "Java"
    case cpp = "C++"

    var id: String { rawValue }

    var fileExtension: String {
        switch self {
        case .swift: return "swift"
        case .python: return "py"
        case .javascript: return "js"
        case .java: return "java"
        case .cpp: return "cpp"
        }
    }

    /// Whether CodeMate can execute this language locally via the system toolchain.
    var isLocallyRunnable: Bool {
        switch self {
        case .swift, .python, .javascript: return true
        case .java, .cpp: return false
        }
    }
}
