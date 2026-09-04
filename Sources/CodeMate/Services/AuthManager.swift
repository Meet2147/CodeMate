import Foundation
import AuthenticationServices
import CryptoKit
import Observation
import AppKit

/// Sign in with Apple (native) and Sign in with Google (OAuth 2.0 + PKCE via
/// ASWebAuthenticationSession -- there's no first-party Google SDK for
/// native, non-Catalyst macOS apps, so this talks to Google's OAuth
/// endpoints directly, which is the standard approach for desktop apps).
///
/// SETUP NEEDED BEFORE THIS WORKS:
/// - Apple: enable "Sign In with Apple" capability for this app's bundle ID
///   in your Apple Developer account, and add the corresponding entitlement
///   when code-signing (Xcode's Signing & Capabilities tab does this for
///   you if you build the archive there instead of via Scripts/build_app.sh).
/// - Google: create an OAuth 2.0 Client ID (type "iOS" or "Desktop app") in
///   Google Cloud Console, put it in `googleClientID` below, and register
///   the `codemate://oauth-callback` redirect URI there. Also add the
///   `codemate` URL scheme as a CFBundleURLTypes entry in Info.plist
///   (Scripts/build_app.sh already does this).
@Observable
final class AuthManager: NSObject {
    private let keychainKey = "com.codemate.app.user-account"

    private(set) var currentUser: UserAccount?
    var isSigningIn = false
    var lastError: String?

    var isSignedIn: Bool { currentUser != nil }

    // Fill in with your real OAuth client ID from Google Cloud Console.
    // "Desktop app" client types don't get a meaningfully secret secret
    // (Google still requires the parameter; see docs), so a placeholder
    // here is fine to commit -- unlike the Polar/license secrets elsewhere.
    private let googleClientID = "REPLACE_WITH_YOUR_GOOGLE_OAUTH_CLIENT_ID.apps.googleusercontent.com"
    private let googleRedirectURI = "codemate://oauth-callback"

    private var webAuthSession: ASWebAuthenticationSession?
    private var pkceVerifier: String?

    override init() {
        super.init()
        if let data = KeychainService.loadGenericString(key: keychainKey)?.data(using: .utf8) {
            currentUser = try? JSONDecoder().decode(UserAccount.self, from: data)
        }
    }

    func signOut() {
        currentUser = nil
        KeychainService.deleteGenericString(key: keychainKey)
    }

    #if DEBUG
    /// Debug-only escape hatch so local testing isn't blocked on Apple/
    /// Google sign-in actually being fully configured (see AuthGateView).
    /// Compiled out of release builds -- never reaches a shipped app.
    func debugSignInAsDeveloper() {
        persist(UserAccount(id: "debug-local", email: "meetjethwa3@gmail.com", displayName: "Meet (debug)", provider: .apple))
    }
    #endif

    private func persist(_ user: UserAccount) {
        currentUser = user
        if let data = try? JSONEncoder().encode(user), let string = String(data: data, encoding: .utf8) {
            KeychainService.saveGenericString(string, key: keychainKey)
        }
    }

    // MARK: - Sign in with Apple

    /// Called from `SignInWithAppleButton`'s own `onCompletion` in
    /// AuthGateView -- the button owns its ASAuthorizationController
    /// internally, so AuthManager just processes the result rather than
    /// running a second, redundant authorization flow.
    func handleAppleSignIn(_ result: Result<ASAuthorization, Error>) {
        lastError = nil
        switch result {
        case .success(let authorization):
            guard let credential = authorization.credential as? ASAuthorizationAppleIDCredential else { return }
            let email = credential.email
            let name = [credential.fullName?.givenName, credential.fullName?.familyName].compactMap { $0 }.joined(separator: " ")
            // Apple only sends email/name on the FIRST authorization -- on a
            // returning sign-in, fall back to whatever we already stored.
            let resolvedEmail = email ?? currentUser?.email
            let resolvedName = name.isEmpty ? currentUser?.displayName : name
            persist(UserAccount(id: credential.user, email: resolvedEmail, displayName: resolvedName, provider: .apple))
        case .failure(let error):
            if let authError = error as? ASAuthorizationError, authError.code == .canceled { return }
            lastError = error.localizedDescription
        }
    }

    // MARK: - Sign in with Google (OAuth 2.0 + PKCE)

    func signInWithGoogle() {
        guard !googleClientID.hasPrefix("REPLACE_WITH") else {
            lastError = "Google sign-in isn't configured yet -- add a real OAuth client ID in AuthManager.swift."
            return
        }
        lastError = nil
        isSigningIn = true

        let verifier = Self.randomURLSafeString(length: 64)
        pkceVerifier = verifier
        let challenge = Self.codeChallenge(for: verifier)

        var components = URLComponents(string: "https://accounts.google.com/o/oauth2/v2/auth")!
        components.queryItems = [
            URLQueryItem(name: "client_id", value: googleClientID),
            URLQueryItem(name: "redirect_uri", value: googleRedirectURI),
            URLQueryItem(name: "response_type", value: "code"),
            URLQueryItem(name: "scope", value: "openid email profile"),
            URLQueryItem(name: "code_challenge", value: challenge),
            URLQueryItem(name: "code_challenge_method", value: "S256")
        ]

        guard let authURL = components.url,
              let scheme = URL(string: googleRedirectURI)?.scheme else {
            isSigningIn = false
            lastError = "Couldn't build the Google sign-in URL."
            return
        }

        let session = ASWebAuthenticationSession(url: authURL, callbackURLScheme: scheme) { [weak self] callbackURL, error in
            guard let self else { return }
            if let error {
                self.isSigningIn = false
                if (error as? ASWebAuthenticationSessionError)?.code != .canceledLogin {
                    self.lastError = error.localizedDescription
                }
                return
            }
            guard let callbackURL,
                  let code = URLComponents(url: callbackURL, resolvingAgainstBaseURL: false)?
                    .queryItems?.first(where: { $0.name == "code" })?.value else {
                self.isSigningIn = false
                self.lastError = "Google sign-in didn't return an authorization code."
                return
            }
            Task { await self.exchangeGoogleCode(code) }
        }
        session.presentationContextProvider = self
        session.prefersEphemeralWebBrowserSession = true
        webAuthSession = session
        session.start()
    }

    private func exchangeGoogleCode(_ code: String) async {
        guard let verifier = pkceVerifier else { return }
        var request = URLRequest(url: URL(string: "https://oauth2.googleapis.com/token")!)
        request.httpMethod = "POST"
        request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
        let params = [
            "client_id": googleClientID,
            "code": code,
            "code_verifier": verifier,
            "grant_type": "authorization_code",
            "redirect_uri": googleRedirectURI
        ]
        request.httpBody = params.map { "\($0.key)=\($0.value)" }.joined(separator: "&").data(using: .utf8)

        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            guard let http = response as? HTTPURLResponse, (200..<300).contains(http.statusCode) else {
                await MainActor.run { self.isSigningIn = false; self.lastError = "Google token exchange failed." }
                return
            }
            struct TokenResponse: Decodable { let access_token: String }
            let token = try JSONDecoder().decode(TokenResponse.self, from: data)
            try await fetchGoogleProfile(accessToken: token.access_token)
        } catch {
            await MainActor.run { self.isSigningIn = false; self.lastError = error.localizedDescription }
        }
    }

    private func fetchGoogleProfile(accessToken: String) async throws {
        var request = URLRequest(url: URL(string: "https://www.googleapis.com/oauth2/v3/userinfo")!)
        request.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
        let (data, _) = try await URLSession.shared.data(for: request)
        struct Profile: Decodable { let sub: String; let email: String?; let name: String? }
        let profile = try JSONDecoder().decode(Profile.self, from: data)
        await MainActor.run {
            self.persist(UserAccount(id: profile.sub, email: profile.email, displayName: profile.name, provider: .google))
            self.isSigningIn = false
        }
    }

    private static func randomURLSafeString(length: Int) -> String {
        var bytes = [UInt8](repeating: 0, count: length)
        _ = SecRandomCopyBytes(kSecRandomDefault, length, &bytes)
        return Data(bytes).base64EncodedString()
            .replacingOccurrences(of: "+", with: "-")
            .replacingOccurrences(of: "/", with: "_")
            .replacingOccurrences(of: "=", with: "")
    }

    private static func codeChallenge(for verifier: String) -> String {
        let hash = SHA256.hash(data: Data(verifier.utf8))
        return Data(hash).base64EncodedString()
            .replacingOccurrences(of: "+", with: "-")
            .replacingOccurrences(of: "/", with: "_")
            .replacingOccurrences(of: "=", with: "")
    }
}

extension AuthManager: ASWebAuthenticationPresentationContextProviding {
    func presentationAnchor(for session: ASWebAuthenticationSession) -> ASPresentationAnchor {
        NSApplication.shared.keyWindow ?? NSApplication.shared.windows.first ?? ASPresentationAnchor()
    }
}
