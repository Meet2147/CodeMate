import Foundation

enum SubscriptionTier: String, CaseIterable, Identifiable, Comparable, Codable {
    case free, pro, max

    var id: String { rawValue }
    private var rank: Int {
        switch self { case .free: return 0; case .pro: return 1; case .max: return 2 }
    }
    static func < (lhs: SubscriptionTier, rhs: SubscriptionTier) -> Bool { lhs.rank < rhs.rank }

    var displayName: String { rawValue }

    var tagline: String {
        switch self {
        case .free: return "see what the fuss is about"
        case .pro: return "practice as much as you want"
        case .max: return "everything, unlimited, first"
        }
    }

    var subtitle: String {
        switch self {
        case .free: return "best for trying it out"
        case .pro: return "best for active interview prep"
        case .max: return "best for a full study group"
        }
    }

    /// nil = unlimited.
    var maxTargetCompanies: Int? {
        switch self {
        case .free: return 1
        case .pro, .max: return nil
        }
    }

    /// nil = unlimited.
    var practiceCallsPerMonth: Int? {
        switch self {
        case .free: return 1
        case .pro: return 10
        case .max: return nil
        }
    }

    var features: [String] {
        switch self {
        case .free:
            return [
                "1 target company's questions",
                "Unlimited on-device AI assistant",
                "1 practice video call / month",
                "Progress tracking"
            ]
        case .pro:
            return [
                "All 10 companies' questions",
                "Unlimited on-device AI assistant",
                "10 practice video calls / month",
                "Full LLD/HLD system-design library",
                "Progress tracking"
            ]
        case .max:
            return [
                "Everything in Pro",
                "Unlimited practice video calls",
                "Early access to new company packs",
                "Priority cloud assistant fallback",
                "Mock interview timer mode"
            ]
        }
    }
}

/// A monthly or yearly product for a paid tier.
struct SubscriptionPlan: Identifiable {
    var id: String { productID }
    var tier: SubscriptionTier
    var billing: BillingPeriod
    var productID: String
    /// Shown price. For a Mac App Store build (StoreManager wired up),
    /// prefer `Product.displayPrice` once products load; this is what's
    /// shown for direct sales, where there's no StoreKit product to ask.
    var placeholderPrice: String
    /// Hosted checkout link (Stripe/Paddle/Gumroad -- replace with your
    /// real payment-processor URL before shipping). Opens in the browser;
    /// the buyer redeems the emailed license key back in the app.
    var purchaseURL: URL?

    enum BillingPeriod: String {
        case monthly = "per month, billed monthly"
        case yearly = "per year, billed yearly"
    }
}

enum SubscriptionCatalog {
    static let proMonthly = SubscriptionPlan(tier: .pro, billing: .monthly, productID: "com.codemate.app.pro.monthly", placeholderPrice: "$9.99", purchaseURL: URL(string: "https://buy.codemate.app/pro-monthly"))
    static let proYearly = SubscriptionPlan(tier: .pro, billing: .yearly, productID: "com.codemate.app.pro.yearly", placeholderPrice: "$79.99", purchaseURL: URL(string: "https://buy.codemate.app/pro-yearly"))
    static let maxMonthly = SubscriptionPlan(tier: .max, billing: .monthly, productID: "com.codemate.app.max.monthly", placeholderPrice: "$19.99", purchaseURL: URL(string: "https://buy.codemate.app/max-monthly"))
    static let maxYearly = SubscriptionPlan(tier: .max, billing: .yearly, productID: "com.codemate.app.max.yearly", placeholderPrice: "$149.99", purchaseURL: URL(string: "https://buy.codemate.app/max-yearly"))

    static let allPlans = [proMonthly, proYearly, maxMonthly, maxYearly]
    static let allProductIDs = allPlans.map(\.productID)

    static func plan(tier: SubscriptionTier, billing: SubscriptionPlan.BillingPeriod) -> SubscriptionPlan? {
        allPlans.first { $0.tier == tier && $0.billing == billing }
    }
}
