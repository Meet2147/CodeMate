import Foundation
import Observation

/// Entitlement source for a direct (non-App-Store) build: holds the
/// redeemed license, if any, and exposes the resulting tier. This is what
/// Practice/LLD-HLD/Settings gate against for a direct download. (StoreManager
/// stays in the project, dormant, for a possible future Mac App Store SKU
/// sold alongside this -- the two are independent, a build only needs to
/// wire up the one matching how it's actually distributed.)
@Observable
final class LicenseManager {
    private let keychainKey = "com.codemate.app.license-key"

    private(set) var license: License?
    var lastError: String?

    var currentTier: SubscriptionTier {
        guard let license, !license.isExpired else { return .free }
        return license.tier
    }

    init() {
        if let stored = KeychainService.loadGenericString(key: keychainKey) {
            license = LicenseCodec.decode(stored)
        }
    }

    @discardableResult
    func redeem(key: String) -> Bool {
        let trimmed = key.trimmingCharacters(in: .whitespacesAndNewlines)
        guard let decoded = LicenseCodec.decode(trimmed) else {
            lastError = "That license key isn't valid. Double-check it was copied in full."
            return false
        }
        if decoded.isExpired {
            lastError = "This license expired\(decoded.expiresAt.map { " on " + $0.formatted(date: .abbreviated, time: .omitted) } ?? ""). Renew to keep \(decoded.tier.displayName) features."
        } else {
            lastError = nil
        }
        license = decoded
        KeychainService.saveGenericString(trimmed, key: keychainKey)
        return true
    }

    func removeLicense() {
        license = nil
        KeychainService.deleteGenericString(key: keychainKey)
    }
}
