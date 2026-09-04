import SwiftUI

struct SettingsView: View {
    @Environment(\.colorScheme) private var scheme
    @Environment(\.dismiss) private var dismiss
    @Environment(AppPreferences.self) private var prefs
    @Environment(LicenseManager.self) private var licenseManager
    @Environment(AuthManager.self) private var auth
    @State private var apiKey: String = KeychainService.loadAPIKey() ?? ""
    @State private var savedConfirmation = false
    @State private var showsCompanyPicker = false
    @State private var showsPaywall = false
    @State private var onDeviceAvailability = OnDeviceAvailability.current

    private var onDeviceStatusText: String {
        switch onDeviceAvailability {
        case .available: return "On-device model ready"
        case .unavailable(let reason): return reason
        }
    }

    private var onDeviceStatusColor: Color {
        switch onDeviceAvailability {
        case .available: return CMTheme.success
        case .unavailable: return CMTheme.warning
        }
    }

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

            if let user = auth.currentUser {
                HStack(spacing: 12) {
                    Image(systemName: user.provider == .apple ? "applelogo" : "g.circle.fill")
                        .font(.system(size: 18))
                        .foregroundStyle(CMTheme.textPrimary(scheme))
                        .frame(width: 32, height: 32)
                        .background(Circle().fill(CMTheme.shadowDark(scheme).opacity(0.2)))
                    VStack(alignment: .leading, spacing: 2) {
                        Text(user.displayName?.isEmpty == false ? user.displayName! : (user.email ?? "Signed in"))
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundStyle(CMTheme.textPrimary(scheme))
                        HStack(spacing: 4) {
                            Text(user.email ?? "")
                                .font(.system(size: 10.5))
                                .foregroundStyle(CMTheme.textSecondary(scheme))
                            if DeveloperAccess.isDeveloper(email: user.email) {
                                Text("DEVELOPER")
                                    .font(.system(size: 8, weight: .bold))
                                    .padding(.horizontal, 5).padding(.vertical, 2)
                                    .background(Capsule().fill(CMTheme.warning.opacity(0.25)))
                                    .foregroundStyle(CMTheme.warning)
                            }
                        }
                    }
                    Spacer()
                    Button("Sign Out") { auth.signOut() }
                        .buttonStyle(NeumorphicButtonStyle(tint: CMTheme.danger))
                }
                .neumorphicRaised(padding: 12)
            }

            HStack(spacing: 12) {
                VStack(alignment: .leading, spacing: 2) {
                    HStack(spacing: 6) {
                        Image(systemName: "star.fill").foregroundStyle(CMTheme.accent)
                        Text("CodeMate \(licenseManager.currentTier.displayName)")
                            .font(.system(size: 13, weight: .bold))
                            .foregroundStyle(CMTheme.textPrimary(scheme))
                    }
                    Text(licenseManager.currentTier == .max ? "You have everything, unlimited." : licenseManager.currentTier.tagline)
                        .font(.system(size: 11))
                        .foregroundStyle(CMTheme.textSecondary(scheme))
                }
                Spacer()
                Button(licenseManager.currentTier == .free ? "Upgrade" : "Manage Plan") { showsPaywall = true }
                    .buttonStyle(NeumorphicButtonStyle(tint: CMTheme.accent, prominent: licenseManager.currentTier == .free))
            }
            .neumorphicRaised(padding: 16)

            VStack(alignment: .leading, spacing: 10) {
                HStack(spacing: 6) {
                    Image(systemName: "building.2").foregroundStyle(CMTheme.accent)
                    Text("Target Companies").font(.system(size: 13, weight: .bold)).foregroundStyle(CMTheme.textPrimary(scheme))
                }
                Text("Practice and LLD/HLD open pre-filtered to these companies.")
                    .font(.system(size: 11.5))
                    .foregroundStyle(CMTheme.textSecondary(scheme))

                if prefs.targetCompanies.isEmpty {
                    Text("No companies selected yet -- every question shows by default.")
                        .font(.system(size: 11.5))
                        .foregroundStyle(CMTheme.textSecondary(scheme))
                } else {
                    HStack(spacing: 6) {
                        ForEach(Array(prefs.targetCompanies).sorted(by: { $0.rawValue < $1.rawValue })) { company in
                            Text(company.initials)
                                .font(.system(size: 9, weight: .bold))
                                .padding(.horizontal, 7).padding(.vertical, 3)
                                .background(Capsule().fill(CMTheme.companyColor(company).opacity(0.18)))
                                .foregroundStyle(CMTheme.companyColor(company))
                        }
                    }
                }

                Button("Change Target Companies") { showsCompanyPicker = true }
                    .buttonStyle(NeumorphicButtonStyle())
            }
            .neumorphicRaised(padding: 16)

            VStack(alignment: .leading, spacing: 10) {
                HStack(spacing: 6) {
                    Image(systemName: "sparkles").foregroundStyle(CMTheme.accent)
                    Text("AI Assistant").font(.system(size: 13, weight: .bold)).foregroundStyle(CMTheme.textPrimary(scheme))
                }

                HStack(spacing: 6) {
                    Circle().fill(onDeviceStatusColor).frame(width: 6, height: 6)
                    Text(onDeviceStatusText)
                        .font(.system(size: 11.5, weight: .medium))
                        .foregroundStyle(CMTheme.textPrimary(scheme))
                }

                Text("CodeMate's assistant runs fully on-device using Apple Intelligence by default -- no API key, no per-message cost, nothing ever leaves your Mac. If this Mac doesn't support that, add your own Anthropic key below as a cloud fallback (stored in the macOS Keychain, only ever sent to api.anthropic.com). Without either, the assistant still works offline using each problem's hints and approach notes.")
                    .font(.system(size: 11.5))
                    .foregroundStyle(CMTheme.textSecondary(scheme))

                Text("CLOUD FALLBACK KEY (OPTIONAL)")
                    .font(.system(size: 9.5, weight: .bold))
                    .foregroundStyle(CMTheme.textSecondary(scheme))
                    .padding(.top, 4)

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
        .onAppear { onDeviceAvailability = OnDeviceAvailability.current }
        .sheet(isPresented: $showsCompanyPicker) {
            CompanyPickerSheet()
        }
        .sheet(isPresented: $showsPaywall) {
            PaywallView()
        }
    }
}

/// Sheet used from Settings to change target companies after onboarding.
/// Edits a local draft so "Cancel" discards changes cleanly.
private struct CompanyPickerSheet: View {
    @Environment(\.colorScheme) private var scheme
    @Environment(\.dismiss) private var dismiss
    @Environment(AppPreferences.self) private var prefs
    @State private var draft: Set<Company> = []

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("Target Companies")
                    .font(.system(size: 16, weight: .bold, design: .rounded))
                    .foregroundStyle(CMTheme.textPrimary(scheme))
                Spacer()
                Button("Cancel") { dismiss() }
                    .buttonStyle(NeumorphicButtonStyle())
                Button("Save") {
                    prefs.targetCompanies = draft
                    dismiss()
                }
                .buttonStyle(NeumorphicButtonStyle(prominent: true))
            }
            ScrollView {
                CompanyPickerGrid(selected: $draft)
            }
        }
        .padding(20)
        .frame(width: 560, height: 480)
        .background(CMTheme.base(scheme))
        .onAppear { draft = prefs.targetCompanies }
    }
}
