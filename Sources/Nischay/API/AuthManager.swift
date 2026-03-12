import AppKit
import Foundation
import CryptoKit

/// Handles user auth – OAuth PKCE flow via Supabase Auth.
/// Mirrors signInWithProvider / getCurrentSession / isAuthenticated from the RE analysis.
/// The OAuth callback arrives via the nischay:// URL scheme handled in AppDelegate.
class AuthManager: @unchecked Sendable {
    static let shared = AuthManager()

    struct UserSession {
        let accessToken:  String
        let refreshToken: String?
        let expiresAt:    Date?
        let userId:       String?
        let email:        String?
    }

    var isAuthenticated: Bool {
        guard let session = currentSession else { return false }
        // If we don't have an expiry (legacy session), assume it's valid 
        // until an API call fails with 401.
        guard let expiry = session.expiresAt else { return true }
        return Date() < expiry.addingTimeInterval(-60)
    }
    private(set) var currentSession: UserSession?
    private var codeVerifier: String?
    private(set) var isSigningIn = false
    
    // Version trace to prove it's the new binary in logs
    let version = "2.0.2+friend-loop-fix-final"

    private init() { 
        loadSession()
        debugLog("AuthManager Initialized. Version: \(version). isAuthd: \(isAuthenticated)")
    }

    // MARK: - Sign In (OAuth PKCE)

    func signInWithSupabase(provider: String = "github") {
        guard !isSigningIn else { return }
        isSigningIn = true
        
        let supabaseURL = ConfigManager.shared.supabaseURL
        
        // 1. Generate PKCE Verifier
        let verifier = generateRandomString(length: 64)
        self.codeVerifier = verifier
        
        // 2. Generate PKCE Challenge
        let challenge = generateCodeChallenge(from: verifier)
        
        // 3. Construct Auth URL
        let redirectUri = "nischay://auth/callback"
        guard let encodedRedirect = redirectUri.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) else { return }
        
        // Use uppercase S256 for maximum compatibility
        let urlStr = "\(supabaseURL)/auth/v1/authorize?provider=\(provider)&redirect_to=\(encodedRedirect)&code_challenge_method=S256&code_challenge=\(challenge)"
        
        guard let url = URL(string: urlStr) else { return }
        debugLog("Initiating OAuth flow for \(provider) with redirect: \(redirectUri)")
        NSWorkspace.shared.open(url)
    }

    // MARK: - PKCE Helpers
    
    private func generateRandomString(length: Int) -> String {
        let characters = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789-._~"
        return String((0..<length).map { _ in characters.randomElement()! })
    }
    
    private func generateCodeChallenge(from verifier: String) -> String {
        guard let data = verifier.data(using: .utf8) else { return "" }
        let digest = SHA256.hash(data: data)
        return Data(digest).base64UrlEncodedString()
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
        
        let components = URLComponents(url: url, resolvingAgainstBaseURL: false)
        if let code = components?.queryItems?.first(where: { $0.name == "code" })?.value {
            debugLog("Got authorization code, exchanging...")
            exchangeCodeForToken(code: code)
            return
        }

        // Check for access_token in fragment (fallback)
        let fragment = url.fragment ?? ""
        var params: [String: String] = [:]
        for pair in fragment.split(separator: "&") {
            let kv = pair.split(separator: "=", maxSplits: 1)
            if kv.count == 2 { params[String(kv[0])] = String(kv[1]) }
        }

        if let token = params["access_token"] {
            let expiresIn = Double(params["expires_in"] ?? "3600") ?? 3600
            let expiresAt = Date().addingTimeInterval(expiresIn)
            let session = UserSession(
                accessToken:  token,
                refreshToken: params["refresh_token"],
                expiresAt:    expiresAt,
                userId:       nil,
                email:        nil
            )
            setSession(session)
        }
    }

    // MARK: - Code Exchange

    private func exchangeCodeForToken(code: String) {
        let supabaseURL = ConfigManager.shared.supabaseURL
        let anonKey = ConfigManager.shared.supabaseAnonKey
        
        // BREAKTHROUGH: Supabase/GoTrue expects grant_type=pkce in the URL query string
        guard let url = URL(string: "\(supabaseURL)/auth/v1/token?grant_type=pkce") else { return }
        
        guard let verifier = codeVerifier else {
            debugLog("ERROR: No code verifier found for exchange. Session state lost?")
            return
        }

        var req = URLRequest(url: url)
        req.httpMethod = "POST"
        
        req.setValue("application/json", forHTTPHeaderField: "Content-Type")
        req.setValue("application/json", forHTTPHeaderField: "Accept")
        req.setValue(anonKey, forHTTPHeaderField: "apikey")
        req.setValue("Bearer \(anonKey)", forHTTPHeaderField: "Authorization")

        // BREAKTHROUGH: The code field must be named "auth_code" for this flow
        let params: [String: Any] = [
            "auth_code": code,
            "code_verifier": verifier
        ]
        
        guard let jsonData = try? JSONSerialization.data(withJSONObject: params),
              let jsonString = String(data: jsonData, encoding: .utf8) else {
            debugLog("ERROR: Could not serialize token request JSON.")
            return
        }
        
        req.httpBody = jsonData
        
        debugLog("Applying Friend's GoTrue Breakfix:")
        debugLog("URL: \(url.absoluteString)")
        debugLog("JSON Body: \(jsonString)")

        URLSession.shared.dataTask(with: req) { [weak self] data, response, error in
            defer { DispatchQueue.main.async { self?.isSigningIn = false } }
            if let error = error {
                self?.debugLog("Network error during exchange: \(error.localizedDescription)")
                return
            }
            
            if let httpResponse = response as? HTTPURLResponse {
                self?.debugLog("HTTP Status: \(httpResponse.statusCode)")
            }
            
            guard let data = data else {
                self?.debugLog("Error: No data in response.")
                return
            }
            
            let responseBody = String(data: data, encoding: .utf8) ?? "non-utf8"
            self?.debugLog("Response Body: \(responseBody)")

            guard let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else {
                self?.debugLog("Error: Failed to parse response JSON.")
                return
            }

            if let accessToken = json["access_token"] as? String {
                let expiresIn = json["expires_in"] as? Double ?? 3600
                let expiresAt = Date().addingTimeInterval(expiresIn)
                
                let session = UserSession(
                    accessToken:  accessToken,
                    refreshToken: json["refresh_token"] as? String,
                    expiresAt:    expiresAt,
                    userId:       (json["user"] as? [String: Any])?["id"] as? String,
                    email:        (json["user"] as? [String: Any])?["email"] as? String
                )
                DispatchQueue.main.async { 
                    self?.setSession(session)
                    self?.debugLog("v\(self?.version ?? "unknown"): AUTHENTICATION SUCCESSFUL. UI Transition triggered.")
                }
            } else {
                let err = json["error"] as? String ?? "unknown"
                let msg = (json["error_description"] as? String) ?? (json["msg"] as? String) ?? ""
                self?.debugLog("EXCHANGE FAILED: \(err) - \(msg)")
            }
        }.resume()
    }

    // MARK: - Sign Out

    func signOut() {
        currentSession = nil
        UserDefaults.standard.removeObject(forKey: "nischay_access_token")
        UserDefaults.standard.removeObject(forKey: "nischay_refresh_token")
        UserDefaults.standard.removeObject(forKey: "nischay_expires_at")
        NotificationCenter.default.post(name: .nischayAuthStateChanged, object: nil)
    }
    
    // MARK: - Token Refresh
    
    func refreshSession(completion: ((Bool) -> Void)? = nil) {
        guard let refresh = currentSession?.refreshToken else {
            completion?(false); return
        }
        
        let supabaseURL = ConfigManager.shared.supabaseURL
        let anonKey = ConfigManager.shared.supabaseAnonKey
        guard let url = URL(string: "\(supabaseURL)/auth/v1/token?grant_type=refresh_token") else {
            completion?(false); return
        }
        
        var req = URLRequest(url: url)
        req.httpMethod = "POST"
        req.setValue("application/json", forHTTPHeaderField: "Content-Type")
        req.setValue(anonKey, forHTTPHeaderField: "apikey")
        req.setValue("Bearer \(anonKey)", forHTTPHeaderField: "Authorization")
        
        let body = ["refresh_token": refresh]
        req.httpBody = try? JSONSerialization.data(withJSONObject: body)
        
        URLSession.shared.dataTask(with: req) { [weak self] data, _, _ in
            guard let data = data,
                  let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                  let accessToken = json["access_token"] as? String else {
                DispatchQueue.main.async { completion?(false) }
                return
            }
            
            let expiresIn = json["expires_in"] as? Double ?? 3600
            let session = UserSession(
                accessToken:  accessToken,
                refreshToken: json["refresh_token"] as? String,
                expiresAt:    Date().addingTimeInterval(expiresIn),
                userId:       (json["user"] as? [String: Any])?["id"] as? String,
                email:        (json["user"] as? [String: Any])?["email"] as? String
            )
            DispatchQueue.main.async {
                self?.setSession(session)
                completion?(true)
            }
        }.resume()
    }

    // MARK: - Session persistence

    private func setSession(_ session: UserSession) {
        currentSession  = session
        UserDefaults.standard.set(session.accessToken,  forKey: "nischay_access_token")
        UserDefaults.standard.set(session.refreshToken, forKey: "nischay_refresh_token")
        if let expiry = session.expiresAt {
            UserDefaults.standard.set(expiry.timeIntervalSince1970, forKey: "nischay_expires_at")
        }
        NotificationCenter.default.post(name: .nischayAuthStateChanged, object: nil)
    }

    private func loadSession() {
        let defaults = UserDefaults.standard
        if let token = defaults.string(forKey: "nischay_access_token") {
            let refresh = defaults.string(forKey: "nischay_refresh_token")
            let expiryVal = defaults.double(forKey: "nischay_expires_at")
            let expiry = expiryVal > 0 ? Date(timeIntervalSince1970: expiryVal) : nil
            
            currentSession  = UserSession(accessToken: token,
                                          refreshToken: refresh,
                                          expiresAt: expiry,
                                          userId: nil, email: nil)
        }
    }
}

extension Data {
    func base64UrlEncodedString() -> String {
        var base64 = self.base64EncodedString()
        base64 = base64.replacingOccurrences(of: "+", with: "-")
        base64 = base64.replacingOccurrences(of: "/", with: "_")
        base64 = base64.replacingOccurrences(of: "=", with: "")
        return base64
    }
}

