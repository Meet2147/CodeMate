import Foundation
import CryptoKit

// Seller-side tool: mints a signed license key to email a customer after
// they pay (via whatever processor you hook up -- Stripe/Paddle/Gumroad --
// this script doesn't talk to any of them, it just signs a key).
//
// Usage:
//   swift Tools/generate_license.swift pro monthly customer@example.com
//   swift Tools/generate_license.swift max lifetime customer@example.com
//
// IMPORTANT: this duplicates the License/LicenseCodec types from the app
// target (Swift scripts can't easily import a local SPM module by path).
// If you change the format in Sources/CodeMate/Models/License.swift,
// mirror the change here, and keep `sharedSecret` identical in both.

let sharedSecret = "REPLACE_ME_WITH_A_PRIVATE_SIGNING_SECRET" // must match License.swift

struct License: Codable {
    var tier: String
    var expiresAt: Date?
    var issuedTo: String?
}

func base64URLEncode(_ data: Data) -> String {
    data.base64EncodedString()
        .replacingOccurrences(of: "+", with: "-")
        .replacingOccurrences(of: "/", with: "_")
        .replacingOccurrences(of: "=", with: "")
}

func sign(_ payloadB64: String) -> String {
    let key = SymmetricKey(data: Data(sharedSecret.utf8))
    let mac = HMAC<SHA256>.authenticationCode(for: Data(payloadB64.utf8), using: key)
    return base64URLEncode(Data(mac))
}

let args = CommandLine.arguments
guard args.count >= 3, ["pro", "max"].contains(args[1].lowercased()) else {
    print("Usage: swift Tools/generate_license.swift <pro|max> <monthly|yearly|lifetime> [buyerEmail]")
    exit(1)
}

let tier = args[1].lowercased()
let period = args[2].lowercased()
let issuedTo = args.count > 3 ? args[3] : nil

var expiresAt: Date?
switch period {
case "monthly": expiresAt = Calendar.current.date(byAdding: .month, value: 1, to: .now)
case "yearly": expiresAt = Calendar.current.date(byAdding: .year, value: 1, to: .now)
case "lifetime": expiresAt = nil
default:
    print("Unknown period '\(period)'. Use monthly, yearly, or lifetime.")
    exit(1)
}

let license = License(tier: tier, expiresAt: expiresAt, issuedTo: issuedTo)
let encoder = JSONEncoder()
encoder.dateEncodingStrategy = .iso8601
let payload = try! encoder.encode(license)
let payloadB64 = base64URLEncode(payload)
let signature = sign(payloadB64)
let key = "\(payloadB64).\(signature)"

print("License key (\(tier), \(period)\(issuedTo.map { ", for \($0)" } ?? "")):")
print(key)
