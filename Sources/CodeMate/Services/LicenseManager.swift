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

    /// Tries Polar first (the real path now that Polar's org ID is
    /// configured), falling back to the offline HMAC format for local
    /// testing/demo keys minted by Tools/generate_license.swift.
    ///
    /// Falls through to the offline format on ANY Polar failure, not just
    /// `.notConfigured` -- an offline-minted key isn't valid input to
    /// Polar's API at all (it's not their key format), so Polar will
    /// reject it outright (404/422, surfaced as `.network`), not report it
    /// as "not valid". Treating that as fatal would make offline dev/test
    /// keys stop working the moment Polar gets wired up, which is exactly
    /// what happened here once `organizationId` was filled in.
    @discardableResult
    func redeem(key: String) async -> Bool {
        let trimmed = key.trimmingCharacters(in: .whitespacesAndNewlines)
        lastError = nil
        var polarNetworkIssue = false

        do {
            let result = try await PolarService.validate(key: trimmed)
            if result.isValid, let tier = result.tier {
                let license = License(tier: tier, expiresAt: result.expiresAt, issuedTo: accountEmail)
                self.license = license
                KeychainService.saveGenericString(trimmed, key: keychainKey)
                return true
            }
            // Polar recognized the key and says it's not valid (revoked/
            // disabled) -- still worth trying the offline format below,
            // since that's a different signal than "not a Polar key at all".
        } catch PolarService.PolarError.notConfigured {
            // Polar isn't wired up -- offline format is the only path.
        } catch {
            // Either this isn't a Polar-issued key at all, or a genuine
            // network hiccup -- try the offline format before giving up.
            polarNetworkIssue = true
        }

        guard let decoded = LicenseCodec.decode(trimmed) else {
            lastError = polarNetworkIssue
                ? "Couldn't verify this key -- check your connection, or double-check it was copied in full."
                : "That license key isn't valid. Double-check it was copied in full."
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
