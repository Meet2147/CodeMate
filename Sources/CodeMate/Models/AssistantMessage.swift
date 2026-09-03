import Foundation

enum AssistantRole: String, Codable {
    case user, assistant, system
}

struct AssistantMessage: Identifiable, Codable, Hashable {
    var id = UUID()
    var role: AssistantRole
    var text: String
    var timestamp: Date = .now
}

/// Quick-action prompts shown as chips above the assistant's input box.
/// Each maps to a prompt template that gets the current problem + code
/// spliced in before being sent to the model.
enum AssistantQuickAction: String, CaseIterable, Identifiable {
    case explainProblem = "Explain this problem simply"
    case compareApproaches = "Which approach should I use?"
    case reviewMyCode = "Review my code so far"
    case explainStep = "Explain what my code does step-by-step"
    case nextHint = "Give me the next hint"
    case whyWrong = "Why is my output wrong?"
    case complexity = "What's the time/space complexity?"

    var id: String { rawValue }
    var symbol: String {
        switch self {
        case .explainProblem: return "lightbulb"
        case .compareApproaches: return "arrow.triangle.branch"
        case .reviewMyCode: return "checkmark.seal"
        case .explainStep: return "list.number"
        case .nextHint: return "questionmark.circle"
        case .whyWrong: return "exclamationmark.triangle"
        case .complexity: return "speedometer"
        }
    }
}
