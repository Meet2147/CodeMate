import SwiftUI
import StoreKit

struct PaywallView: View {
    @Environment(\.colorScheme) private var scheme
    @Environment(\.dismiss) private var dismiss
    @Environment(StoreManager.self) private var store
    @State private var billing: SubscriptionPlan.BillingPeriod = .monthly
    @State private var purchasingProductID: String?

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

                    if let lastError = store.lastError {
                        Text(lastError)
                            .font(.system(size: 11))
                            .foregroundStyle(CMTheme.danger)
                    }

                    Button("Restore Purchases") { Task { await store.restorePurchases() } }
                        .buttonStyle(.plain)
                        .font(.system(size: 11))
                        .foregroundStyle(CMTheme.textSecondary(scheme))
                        .padding(.bottom, 8)
                }
                .padding(24)
            }
        }
        .frame(width: 860, height: 700)
        .background(CMTheme.base(scheme))
    }

    private var header: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text("Upgrade CodeMate")
                    .font(.system(size: 18, weight: .bold, design: .rounded))
                    .foregroundStyle(CMTheme.textPrimary(scheme))
                Text("You're currently on \(store.currentTier.displayName).")
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
        let product = plan.flatMap { store.product(for: $0) }
        let isCurrent = store.currentTier == tier
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
                    Text(priceText(tier: tier, product: product, plan: plan))
                        .font(.system(size: 30, weight: .bold, design: .rounded))
                        .foregroundStyle(CMTheme.textPrimary(scheme))
                    Text(priceCaption(tier: tier, plan: plan))
                        .font(.system(size: 10))
                        .foregroundStyle(CMTheme.textSecondary(scheme))
                }
                .frame(height: 56)

                actionButton(tier: tier, product: product, isCurrent: isCurrent)

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

    private func priceText(tier: SubscriptionTier, product: Product?, plan: SubscriptionPlan?) -> String {
        if tier == .free { return "$0" }
        if let product { return product.displayPrice }
        return plan?.placeholderPrice ?? "—"
    }

    private func priceCaption(tier: SubscriptionTier, plan: SubscriptionPlan?) -> String {
        switch tier {
        case .free: return "free forever, no card needed"
        case .pro, .max: return plan?.billing.rawValue ?? ""
        }
    }

    @ViewBuilder
    private func actionButton(tier: SubscriptionTier, product: Product?, isCurrent: Bool) -> some View {
        if isCurrent {
            Text("Current Plan")
                .frame(maxWidth: .infinity)
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(CMTheme.textSecondary(scheme))
                .padding(.vertical, 10)
                .background(RoundedRectangle(cornerRadius: CMTheme.smallCornerRadius).fill(CMTheme.shadowDark(scheme).opacity(0.15)))
        } else if tier == .free {
            Text("Manage your plan in System Settings")
                .frame(maxWidth: .infinity)
                .font(.system(size: 10.5, weight: .medium))
                .foregroundStyle(CMTheme.textSecondary(scheme))
                .multilineTextAlignment(.center)
                .padding(.vertical, 10)
        } else {
            Button {
                guard let product else { return }
                purchasingProductID = product.id
                Task {
                    await store.purchase(product)
                    purchasingProductID = nil
                }
            } label: {
                if purchasingProductID == product?.id {
                    ProgressView().controlSize(.small).frame(maxWidth: .infinity)
                } else {
                    Text("get \(tier.displayName)").frame(maxWidth: .infinity)
                }
            }
            .buttonStyle(NeumorphicButtonStyle(tint: tier == .max ? CMTheme.accent : CMTheme.success, prominent: true))
            .disabled(product == nil || purchasingProductID != nil)
        }
    }
}
