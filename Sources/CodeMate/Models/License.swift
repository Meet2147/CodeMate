import Foundation
import CryptoKit

/// A signed, offline-verifiable license for direct (outside the Mac App
/// Store) sales. StoreKit's Product/Transaction APIs only work for App
/// Store-distributed builds -- there's no receipt to validate otherwise --
/// so a direct download needs its own entitlement mechanism. This is the
/// standard shape indie Mac apps use: a payment processor (Stripe/Paddle/
/// Gumroad, plugged in separately -- not built here) collects payment and
/// hands the buyer a key; the app verifies the key's signature locally,
/// no server or network call needed.
struct License: Codable, Equatable {
    var tier: SubscriptionTier
    var expiresAt: Date?   // nil = lifetime / no expiry
    var issuedTo: String?  // buyer email or name, shown in Settings as a receipt

    var isExpired: Bool {
        guard let expiresAt else { return false }
        return expiresAt < .now
    }

    private enum CodingKeys: String, CodingKey { case tier, expiresAt, issuedTo }
}

/// Encodes/decodes/signs license keys as `<payload>.<signature>`, both
/// base64url, verified with HMAC-SHA256 against an embedded shared secret.
///
/// This protects against casual tampering (editing a key to say "max"
/// instead of "pro"), not against a determined reverse-engineer who
/// extracts the secret from the binary -- no offline license scheme can
/// fully prevent that. That's an accepted, common trade-off for indie
/// Mac software sold outside the App Store; it isn't trying to be DRM.
enum LicenseCodec {
    /// Replace with your own secret before shipping -- anyone with this
    /// string (and the algorithm here, which is public in this repo) can
    /// mint valid-looking keys. Keep it out of version control in a real
    /// release: inject at build time rather than committing a real value.
    private static let sharedSecret = "REPLACE_ME_WITH_A_PRIVATE_SIGNING_SECRET"

    // Must match Tools/generate_license.swift's encoder exactly (both the
    // date strategy and the shared secret above), since that script signs
    // keys completely offline against this same format.
    private static var encoder: JSONEncoder {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        return encoder
    }

    private static var decoder: JSONDecoder {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return decoder
    }

    static func encode(_ license: License) throws -> String {
        let payload = try encoder.encode(license)
        let payloadB64 = payload.base64URLEncodedString()
        let signature = sign(payloadB64)
        return "\(payloadB64).\(signature)"
    }

    static func decode(_ key: String) -> License? {
        let parts = key.trimmingCharacters(in: .whitespacesAndNewlines).split(separator: ".")
        guard parts.count == 2 else { return nil }
        let payloadB64 = String(parts[0])
        let signature = String(parts[1])
        guard sign(payloadB64) == signature else { return nil }
        guard let payloadData = Data(base64URLEncoded: payloadB64) else { return nil }
        return try? decoder.decode(License.self, from: payloadData)
    }

    private static func sign(_ payloadB64: String) -> String {
        let key = SymmetricKey(data: Data(sharedSecret.utf8))
        let mac = HMAC<SHA256>.authenticationCode(for: Data(payloadB64.utf8), using: key)
        return Data(mac).base64URLEncodedString()
    }
}

private extension Data {
    func base64URLEncodedString() -> String {
        base64EncodedString()
            .replacingOccurrences(of: "+", with: "-")
            .replacingOccurrences(of: "/", with: "_")
            .replacingOccurrences(of: "=", with: "")
    }

    init?(base64URLEncoded string: String) {
        var base64 = string
            .replacingOccurrences(of: "-", with: "+")
            .replacingOccurrences(of: "_", with: "/")
        while base64.count % 4 != 0 { base64.append("=") }
        self.init(base64Encoded: base64)
    }
}
