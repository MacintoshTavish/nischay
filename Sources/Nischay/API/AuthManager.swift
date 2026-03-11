import AppKit
import Foundation

/// Handles user auth – OAuth PKCE flow via Supabase Auth.
/// Mirrors signInWithProvider / getCurrentSession / isAuthenticated from the RE analysis.
/// The OAuth callback arrives via the nischay:// URL scheme handled in AppDelegate.
class AuthManager: @unchecked Sendable {
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
        // Use implicit flow so tokens come directly in URL fragment (no code exchange needed)
        let urlStr = "\(supabaseURL)/auth/v1/authorize?provider=github&redirect_to=nischay://auth/callback"
        guard let url = URL(string: urlStr) else { return }
        NSWorkspace.shared.open(url)
    }

    // MARK: - OAuth Callback

    private func debugLog(_ msg: String) {
        let path = NSHomeDirectory() + "/Desktop/nischay_auth_debug.txt"
        let line = "\(Date()): \(msg)\n"
        if let handle = FileHandle(forWritingAtPath: path) {
            handle.seekToEndOfFile()
            handle.write(line.data(using: .utf8)!)
            handle.closeFile()
        } else {
            try? line.write(toFile: path, atomically: true, encoding: .utf8)
        }
        print("Nischay Auth: \(msg)")
    }

    func handleCallback(url: URL) {
        debugLog("Received callback URL: \(url.absoluteString)")
        debugLog("URL scheme: \(url.scheme ?? "nil")")
        debugLog("URL host: \(url.host ?? "nil")")
        debugLog("URL path: \(url.path)")
        debugLog("URL query: \(url.query ?? "nil")")
        debugLog("URL fragment: \(url.fragment ?? "nil")")

        // Try 1: Check for authorization code in query params (Supabase PKCE / code flow)
        let components = URLComponents(url: url, resolvingAgainstBaseURL: false)
        if let code = components?.queryItems?.first(where: { $0.name == "code" })?.value {
            debugLog("Got authorization code: \(code.prefix(10))...")
            exchangeCodeForToken(code: code)
            return
        }

        // Try 2: Check for access_token in URL fragment (implicit flow)
        let fragment = url.fragment ?? ""
        debugLog("Fragment raw: \(fragment.prefix(100))")
        var params: [String: String] = [:]
        for pair in fragment.split(separator: "&") {
            let kv = pair.split(separator: "=", maxSplits: 1)
            if kv.count == 2 { params[String(kv[0])] = String(kv[1]) }
        }
        debugLog("Fragment params keys: \(params.keys.sorted())")

        if let token = params["access_token"] {
            debugLog("Got access_token from fragment: \(token.prefix(20))...")
            let session = UserSession(
                accessToken:  token,
                refreshToken: params["refresh_token"],
                userId:       nil,
                email:        nil
            )
            setSession(session)
            debugLog("Session saved successfully!")
        } else {
            debugLog("NO code or access_token found — auth failed")
        }
    }

    // MARK: - Code Exchange

    private func exchangeCodeForToken(code: String) {
        let supabaseURL = ConfigManager.shared.supabaseURL
        let anonKey = ConfigManager.shared.supabaseAnonKey
        guard let url = URL(string: "\(supabaseURL)/auth/v1/token?grant_type=authorization_code") else { return }

        var req = URLRequest(url: url)
        req.httpMethod = "POST"
        req.setValue("application/json", forHTTPHeaderField: "Content-Type")
        req.setValue(anonKey, forHTTPHeaderField: "apikey")
        req.setValue("Bearer \(anonKey)", forHTTPHeaderField: "Authorization")

        let body: [String: String] = [
            "code": code
        ]
        req.httpBody = try? JSONSerialization.data(withJSONObject: body)

        URLSession.shared.dataTask(with: req) { [weak self] data, response, error in
            if let error = error {
                print("Nischay Auth: Token exchange failed – \(error)")
                return
            }
            guard let data = data,
                  let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else {
                print("Nischay Auth: Token exchange – invalid response")
                return
            }

            print("Nischay Auth: Token exchange response keys: \(json.keys)")

            if let accessToken = json["access_token"] as? String {
                let session = UserSession(
                    accessToken:  accessToken,
                    refreshToken: json["refresh_token"] as? String,
                    userId:       (json["user"] as? [String: Any])?["id"] as? String,
                    email:        nil
                )
                DispatchQueue.main.async { self?.setSession(session) }
                print("Nischay Auth: Successfully authenticated!")
            } else if let errorMsg = json["error_description"] as? String ?? json["msg"] as? String {
                print("Nischay Auth: Token exchange error – \(errorMsg)")
            }
        }.resume()
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
