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

    /// Set by AuthManager after sign-in (see CodeMateApp's wiring) so
    /// DeveloperAccess and any future per-account entitlement checks have
    /// the signed-in email without LicenseManager depending on AuthManager
    /// directly.
    var accountEmail: String?

    var currentTier: SubscriptionTier {
        if DeveloperAccess.isDeveloper(email: accountEmail) { return .max }
        guard let license, !license.isExpired else { return .free }
        return license.tier
    }

    init() {
        if let stored = KeychainService.loadGenericString(key: keychainKey) {
            license = LicenseCodec.decode(stored)
        }
    }

    /// Tries Polar first (the real path once Polar's org ID is configured),
    /// falling back to the offline HMAC format for local testing/demo keys
    /// minted by Tools/generate_license.swift.
    @discardableResult
    func redeem(key: String) async -> Bool {
        let trimmed = key.trimmingCharacters(in: .whitespacesAndNewlines)
        lastError = nil

        do {
            let result = try await PolarService.validate(key: trimmed)
            if result.isValid, let tier = result.tier {
                let license = License(tier: tier, expiresAt: result.expiresAt, issuedTo: accountEmail)
                self.license = license
                KeychainService.saveGenericString(trimmed, key: keychainKey)
                return true
            }
        } catch PolarService.PolarError.notConfigured {
            // Fall through to offline format -- Polar isn't wired up yet.
        } catch {
            lastError = error.localizedDescription
            return false
        }

        guard let decoded = LicenseCodec.decode(trimmed) else {
            lastError = "That license key isn't valid. Double-check it was copied in full."
            return false
        }
        if decoded.isExpired {
            lastError = "This license expired\(decoded.expiresAt.map { " on " + $0.formatted(date: .abbreviated, time: .omitted) } ?? ""). Renew to keep \(decoded.tier.displayName) features."
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
