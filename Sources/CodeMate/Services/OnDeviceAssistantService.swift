import Foundation

#if canImport(FoundationModels)
import FoundationModels
#endif

/// Where the assistant's answer to the *next* message would come from,
/// so the UI can show an honest status ("On-device", "Cloud (your key)",
/// "Offline") instead of just a generic connected/disconnected dot.
enum AssistantSource: Equatable {
    case onDevice
    case cloud
    case offline(reason: String)
}

enum OnDeviceAvailability: Equatable {
    case available
    case unavailable(reason: String)

    /// Synchronous, cheap to call from view bodies -- doesn't spin up a session.
    static var current: OnDeviceAvailability {
        #if canImport(FoundationModels)
        if #available(macOS 26.0, *) {
            switch SystemLanguageModel.default.availability {
            case .available:
                return .available
            case .unavailable(let reason):
                switch reason {
                case .deviceNotEligible:
                    return .unavailable(reason: "This Mac doesn't support Apple Intelligence.")
                case .appleIntelligenceNotEnabled:
                    return .unavailable(reason: "Turn on Apple Intelligence in System Settings to use the on-device assistant.")
                case .modelNotReady:
                    return .unavailable(reason: "The on-device model is still downloading/preparing -- try again shortly.")
                @unknown default:
                    return .unavailable(reason: "The on-device model isn't available right now.")
                }
            }
        } else {
            return .unavailable(reason: "Requires macOS 26 or later.")
        }
        #else
        return .unavailable(reason: "This build wasn't compiled with on-device model support.")
        #endif
    }
}

/// Runs the assistant fully on-device via Apple's system language model
/// (Apple Intelligence) -- no API key, no per-message cost, nothing ever
/// leaves the Mac. This is CodeMate's default assistant; cloud (BYO Anthropic
/// key) and the offline canned assistant are fallbacks for unsupported
/// hardware/OS versions.
final class OnDeviceAssistantService: AIAssistantServicing {
    func reply(conversation: [AssistantMessage], context: AssistantContext) async throws -> String {
        #if canImport(FoundationModels)
        guard #available(macOS 26.0, *) else {
            throw AssistantError.network("On-device assistant requires macOS 26 or later.")
        }
        guard case .available = OnDeviceAvailability.current else {
            if case .unavailable(let reason) = OnDeviceAvailability.current {
                throw AssistantError.network(reason)
            }
            throw AssistantError.network("The on-device model isn't available right now.")
        }
        guard let lastUserMessage = conversation.last(where: { $0.role == .user })?.text else {
            return "Ask me anything about this problem."
        }

        let session = LanguageModelSession(instructions: Self.systemPrompt(for: context))
        do {
            let response = try await session.respond(to: lastUserMessage)
            return response.content
        } catch {
            throw AssistantError.network(error.localizedDescription)
        }
        #else
        throw AssistantError.network("This build wasn't compiled with on-device model support.")
        #endif
    }

    private static func systemPrompt(for context: AssistantContext) -> String {
        let s = context.subject
        return """
        You are the in-app tutor inside CodeMate, a macOS app that helps students prepare for \
        technical interviews (both coding DSA rounds and system design rounds). You are calm, \
        encouraging, and never make the student feel behind or panicked -- short sentences, \
        concrete next steps. Prefer guiding questions and hints over instantly giving full \
        solutions; when explaining code, walk through it top-to-bottom naming the purpose of \
        each step, not just what each line does. Keep replies short and skimmable.

        Current \(s.kind): "\(s.title)" (\(s.difficulty.rawValue)), tags: \(s.topics.joined(separator: ", ")).
        Prompt: \(s.prompt)
        Hints already revealed (\(context.hintsRevealedSoFar)/\(s.hints.count)): \(s.hints.prefix(context.hintsRevealedSoFar).joined(separator: " | "))
        Student's current \(context.language.rawValue) code:
        \(context.currentCode.isEmpty ? "(nothing written yet)" : context.currentCode)
        \(context.lastRunOutput.map { "Last run output: \($0)" } ?? "")
        """
    }
}
