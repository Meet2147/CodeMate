import Foundation

enum AssistantError: LocalizedError {
    case missingAPIKey
    case network(String)
    case badResponse(Int, String)
    case decoding

    var errorDescription: String? {
        switch self {
        case .missingAPIKey:
            return "Add your Anthropic API key in Settings to enable the live AI assistant."
        case .network(let message):
            return "Network error: \(message)"
        case .badResponse(let code, let message):
            return "Assistant request failed (\(code)): \(message)"
        case .decoding:
            return "Couldn't read the assistant's response."
        }
    }
}

protocol AIAssistantServicing {
    /// Sends the running conversation (already includes the new user turn)
    /// plus grounding context about the current problem/code, and returns
    /// the assistant's reply text.
    func reply(conversation: [AssistantMessage], context: AssistantContext) async throws -> String
}

/// A topic-agnostic view of "what the student is looking at right now" --
/// lets the same assistant ground itself on either a DSA coding problem or
/// an LLD/HLD system-design question without the service layer caring which.
struct AssistantSubject {
    var title: String
    var kind: String              // "DSA problem" or "System design question"
    var difficulty: Difficulty
    var topics: [String]
    var prompt: String
    var hints: [String]
    var approaches: [Approach]
}

extension Problem {
    var asAssistantSubject: AssistantSubject {
        AssistantSubject(title: title, kind: "DSA problem", difficulty: difficulty,
                          topics: topics.map(\.rawValue), prompt: prompt, hints: hints, approaches: approaches)
    }
}

extension SystemDesignQuestion {
    var asAssistantSubject: AssistantSubject {
        let sectionText = sections.map { section in
            "\(section.heading):\n" + section.bullets.map { "- \($0)" }.joined(separator: "\n")
        }.joined(separator: "\n\n")
        let clarifying = clarifyingQuestions.isEmpty ? "" : "\n\nClarifying questions worth asking first:\n" + clarifyingQuestions.map { "- \($0)" }.joined(separator: "\n")
        return AssistantSubject(title: title, kind: "\(scope.rawValue) question", difficulty: difficulty,
                                 topics: companies.map(\.rawValue), prompt: prompt + clarifying + "\n\nStudy scaffold:\n" + sectionText,
                                 hints: clarifyingQuestions, approaches: [])
    }
}

/// Everything the assistant is grounded on for the current session, so
/// its guidance stays specific to the problem the student is actually
/// looking at instead of generic DSA trivia.
struct AssistantContext {
    var subject: AssistantSubject
    var language: ProgrammingLanguage
    var currentCode: String
    var hintsRevealedSoFar: Int
    var lastRunOutput: String?

    init(subject: AssistantSubject, language: ProgrammingLanguage = .swift, currentCode: String = "",
         hintsRevealedSoFar: Int = 0, lastRunOutput: String? = nil) {
        self.subject = subject
        self.language = language
        self.currentCode = currentCode
        self.hintsRevealedSoFar = hintsRevealedSoFar
        self.lastRunOutput = lastRunOutput
    }

    init(problem: Problem, language: ProgrammingLanguage, currentCode: String, hintsRevealedSoFar: Int, lastRunOutput: String?) {
        self.init(subject: problem.asAssistantSubject, language: language, currentCode: currentCode,
                   hintsRevealedSoFar: hintsRevealedSoFar, lastRunOutput: lastRunOutput)
    }

    init(designQuestion: SystemDesignQuestion) {
        self.init(subject: designQuestion.asAssistantSubject)
    }
}

/// Talks to the Anthropic Messages API using the user's own API key
/// (stored in Keychain, entered in Settings). CodeMate ships with no
/// embedded key -- each installation is BYO-key, which keeps inference
/// cost off the app vendor and off the App Store review surface.
final class AnthropicAssistantService: AIAssistantServicing {
    private let endpoint = URL(string: "https://api.anthropic.com/v1/messages")!
    private let model = "claude-sonnet-4-5"
    private let apiKeyProvider: () -> String?

    init(apiKeyProvider: @escaping () -> String? = { KeychainService.loadAPIKey() }) {
        self.apiKeyProvider = apiKeyProvider
    }

    func reply(conversation: [AssistantMessage], context: AssistantContext) async throws -> String {
        guard let apiKey = apiKeyProvider(), !apiKey.isEmpty else {
            throw AssistantError.missingAPIKey
        }

        var request = URLRequest(url: endpoint)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue(apiKey, forHTTPHeaderField: "x-api-key")
        request.setValue("2023-06-01", forHTTPHeaderField: "anthropic-version")

        let body = RequestBody(
            model: model,
            max_tokens: 1024,
            system: Self.systemPrompt(for: context),
            messages: conversation
                .filter { $0.role != .system }
                .map { .init(role: $0.role == .user ? "user" : "assistant", content: $0.text) }
        )

        do {
            request.httpBody = try JSONEncoder().encode(body)
        } catch {
            throw AssistantError.decoding
        }

        let (data, response): (Data, URLResponse)
        do {
            (data, response) = try await URLSession.shared.data(for: request)
        } catch {
            throw AssistantError.network(error.localizedDescription)
        }

        guard let http = response as? HTTPURLResponse else { throw AssistantError.decoding }
        guard (200..<300).contains(http.statusCode) else {
            let message = String(data: data, encoding: .utf8) ?? "unknown error"
            throw AssistantError.badResponse(http.statusCode, message)
        }

        guard let decoded = try? JSONDecoder().decode(ResponseBody.self, from: data),
              let text = decoded.content.first(where: { $0.type == "text" })?.text else {
            throw AssistantError.decoding
        }
        return text
    }

    /// Grounds the model as a patient, Socratic DSA tutor rather than an
    /// answer dispenser -- it should build understanding and confidence,
    /// nudge toward a good approach, and only hand over full code when
    /// the student is stuck after hints or asks directly.
    private static func systemPrompt(for context: AssistantContext) -> String {
        let s = context.subject
        return """
        You are the in-app tutor inside CodeMate, a macOS app that helps students \
        prepare for Amazon/Google/Apple/Microsoft interviews (both coding DSA rounds and \
        system design rounds). You are calm, encouraging, and never make the student feel \
        behind or panicked -- short sentences, concrete next steps.

        Teaching style:
        - Prefer guiding questions and hints over instantly giving full solutions.
        - When explaining the student's own code, walk through it top-to-bottom, plain language,
          and name the *purpose* of each step, not just what each line does.
        - When comparing approaches, always state time/space complexity and the concrete reason
          one approach wins (or loses) for the given constraints.
        - For system design questions, coach the student to ask clarifying questions and reason
          about trade-offs themselves before you volunteer a full design.
        - If the student explicitly asks for the final solution, or has already used all hints,
          give clean, idiomatic \(context.language.rawValue) code (for DSA) or a structured design
          (for system design) with brief comments/explanations.
        - Keep replies focused and skimmable: short paragraphs or bullet points, no filler.

        Current \(s.kind): "\(s.title)" (\(s.difficulty.rawValue)), tags: \
        \(s.topics.joined(separator: ", ")).
        Prompt:
        \(s.prompt)

        Hints/clarifying questions already surfaced to the student (\(context.hintsRevealedSoFar)/\(s.hints.count)): \
        \(s.hints.prefix(context.hintsRevealedSoFar).joined(separator: " | "))

        Student's current \(context.language.rawValue) code (if this is a coding problem):
        ```\(context.language.rawValue.lowercased())
        \(context.currentCode.isEmpty ? "(nothing written yet)" : context.currentCode)
        ```
        \(context.lastRunOutput.map { "Last run output:\n\($0)" } ?? "")
        """
    }

    private struct RequestBody: Encodable {
        var model: String
        var max_tokens: Int
        var system: String
        var messages: [Msg]
        struct Msg: Encodable { var role: String; var content: String }
    }

    private struct ResponseBody: Decodable {
        var content: [ContentBlock]
        struct ContentBlock: Decodable { var type: String; var text: String? }
    }
}

/// Deterministic fallback used when no API key is configured yet, so the
/// assistant panel is never a dead end -- it still gives useful, canned
/// guidance built from the problem's own hints/approaches.
final class OfflineAssistantService: AIAssistantServicing {
    func reply(conversation: [AssistantMessage], context: AssistantContext) async throws -> String {
        let p = context.subject
        guard let last = conversation.last(where: { $0.role == .user })?.text.lowercased() else {
            return "Ask me anything about **\(p.title)** -- I can suggest an approach, explain your code, or give a hint."
        }

        if last.contains("hint") {
            guard context.hintsRevealedSoFar < p.hints.count else {
                return "You've used all \(p.hints.count) hints for this one. Try sketching the approach in comments, or ask me to review what you have."
            }
            return "Hint \(context.hintsRevealedSoFar + 1): \(p.hints[context.hintsRevealedSoFar])"
        }

        if last.contains("approach") || last.contains("which") {
            guard let a = p.approaches.first else { return "No stored approaches for this problem yet." }
            let lines = p.approaches.map { "• \($0.name) — \($0.timeComplexity) time, \($0.spaceComplexity) space: \($0.whenToUse)" }
            return "Here's how the approaches stack up:\n\n" + lines.joined(separator: "\n") + "\n\nStart with **\(a.name)** if you're unsure."
        }

        if last.contains("complex") {
            let lines = p.approaches.map { "• \($0.name): \($0.timeComplexity) time / \($0.spaceComplexity) space" }
            return lines.isEmpty ? "No complexity data stored for this problem." : lines.joined(separator: "\n")
        }

        if last.contains("review") || last.contains("wrong") || last.contains("step") {
            if context.currentCode.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                return "You haven't written any code yet -- start from the starter template and I'll walk through it with you as you go."
            }
            return "Live code review needs the AI assistant connected. Add your Anthropic API key in Settings → Assistant to unlock full reviews, step explanations, and debugging help."
        }

        return "I can explain the problem, compare approaches, give a progressive hint, or review code once you add an Anthropic API key in Settings."
    }
}
