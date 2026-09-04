import Foundation

/// Client for Polar's (polar.sh) customer-facing license key validation.
/// Polar is the subscription/payment processor for this app's direct sales
/// (Stripe under the hood, handles tax/VAT as merchant of record). Their
/// License Keys feature issues a signed key to the customer at checkout;
/// validating a key a customer already holds is safe to call directly from
/// the app (unlike querying subscriptions by email, which needs a secret
/// organization API token and must go through your own backend instead --
/// never embed that secret client-side).
///
/// VERIFY BEFORE SHIPPING: this is written against Polar's documented
/// customer-portal license-key endpoints as of when this was built --
/// double-check the exact path/payload/response shape at
/// https://docs.polar.sh before relying on it, their API surface evolves.
enum PolarService {
    /// From your Polar dashboard (Settings -> General). Not secret.
    static let organizationId = "REPLACE_WITH_YOUR_POLAR_ORGANIZATION_ID"

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

        // Polar's response includes the benefit/product granted by the key.
        // Map your actual Polar product names to SubscriptionTier here --
        // adjust the matching below once your products are set up.
        struct Response: Decodable {
            let status: String?
            let benefit: Benefit?
            struct Benefit: Decodable { let description: String? }
        }
        let decoded = try? JSONDecoder().decode(Response.self, from: data)
        let description = (decoded?.benefit?.description ?? "").lowercased()
        let tier: SubscriptionTier = description.contains("max") ? .max : .pro

        return ValidationResult(isValid: true, tier: tier, expiresAt: nil)
    }
}
