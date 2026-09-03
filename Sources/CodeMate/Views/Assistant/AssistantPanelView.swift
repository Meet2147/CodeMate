import SwiftUI

struct AssistantPanelView: View {
    @Environment(\.colorScheme) private var scheme
    let context: AssistantContext

    @State private var messages: [AssistantMessage] = []
    @State private var draft: String = ""
    @State private var isThinking = false
    @State private var errorText: String?
    @State private var hasAPIKey = KeychainService.loadAPIKey()?.isEmpty == false
    @State private var onDeviceAvailability = OnDeviceAvailability.current

    /// On-device is always preferred (free, private, no key needed). A
    /// user-supplied cloud key is the fallback for Macs without Apple
    /// Intelligence; the canned offline assistant is the last resort.
    private var activeSource: AssistantSource {
        if case .available = onDeviceAvailability { return .onDevice }
        if hasAPIKey { return .cloud }
        if case .unavailable(let reason) = onDeviceAvailability { return .offline(reason: reason) }
        return .offline(reason: "Assistant unavailable.")
    }

    private var service: AIAssistantServicing {
        switch activeSource {
        case .onDevice: return OnDeviceAssistantService()
        case .cloud: return AnthropicAssistantService()
        case .offline: return OfflineAssistantService()
        }
    }

    var body: some View {
        VStack(spacing: 0) {
            header
            Divider()
            ScrollViewReader { proxy in
                ScrollView {
                    LazyVStack(alignment: .leading, spacing: 10) {
                        if messages.isEmpty {
                            welcomeCard
                        }
                        ForEach(messages) { message in
                            MessageBubble(message: message)
                                .id(message.id)
                        }
                        if isThinking {
                            HStack(spacing: 6) {
                                ProgressView().controlSize(.small)
                                Text("Thinking…").font(.system(size: 11)).foregroundStyle(CMTheme.textSecondary(scheme))
                            }
                        }
                        if let errorText {
                            Text(errorText)
                                .font(.system(size: 11))
                                .foregroundStyle(CMTheme.danger)
                                .padding(8)
                                .neumorphicInset(padding: 8)
                        }
                    }
                    .padding(14)
                }
                .onChange(of: messages.count) { _, _ in
                    if let last = messages.last { withAnimation { proxy.scrollTo(last.id, anchor: .bottom) } }
                }
            }
            quickActionChips
            inputBar
        }
        .background(CMTheme.base(scheme))
        .onAppear {
            hasAPIKey = KeychainService.loadAPIKey()?.isEmpty == false
            onDeviceAvailability = OnDeviceAvailability.current
        }
    }

    private var header: some View {
        HStack(spacing: 8) {
            Image(systemName: "sparkles").foregroundStyle(CMTheme.accent)
            Text("Assistant").font(.system(size: 13, weight: .bold, design: .rounded)).foregroundStyle(CMTheme.textPrimary(scheme))
            Spacer()
            Circle().fill(statusColor).frame(width: 6, height: 6)
            Text(statusLabel)
                .font(.system(size: 9, weight: .bold))
                .foregroundStyle(statusColor)
        }
        .padding(14)
    }

    private var statusLabel: String {
        switch activeSource {
        case .onDevice: return "On-device"
        case .cloud: return "Cloud"
        case .offline: return "Offline"
        }
    }

    private var statusColor: Color {
        switch activeSource {
        case .onDevice, .cloud: return CMTheme.success
        case .offline: return CMTheme.textSecondary(scheme).opacity(0.6)
        }
    }

    private var welcomeCard: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("I'm here so you never get stuck.")
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(CMTheme.textPrimary(scheme))
            Text(welcomeBody)
                .font(.system(size: 11))
                .foregroundStyle(CMTheme.textSecondary(scheme))
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .neumorphicRaised(padding: 12)
    }

    private var welcomeBody: String {
        switch activeSource {
        case .onDevice:
            return "Running fully on-device with Apple Intelligence -- no API key, no per-message cost, nothing leaves your Mac. Ask me to explain the problem, compare approaches, review your code, or walk through it step by step."
        case .cloud:
            return "Running on your own Anthropic key (Settings → AI Assistant). Ask me to explain the problem, compare approaches, review your code, or walk through it step by step."
        case .offline(let reason):
            return "\(reason) I can still give hints, compare approaches, and share complexity from this problem's notes -- or add your own Anthropic key in Settings for full help."
        }
    }

    private var quickActionChips: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(AssistantQuickAction.allCases) { action in
                    Button {
                        send(action.rawValue)
                    } label: {
                        Label(action.rawValue, systemImage: action.symbol)
                            .font(.system(size: 10.5, weight: .medium))
                    }
                    .buttonStyle(NeumorphicButtonStyle())
                }
            }
            .padding(.horizontal, 14)
        }
        .padding(.bottom, 8)
    }

    private var inputBar: some View {
        HStack(spacing: 8) {
            TextField("Ask the assistant…", text: $draft, axis: .vertical)
                .textFieldStyle(.plain)
                .lineLimit(1...4)
                .onSubmit { send(draft) }
            Button {
                send(draft)
            } label: {
                Image(systemName: "arrow.up.circle.fill").font(.system(size: 22))
            }
            .buttonStyle(.plain)
            .foregroundStyle(draft.trimmingCharacters(in: .whitespaces).isEmpty ? CMTheme.textSecondary(scheme) : CMTheme.accent)
            .disabled(draft.trimmingCharacters(in: .whitespaces).isEmpty || isThinking)
        }
        .neumorphicInset(padding: 10)
        .padding(14)
    }

    private func send(_ text: String) {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty, !isThinking else { return }
        errorText = nil
        messages.append(AssistantMessage(role: .user, text: trimmed))
        draft = ""
        isThinking = true

        let conversation = messages
        Task {
            do {
                let reply = try await service.reply(conversation: conversation, context: context)
                await MainActor.run {
                    messages.append(AssistantMessage(role: .assistant, text: reply))
                    isThinking = false
                }
            } catch {
                await MainActor.run {
                    errorText = error.localizedDescription
                    isThinking = false
                }
            }
        }
    }
}

private struct MessageBubble: View {
    @Environment(\.colorScheme) private var scheme
    let message: AssistantMessage

    var body: some View {
        HStack {
            if message.role == .user { Spacer(minLength: 30) }
            Text(.init(message.text))
                .font(.system(size: 12))
                .foregroundStyle(message.role == .user ? .white : CMTheme.textPrimary(scheme))
                .padding(10)
                .background(
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .fill(message.role == .user ? AnyShapeStyle(CMTheme.accent.gradient) : AnyShapeStyle(CMTheme.base(scheme)))
                        .shadow(color: CMTheme.shadowDark(scheme), radius: 4, x: 3, y: 3)
                        .shadow(color: CMTheme.shadowLight(scheme), radius: 4, x: -3, y: -3)
                )
                .textSelection(.enabled)
            if message.role == .assistant { Spacer(minLength: 30) }
        }
    }
}
