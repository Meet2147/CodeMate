import SwiftUI

struct AssistantPanelView: View {
    @Environment(\.colorScheme) private var scheme
    let context: AssistantContext

    @State private var messages: [AssistantMessage] = []
    @State private var draft: String = ""
    @State private var isThinking = false
    @State private var errorText: String?
    @State private var hasAPIKey = KeychainService.loadAPIKey()?.isEmpty == false

    private var service: AIAssistantServicing {
        hasAPIKey ? AnthropicAssistantService() : OfflineAssistantService()
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
        .onAppear { hasAPIKey = KeychainService.loadAPIKey()?.isEmpty == false }
    }

    private var header: some View {
        HStack(spacing: 8) {
            Image(systemName: "sparkles").foregroundStyle(CMTheme.accent)
            Text("Assistant").font(.system(size: 13, weight: .bold, design: .rounded)).foregroundStyle(CMTheme.textPrimary(scheme))
            Spacer()
            Circle().fill(hasAPIKey ? CMTheme.success : CMTheme.textSecondary(scheme).opacity(0.5)).frame(width: 6, height: 6)
            Text(hasAPIKey ? "Live" : "Offline")
                .font(.system(size: 9, weight: .bold))
                .foregroundStyle(hasAPIKey ? CMTheme.success : CMTheme.textSecondary(scheme))
        }
        .padding(14)
    }

    private var welcomeCard: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("I'm here so you never get stuck.")
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(CMTheme.textPrimary(scheme))
            Text(hasAPIKey
                 ? "Ask me to explain the problem, compare approaches, review your code, or explain it step by step."
                 : "Add your Anthropic API key in Settings for full live help. For now I can still give hints, compare approaches, and share complexity from this problem's notes.")
                .font(.system(size: 11))
                .foregroundStyle(CMTheme.textSecondary(scheme))
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .neumorphicRaised(padding: 12)
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
