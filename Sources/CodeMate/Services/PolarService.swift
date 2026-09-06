import Foundation

/// Client for Polar's (polar.sh) customer-facing license key validation.
/// Polar is the subscription/payment processor for this app's direct sales
/// (Stripe under the hood, handles tax/VAT as merchant of record). Their
/// License Keys feature issues a key to the customer at checkout;
/// validating a key a customer already holds is safe to call directly from
/// the app (unlike querying subscriptions by email, which needs a secret
/// organization API token and must go through your own backend instead --
/// never embed that secret client-side).
///
/// Endpoint, request, and response shape below were confirmed directly
/// against Polar's live OpenAPI spec (https://polar.sh/docs/openapi.json,
/// schemas `LicenseKeyValidate` / `ValidatedLicenseKey`) on 2026-09-04 --
/// the response does NOT include a product/tier name, only a `benefit_id`
/// (a UUID), so tier is resolved via `benefitTierMap` below rather than by
/// guessing at any text field. Re-check that spec if this stops matching,
/// their API surface evolves.
enum PolarService {
    /// From your Polar dashboard (Settings -> General). Not secret.
    static let organizationId = "36a24ca3-4af7-4c52-8fac-7243fb07019a"

    /// Maps each License Keys *benefit* (not product) to the tier it
    /// unlocks. Set this up as: one "Pro Access" benefit attached to both
    /// the pro-monthly and pro-yearly products, one "Max Access" benefit
    /// attached to both max-monthly and max-yearly products -- that way
    /// there are only two benefit IDs to map here regardless of billing
    /// period. Find each ID on the benefit's page in the Polar dashboard
    /// (Benefits -> the benefit -> its ID is in the URL/detail panel).
    static let benefitTierMap: [String: SubscriptionTier] = [
        "67ed3eb8-b533-47b9-ac17-3e8d161e71df": .pro,
        "0ea423b3-4e79-447f-9bbb-8a8ae678baa7": .max,
    ]

    struct ValidationResult {
        var isValid: Bool
        var tier: SubscriptionTier?
        var expiresAt: Date?
    }

    enum PolarError: LocalizedError {
        case notConfigured
        case network(String)
        var errorDescription: String? {
            switch self {
            case .notConfigured: return "Polar isn't configured yet."
            case .network(let message): return message
            }
        }
    }

    static func validate(key: String) async throws -> ValidationResult {
        guard !organizationId.hasPrefix("REPLACE_WITH") else {
            throw PolarError.notConfigured
        }

        var request = URLRequest(url: URL(string: "https://api.polar.sh/v1/customer-portal/license-keys/validate")!)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONSerialization.data(withJSONObject: [
            "key": key,
            "organization_id": organizationId
        ])

        let (data, response) = try await URLSession.shared.data(for: request)
        guard let http = response as? HTTPURLResponse else {
            throw PolarError.network("No response from Polar.")
        }
        guard (200..<300).contains(http.statusCode) else {
            throw PolarError.network("Polar rejected this key (HTTP \(http.statusCode)).")
        }

        // Matches ValidatedLicenseKey from Polar's OpenAPI spec.
        struct Response: Decodable {
            let status: String       // "granted" | "revoked" | "disabled"
            let benefit_id: String
            let expires_at: Date?
        }
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        guard let decoded = try? decoder.decode(Response.self, from: data) else {
            throw PolarError.network("Couldn't read Polar's response.")
        }
        guard decoded.status == "granted" else {
            return ValidationResult(isValid: false, tier: nil, expiresAt: nil)
        }
        guard let tier = benefitTierMap[decoded.benefit_id] else {
            throw PolarError.network("This key is valid but isn't for a CodeMate product benefit (unrecognized benefit_id \(decoded.benefit_id)). Check benefitTierMap in PolarService.swift.")
        }

        return ValidationResult(isValid: true, tier: tier, expiresAt: decoded.expires_at)
    }
}
