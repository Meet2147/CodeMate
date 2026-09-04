import SwiftUI

/// Direct-sale paywall: CodeMate isn't distributed through the Mac App
/// Store, so this can't use StoreKit's in-app purchase() -- there's no App
/// Store receipt to validate outside that sandbox. Instead it opens a
/// hosted checkout link (Stripe/Paddle/Gumroad -- wire up the real URLs
/// below) and lets the buyer redeem the license key they're emailed after
/// paying. See LicenseCodec/Tools/generate_license.swift for how keys are
/// minted.
struct PaywallView: View {
    @Environment(\.colorScheme) private var scheme
    @Environment(\.dismiss) private var dismiss
    @Environment(LicenseManager.self) private var licenseManager
    @Environment(\.openURL) private var openURL
    @State private var billing: SubscriptionPlan.BillingPeriod = .monthly
    @State private var licenseKeyDraft: String = ""
    @State private var redeemedConfirmation = false
    @State private var isRedeeming = false

    var body: some View {
        VStack(spacing: 0) {
            header
            ScrollView {
                VStack(spacing: 22) {
                    billingToggle
                    HStack(alignment: .top, spacing: 18) {
                        tierCard(.free)
                        tierCard(.pro)
                        tierCard(.max)
                    }
                    .padding(.horizontal, 4)

                    redeemSection
                }
                .padding(24)
            }
        }
        .frame(width: 860, height: 760)
        .background(CMTheme.base(scheme))
        .onAppear { licenseKeyDraft = "" }
    }

    private var header: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text("Upgrade CodeMate")
                    .font(.system(size: 18, weight: .bold, design: .rounded))
                    .foregroundStyle(CMTheme.textPrimary(scheme))
                Text("You're currently on \(licenseManager.currentTier.displayName).")
                    .font(.system(size: 11))
                    .foregroundStyle(CMTheme.textSecondary(scheme))
            }
            Spacer()
            Button("Close") { dismiss() }
                .buttonStyle(NeumorphicButtonStyle())
        }
        .padding(20)
    }

    private var billingToggle: some View {
        Picker("Billing", selection: $billing) {
            Text("Monthly").tag(SubscriptionPlan.BillingPeriod.monthly)
            Text("Yearly — save ~33%").tag(SubscriptionPlan.BillingPeriod.yearly)
        }
        .pickerStyle(.segmented)
        .frame(width: 320)
    }

    @ViewBuilder
    private func tierCard(_ tier: SubscriptionTier) -> some View {
        let plan = SubscriptionCatalog.plan(tier: tier, billing: billing)
        let isCurrent = licenseManager.currentTier == tier
        let isPopular = tier == .pro

        VStack(spacing: 0) {
            // Little macOS-window chrome, like an IDE tab, to tie into the app's own look.
            HStack(spacing: 6) {
                Circle().fill(Color.red.opacity(0.7)).frame(width: 8, height: 8)
                Circle().fill(Color.yellow.opacity(0.7)).frame(width: 8, height: 8)
                Circle().fill(Color.green.opacity(0.7)).frame(width: 8, height: 8)
                Spacer()
                if isPopular {
                    Text("POPULAR")
                        .font(.system(size: 8, weight: .bold))
                        .padding(.horizontal, 6).padding(.vertical, 2)
                        .background(Capsule().fill(CMTheme.accent))
                        .foregroundStyle(.white)
                }
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 8)
            .background(CMTheme.shadowDark(scheme).opacity(0.15))

            VStack(spacing: 14) {
                VStack(spacing: 4) {
                    Text(tier.displayName)
                        .font(.system(size: 20, weight: .bold, design: .rounded))
                        .foregroundStyle(CMTheme.textPrimary(scheme))
                    Text(tier.tagline)
                        .font(.system(size: 11))
                        .foregroundStyle(CMTheme.textSecondary(scheme))
                        .multilineTextAlignment(.center)
                    Text(tier.subtitle)
                        .font(.system(size: 9))
                        .foregroundStyle(CMTheme.textSecondary(scheme).opacity(0.7))
                }

                VStack(spacing: 2) {
                    Text(tier == .free ? "$0" : (plan?.placeholderPrice ?? "—"))
                        .font(.system(size: 30, weight: .bold, design: .rounded))
                        .foregroundStyle(CMTheme.textPrimary(scheme))
                    Text(priceCaption(tier: tier, plan: plan))
                        .font(.system(size: 10))
                        .foregroundStyle(CMTheme.textSecondary(scheme))
                }
                .frame(height: 56)

                actionButton(tier: tier, plan: plan, isCurrent: isCurrent)

                Divider()

                VStack(alignment: .leading, spacing: 8) {
                    Text("includes")
                        .font(.system(size: 9, weight: .bold))
                        .foregroundStyle(CMTheme.textSecondary(scheme))
                    ForEach(tier.features, id: \.self) { feature in
                        HStack(alignment: .top, spacing: 6) {
                            Image(systemName: "checkmark.circle.fill")
                                .font(.system(size: 10))
                                .foregroundStyle(CMTheme.success)
                            Text(feature)
                                .font(.system(size: 11))
                                .foregroundStyle(CMTheme.textPrimary(scheme))
                        }
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .padding(18)
        }
        .background(
            RoundedRectangle(cornerRadius: CMTheme.cornerRadius, style: .continuous)
                .fill(CMTheme.base(scheme))
                .shadow(color: CMTheme.shadowDark(scheme), radius: isPopular ? 10 : 6, x: 4, y: 4)
                .shadow(color: CMTheme.shadowLight(scheme), radius: isPopular ? 10 : 6, x: -4, y: -4)
        )
        .overlay(
            RoundedRectangle(cornerRadius: CMTheme.cornerRadius, style: .continuous)
                .stroke(isPopular ? CMTheme.accent : CMTheme.hairline(scheme), lineWidth: isPopular ? 2 : 1)
        )
        .frame(maxWidth: .infinity)
    }

    private func priceCaption(tier: SubscriptionTier, plan: SubscriptionPlan?) -> String {
        switch tier {
        case .free: return "free forever, no card needed"
        case .pro, .max: return plan?.billing.rawValue ?? ""
        }
    }

    @ViewBuilder
    private func actionButton(tier: SubscriptionTier, plan: SubscriptionPlan?, isCurrent: Bool) -> some View {
        if isCurrent {
            Text("Current Plan")
                .frame(maxWidth: .infinity)
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(CMTheme.textSecondary(scheme))
                .padding(.vertical, 10)
                .background(RoundedRectangle(cornerRadius: CMTheme.smallCornerRadius).fill(CMTheme.shadowDark(scheme).opacity(0.15)))
        } else if tier == .free {
            Text("Downgrade anytime by letting a paid license lapse")
                .frame(maxWidth: .infinity)
                .font(.system(size: 10.5, weight: .medium))
                .foregroundStyle(CMTheme.textSecondary(scheme))
                .multilineTextAlignment(.center)
                .padding(.vertical, 10)
        } else {
            Button {
                if let url = plan?.purchaseURL { openURL(url) }
            } label: {
                Text("buy \(tier.displayName)").frame(maxWidth: .infinity)
            }
            .buttonStyle(NeumorphicButtonStyle(tint: tier == .max ? CMTheme.accent : CMTheme.success, prominent: true))
        }
    }

    private var redeemSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("HAVE A LICENSE KEY?")
                .font(.system(size: 10, weight: .bold))
                .foregroundStyle(CMTheme.textSecondary(scheme))
            Text("After buying above, you'll get a license key by email -- paste it here to unlock instantly.")
                .font(.system(size: 11))
                .foregroundStyle(CMTheme.textSecondary(scheme))

            HStack(spacing: 10) {
                TextField("Paste your license key", text: $licenseKeyDraft)
                    .textFieldStyle(.plain)
                    .font(.system(size: 12, design: .monospaced))
                    .neumorphicInset(padding: 10)
                Button {
                    isRedeeming = true
                    Task {
                        let ok = await licenseManager.redeem(key: licenseKeyDraft)
                        isRedeeming = false
                        if ok {
                            redeemedConfirmation = true
                            licenseKeyDraft = ""
                            DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) { redeemedConfirmation = false }
                        }
                    }
                } label: {
                    if isRedeeming { ProgressView().controlSize(.small) } else { Text("Redeem") }
                }
                .buttonStyle(NeumorphicButtonStyle(prominent: true))
                .disabled(licenseKeyDraft.trimmingCharacters(in: .whitespaces).isEmpty || isRedeeming)
            }

            if redeemedConfirmation {
                Label("License applied -- you're on \(licenseManager.currentTier.displayName) now.", systemImage: "checkmark.circle.fill")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(CMTheme.success)
            } else if let error = licenseManager.lastError {
                Text(error)
                    .font(.system(size: 11))
                    .foregroundStyle(CMTheme.danger)
            }

            if let license = licenseManager.license {
                HStack(spacing: 6) {
                    Image(systemName: "checkmark.seal.fill").foregroundStyle(CMTheme.success)
                    Text("Active: \(license.tier.displayName)" + (license.expiresAt.map { " · renews \($0.formatted(date: .abbreviated, time: .omitted))" } ?? " · lifetime"))
                        .font(.system(size: 11))
                        .foregroundStyle(CMTheme.textSecondary(scheme))
                    Spacer()
                    Button("Remove") { licenseManager.removeLicense() }
                        .buttonStyle(.plain)
                        .font(.system(size: 10, weight: .semibold))
                        .foregroundStyle(CMTheme.danger)
                }
                .padding(.top, 4)
            }
        }
        .neumorphicRaised(padding: 16)
    }
}
