import Foundation
import Security

/// Minimal Keychain wrapper. Used for the user's own Anthropic API key
/// (CodeMate never ships with an embedded key and never sends it anywhere
/// except https://api.anthropic.com) and for the direct-sale license key.
enum KeychainService {
    private static let apiKeyService = "com.codemate.app.anthropic-api-key"

    static func save(apiKey: String) {
        saveGenericString(apiKey, key: apiKeyService)
    }

    static func loadAPIKey() -> String? {
        loadGenericString(key: apiKeyService)
    }

    static func clear() {
        deleteGenericString(key: apiKeyService)
    }

    // MARK: - Generic string storage (also used by LicenseManager)

    static func saveGenericString(_ value: String, key: String) {
        let data = Data(value.utf8)
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: key
        ]
        SecItemDelete(query as CFDictionary)

        var attributes = query
        attributes[kSecValueData as String] = data
        SecItemAdd(attributes as CFDictionary, nil)
    }

    static func loadGenericString(key: String) -> String? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: key,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]
        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)
        guard status == errSecSuccess, let data = result as? Data else { return nil }
        return String(data: data, encoding: .utf8)
    }

    static func deleteGenericString(key: String) {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: key
        ]
        SecItemDelete(query as CFDictionary)
    }
}
