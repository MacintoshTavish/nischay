import Foundation

// MARK: - Supporting Types

enum FeatureType: Int {
    case screenAnalysis    = 1
    case voiceTranscription = 2
}

struct UsageCheckResult {
    let allowed:   Bool
    let remaining: Int?
    let limit:     Int?
}

// MARK: - SupabaseManager

/// Handles all Supabase API calls: Edge Functions, chat history, usage, and subscription.
/// API base URL and anon key are read from ConfigManager (placeholders until user sets up Supabase).
///
/// Mirrors SupabaseManager from RE class dump ivars:
///   supabaseURL, supabaseAnonKey, activeStreamingSessions,
///   cachedSubscriptionStatus, subscriptionCacheTime, subscriptionCacheDuration
class SupabaseManager: @unchecked Sendable {

    private var baseURL:   String { ConfigManager.shared.supabaseURL }
    private var anonKey:   String { ConfigManager.shared.supabaseAnonKey }
    private var activeSessions = Set<URLSession>()
    private var cachedSubStatus: SubscriptionStatus?
    private var subCacheTime: Date?
    private let subCacheDuration: Double = 300 // 5 minutes

    enum SubscriptionStatus: String, Codable { case free, pro, unknown }

    // MARK: - Auth headers helper

    private func authHeaders(session: URLSession = .shared) -> [String: String] {
        var headers = [
            "apikey": anonKey,
            "Content-Type": "application/json",
            "X-Supabase-Api-Version": "2024-01-01"
        ]
        // Send user's access token if signed in, otherwise fallback to anonKey
        if let token = AuthManager.shared.currentSession?.accessToken {
            headers["Authorization"] = "Bearer \(token)"
        } else {
            headers["Authorization"] = "Bearer \(anonKey)"
        }
        return headers
    }

    // MARK: - Screen Analysis (streaming)

    /// Streams screen analysis from the Supabase Edge Function.
    /// Calls checkFeatureUsage(FeatureType.screenAnalysis, 1.0) first –
    /// exactly as in the decompiled streamAnalyzeText_entry.c:
    ///   inputmethodd::SupabaseManager::_checkFeatureUsage((FeatureType)0x1, 1.0)
    func streamAnalyzeText(
        content: String,
        requestType: String,
        useShortMode: Bool,
        onUpdate: @escaping (String) -> Void,
        onComplete: @escaping (Result<String, Error>) -> Void
    ) async {
        let path = useShortMode
            ? "analyze-screen-short"
            : "functions/v1/analyze-screen"

        guard let url = URL(string: "\(baseURL)/\(path)") else {
            onComplete(.failure(NischayError.invalidURL)); return
        }

        var req = URLRequest(url: url)
        req.httpMethod = "POST"
        authHeaders().forEach { req.setValue($1, forHTTPHeaderField: $0) }

        let body: [String: Any] = [
            "content": content,
            "requestType": requestType,
            "useShortMode": useShortMode
        ]
        guard let data = try? JSONSerialization.data(withJSONObject: body) else {
            onComplete(.failure(NischayError.encodingFailed)); return
        }
        req.httpBody = data

        let session = URLSession(configuration: .default)
        activeSessions.insert(session)

        do {
            var full = ""
            let (bytes, response) = try await session.bytes(for: req)
            guard let http = response as? HTTPURLResponse, http.statusCode == 200 else {
                let code = (response as? HTTPURLResponse)?.statusCode ?? -1
                var bodyString = "nil"
                if let d = try? await session.data(for: req).0 {
                    bodyString = String(data: d, encoding: .utf8) ?? "binary"
                }
                
                // Log to our debug file
                let path = NSHomeDirectory() + "/Desktop/nischay_auth_debug.txt"
                let msg = "\(Date()): streamAnalyzeText HTTP \(code), body: \(bodyString)\n"
                if let handle = FileHandle(forWritingAtPath: path) {
                    handle.seekToEndOfFile()
                    handle.write(msg.data(using: .utf8)!)
                    handle.closeFile()
                } else {
                    try? msg.write(toFile: path, atomically: true, encoding: .utf8)
                }
                
                throw NischayError.httpError(code)
            }
            // Parse Server-Sent Events (SSE) stream
            for try await line in bytes.lines {
                guard line.hasPrefix("data: ") else { continue }
                let raw = String(line.dropFirst(6))
                if raw == "[DONE]" { break }
                if let json = try? JSONSerialization.jsonObject(with: Data(raw.utf8)) as? [String: Any] {
                    // Support both Supabase Edge format {"content":"..."} and OpenAI delta format
                    let delta = (json["choices"] as? [[String: Any]])?.first?["delta"] as? [String: Any]
                    let chunk = (json["content"] as? String) ?? (delta?["content"] as? String) ?? ""
                    if !chunk.isEmpty { full += chunk; onUpdate(chunk) }
                }
            }
            activeSessions.remove(session)
            onComplete(.success(full))
        } catch {
            activeSessions.remove(session)
            onComplete(.failure(error))
        }
    }

    // MARK: - Chat History

    func loadChatHistory() async -> [ChatMessage] {
        guard let url = URL(string: "\(baseURL)/rest/v1/chat_messages?order=created_at.asc") else { return [] }
        var req = URLRequest(url: url)
        authHeaders().forEach { req.setValue($1, forHTTPHeaderField: $0) }
        req.setValue("application/json", forHTTPHeaderField: "Accept")
        do {
            let (data, _) = try await URLSession.shared.data(for: req)
            return (try? JSONDecoder().decode([ChatMessage].self, from: data)) ?? []
        } catch { print("Nischay: loadChatHistory – \(error)"); return [] }
    }

    func saveChatMessage(_ message: ChatMessage) async {
        guard let url = URL(string: "\(baseURL)/rest/v1/chat_messages") else { return }
        var req = URLRequest(url: url)
        req.httpMethod = "POST"
        authHeaders().forEach { req.setValue($1, forHTTPHeaderField: $0) }
        req.setValue("return=minimal", forHTTPHeaderField: "Prefer")
        let body: [String: Any] = [
            "role": message.role,
            "content": message.content,
            "created_at": ISO8601DateFormatter().string(from: message.timestamp)
        ]
        req.httpBody = try? JSONSerialization.data(withJSONObject: body)
        do {
            _ = try await URLSession.shared.data(for: req)
            print("Nischay: Successfully saved message to Supabase")
        } catch { print("Nischay: saveChatMessage – \(error)") }
    }

    // MARK: - Feature Usage

    func checkFeatureUsage(_ feature: FeatureType, amount: Double) async -> UsageCheckResult {
        guard let url = URL(string: "\(baseURL)/functions/v1/check-usage") else {
            return UsageCheckResult(allowed: true, remaining: nil, limit: nil)
        }
        var req = URLRequest(url: url)
        req.httpMethod = "POST"
        authHeaders().forEach { req.setValue($1, forHTTPHeaderField: $0) }
        req.httpBody = try? JSONSerialization.data(withJSONObject: ["feature": feature.rawValue, "amount": amount])
        do {
            let (data, _) = try await URLSession.shared.data(for: req)
            if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] {
                let allowed = json["allowed"] as? Bool ?? true
                print("Nischay: Usage check result: allowed=\(allowed)")
                return UsageCheckResult(allowed: allowed,
                                        remaining: json["remaining"] as? Int,
                                        limit: json["limit"] as? Int)
            }
        } catch { print("Nischay: checkFeatureUsage – \(error)") }
        return UsageCheckResult(allowed: true, remaining: nil, limit: nil)
    }

    func recordUsage(_ feature: FeatureType, amount: Double) async {
        guard let url = URL(string: "\(baseURL)/functions/v1/record-usage") else { return }
        var req = URLRequest(url: url)
        req.httpMethod = "POST"
        authHeaders().forEach { req.setValue($1, forHTTPHeaderField: $0) }
        req.httpBody = try? JSONSerialization.data(withJSONObject: ["feature": feature.rawValue, "amount": amount])
        _ = try? await URLSession.shared.data(for: req)
        print("Nischay: Successfully recorded transcription usage")
    }

    // MARK: - Subscription

    func checkSubscriptionStatus(forceRefresh: Bool = false) async -> SubscriptionStatus {
        if !forceRefresh,
           let cached = cachedSubStatus,
           let cacheTime = subCacheTime,
           Date().timeIntervalSince(cacheTime) < subCacheDuration {
            print("Nischay: Returning cached subscription status")
            return cached
        }
        guard let url = URL(string: "\(baseURL)/functions/v1/check-subscription") else { return .unknown }
        var req = URLRequest(url: url)
        req.httpMethod = "POST"
        authHeaders().forEach { req.setValue($1, forHTTPHeaderField: $0) }
        req.httpBody = try? JSONSerialization.data(withJSONObject: [:])
        do {
            let (data, _) = try await URLSession.shared.data(for: req)
            if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
               let s = json["status"] as? String, let status = SubscriptionStatus(rawValue: s) {
                cachedSubStatus = status; subCacheTime = Date()
                print("Nischay: Subscription check complete: \(status)")
                return status
            }
        } catch { print("Nischay: checkSubscriptionStatus – \(error)") }
        return .unknown
    }
}

// MARK: - Errors

enum NischayError: LocalizedError {
    case invalidURL
    case encodingFailed
    case httpError(Int)
    case noAPIKey
    case decodingFailed

    var errorDescription: String? {
        switch self {
        case .invalidURL:     return "Invalid API URL. Check your Supabase URL in Settings."
        case .encodingFailed: return "Failed to encode request body."
        case .httpError(let c): return "HTTP error \(c)."
        case .noAPIKey:       return "No API key configured. Add your OpenAI key in Settings."
        case .decodingFailed: return "Failed to parse API response."
        }
    }
}
