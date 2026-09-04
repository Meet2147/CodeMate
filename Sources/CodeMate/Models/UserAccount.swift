import Foundation

enum AuthProvider: String, Codable {
    case apple, google
}

struct UserAccount: Codable, Equatable {
    var id: String            // stable provider user id (Apple's `user` id, or Google's `sub`)
    var email: String?
    var displayName: String?
    var provider: AuthProvider
}

/// Emails that always get Max-tier access without a license/subscription --
/// for the developer to test paid features. Add teammates here too if
/// needed; this is a client-side allowlist (fine for "don't make me pay
/// myself to test my own app", not meant as a security boundary).
enum DeveloperAccess {
    static let allowlistedEmails: Set<String> = [
        "meetjethwa3@gmail.com"
    ]

    static func isDeveloper(email: String?) -> Bool {
        guard let email else { return false }
        return allowlistedEmails.contains(email.lowercased())
    }
}
