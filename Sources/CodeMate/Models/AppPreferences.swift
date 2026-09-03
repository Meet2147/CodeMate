import Foundation
import Observation

/// App-wide, persisted user preferences -- currently just which companies
/// the student is targeting. Backed by UserDefaults, exposed as an
/// @Observable so onboarding, Settings, and the practice/design lists all
/// stay in sync without prop-drilling a closure everywhere.
@Observable
final class AppPreferences {
    private let defaults = UserDefaults.standard
    private let companiesKey = "cm.targetCompanies"
    private let onboardedKey = "cm.hasOnboarded"
    private let callsUsedKey = "cm.practiceCallsUsedThisMonth"
    private let callsMonthKey = "cm.practiceCallsMonthKey"

    var targetCompanies: Set<Company> {
        didSet { persistCompanies() }
    }

    var hasOnboarded: Bool {
        didSet { defaults.set(hasOnboarded, forKey: onboardedKey) }
    }

    /// Practice-call usage resets automatically at the start of each
    /// calendar month (client-side only -- fine for a soft usage nudge,
    /// not meant as tamper-proof metering).
    private(set) var practiceCallsUsedThisMonth: Int = 0

    init() {
        if let raw = defaults.string(forKey: companiesKey), !raw.isEmpty {
            targetCompanies = Set(raw.split(separator: ",").compactMap { Company(rawValue: String($0)) })
        } else {
            targetCompanies = []
        }
        hasOnboarded = defaults.bool(forKey: onboardedKey)

        let currentMonthKey = Self.monthKey(for: .now)
        if defaults.string(forKey: callsMonthKey) == currentMonthKey {
            practiceCallsUsedThisMonth = defaults.integer(forKey: callsUsedKey)
        } else {
            defaults.set(currentMonthKey, forKey: callsMonthKey)
            defaults.set(0, forKey: callsUsedKey)
        }
    }

    private func persistCompanies() {
        defaults.set(targetCompanies.map(\.rawValue).joined(separator: ","), forKey: companiesKey)
    }

    /// Resets onboarding so the picker shows again next launch (or immediately, if the caller re-renders RootView).
    func resetOnboarding() {
        hasOnboarded = false
    }

    func canStartPracticeCall(tier: SubscriptionTier) -> Bool {
        guard let limit = tier.practiceCallsPerMonth else { return true }
        return practiceCallsUsedThisMonth < limit
    }

    func recordPracticeCallStarted() {
        practiceCallsUsedThisMonth += 1
        defaults.set(practiceCallsUsedThisMonth, forKey: callsUsedKey)
    }

    private static func monthKey(for date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM"
        return formatter.string(from: date)
    }
}
