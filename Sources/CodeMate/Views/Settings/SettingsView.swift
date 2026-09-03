import SwiftUI

struct SettingsView: View {
    @Environment(\.colorScheme) private var scheme
    @Environment(\.dismiss) private var dismiss
    @State private var apiKey: String = KeychainService.loadAPIKey() ?? ""
    @State private var savedConfirmation = false

    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            HStack {
                Text("Settings")
                    .font(.system(size: 18, weight: .bold, design: .rounded))
                    .foregroundStyle(CMTheme.textPrimary(scheme))
                Spacer()
                Button("Done") { dismiss() }
                    .buttonStyle(NeumorphicButtonStyle(prominent: true))
            }

            VStack(alignment: .leading, spacing: 10) {
                HStack(spacing: 6) {
                    Image(systemName: "sparkles").foregroundStyle(CMTheme.accent)
                    Text("AI Assistant").font(.system(size: 13, weight: .bold)).foregroundStyle(CMTheme.textPrimary(scheme))
                }
                Text("CodeMate's assistant runs on your own Anthropic API key -- it's stored securely in the macOS Keychain and only ever sent to api.anthropic.com. Without a key, the assistant still works offline using this problem's hints and approach notes.")
                    .font(.system(size: 11.5))
                    .foregroundStyle(CMTheme.textSecondary(scheme))

                SecureField("sk-ant-...", text: $apiKey)
                    .textFieldStyle(.plain)
                    .neumorphicInset(padding: 10)

                HStack(spacing: 10) {
                    Button("Save Key") {
                        KeychainService.save(apiKey: apiKey.trimmingCharacters(in: .whitespacesAndNewlines))
                        savedConfirmation = true
                        DispatchQueue.main.asyncAfter(deadline: .now() + 2) { savedConfirmation = false }
                    }
                    .buttonStyle(NeumorphicButtonStyle(prominent: true))
                    .disabled(apiKey.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)

                    Button("Remove Key") {
                        KeychainService.clear()
                        apiKey = ""
                    }
                    .buttonStyle(NeumorphicButtonStyle(tint: CMTheme.danger))

                    if savedConfirmation {
                        Label("Saved", systemImage: "checkmark.circle.fill")
                            .font(.system(size: 11, weight: .semibold))
                            .foregroundStyle(CMTheme.success)
                    }
                }

                Link("Get an API key from console.anthropic.com", destination: URL(string: "https://console.anthropic.com/")!)
                    .font(.system(size: 11))
            }
            .neumorphicRaised(padding: 16)

            Spacer()
        }
        .padding(20)
        .background(CMTheme.base(scheme))
    }
}
