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

    var targetCompanies: Set<Company> {
        didSet { persistCompanies() }
    }

    var hasOnboarded: Bool {
        didSet { defaults.set(hasOnboarded, forKey: onboardedKey) }
    }

    init() {
        if let raw = defaults.string(forKey: companiesKey), !raw.isEmpty {
            targetCompanies = Set(raw.split(separator: ",").compactMap { Company(rawValue: String($0)) })
        } else {
            targetCompanies = []
        }
        hasOnboarded = defaults.bool(forKey: onboardedKey)
    }

    private func persistCompanies() {
        defaults.set(targetCompanies.map(\.rawValue).joined(separator: ","), forKey: companiesKey)
    }

    /// Resets onboarding so the picker shows again next launch (or immediately, if the caller re-renders RootView).
    func resetOnboarding() {
        hasOnboarded = false
    }
}
