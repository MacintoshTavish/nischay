import AppKit
import Foundation

/// Handles user auth – OAuth PKCE flow via Supabase Auth.
/// Mirrors signInWithProvider / getCurrentSession / isAuthenticated from the RE analysis.
/// The OAuth callback arrives via the nischay:// URL scheme handled in AppDelegate.
class AuthManager {
    static let shared = AuthManager()

    struct UserSession {
        let accessToken:  String
        let refreshToken: String?
        let userId:       String?
        let email:        String?
    }

    private(set) var isAuthenticated = false
    private(set) var currentSession: UserSession?

    private init() { loadSession() }

    // MARK: - Sign In (OAuth PKCE)

    func signIn() {
        let supabaseURL = ConfigManager.shared.supabaseURL
        guard !supabaseURL.isEmpty else {
            print("Nischay: Cannot sign in – Supabase URL not configured.")
            return
        }
        let urlStr = "\(supabaseURL)/auth/v1/authorize?provider=github&redirect_to=nischay://auth/callback"
        guard let url = URL(string: urlStr) else { return }
        NSWorkspace.shared.open(url)
    }

    // MARK: - OAuth Callback

    func handleCallback(url: URL) {
        // Extract token from URL fragment or query params
        // e.g. nischay://auth/callback#access_token=xxx&refresh_token=yyy
        let components = URLComponents(url: url, resolvingAgainstBaseURL: false)
        let fragment = url.fragment ?? ""
        var params: [String: String] = [:]

        for pair in fragment.split(separator: "&") {
            let kv = pair.split(separator: "=", maxSplits: 1)
            if kv.count == 2 { params[String(kv[0])] = String(kv[1]) }
        }

        if let token = params["access_token"] {
            let session = UserSession(
                accessToken:  token,
                refreshToken: params["refresh_token"],
                userId:       components?.queryItems?.first(where: { $0.name == "user_id" })?.value,
                email:        nil
            )
            setSession(session)
        }
    }

    // MARK: - Sign Out

    func signOut() {
        currentSession = nil
        isAuthenticated = false
        UserDefaults.standard.removeObject(forKey: "nischay_access_token")
        UserDefaults.standard.removeObject(forKey: "nischay_refresh_token")
        NotificationCenter.default.post(name: .nischayAuthStateChanged, object: nil)
    }

    // MARK: - Session persistence

    private func setSession(_ session: UserSession) {
        currentSession  = session
        isAuthenticated = true
        UserDefaults.standard.set(session.accessToken,  forKey: "nischay_access_token")
        UserDefaults.standard.set(session.refreshToken, forKey: "nischay_refresh_token")
        NotificationCenter.default.post(name: .nischayAuthStateChanged, object: nil)
    }

    private func loadSession() {
        if let token = UserDefaults.standard.string(forKey: "nischay_access_token") {
            currentSession  = UserSession(accessToken: token,
                                          refreshToken: UserDefaults.standard.string(forKey: "nischay_refresh_token"),
                                          userId: nil, email: nil)
            isAuthenticated = true
        }
    }
}
