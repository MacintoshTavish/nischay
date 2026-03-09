import AppKit
import Foundation

/// Direct OpenAI API calls (chat completions + vision).
/// Used when ConfigManager.useEdgeFunctionAPI == false or user supplies their own key.
/// Mirrors callOpenAIAPI / callOpenAIVisionAPI from the NischaySystemDelegate RE analysis.
class OpenAIManager {

    private let endpoint = "https://api.openai.com/v1/chat/completions"
    private var apiKey: String   { ConfigManager.shared.openAIAPIKey }
    private var model: String    { ConfigManager.shared.openAIModel }
    private var maxTokens: Int   { ConfigManager.shared.maxTokens }
    private var temperature: Double { ConfigManager.shared.temperature }

    // MARK: - Text chat

    func callChatAPI(prompt: String) async throws -> String {
        guard !apiKey.isEmpty else { throw NischayError.noAPIKey }
        let messages: [[String: Any]] = [
            ["role": "system",  "content": "You are a helpful AI assistant that analyzes screen content and answers questions."],
            ["role": "user",    "content": prompt]
        ]
        return try await sendRequest(messages: messages)
    }

    // MARK: - Vision (image + text)

    func callVisionAPI(prompt: String, image: NSImage) async throws -> String {
        guard !apiKey.isEmpty else { throw NischayError.noAPIKey }

        guard let base64 = imageToBase64JPEG(image) else { throw NischayError.encodingFailed }

        let messages: [[String: Any]] = [
            ["role": "system", "content": "You are a helpful AI assistant that analyzes screen content and answers questions."],
            ["role": "user", "content": [
                ["type": "text",      "text": prompt],
                ["type": "image_url", "image_url": ["url": "data:image/jpeg;base64,\(base64)"]]
            ]]
        ]
        return try await sendRequest(messages: messages)
    }

    // MARK: - Shared request

    private func sendRequest(messages: [[String: Any]]) async throws -> String {
        guard let url = URL(string: endpoint) else { throw NischayError.invalidURL }

        var req = URLRequest(url: url)
        req.httpMethod = "POST"
        req.setValue("application/json",      forHTTPHeaderField: "Content-Type")
        req.setValue("Bearer \(apiKey)",       forHTTPHeaderField: "Authorization")

        let body: [String: Any] = [
            "model":       model,
            "max_tokens":  maxTokens,
            "temperature": temperature,
            "messages":    messages
        ]
        req.httpBody = try JSONSerialization.data(withJSONObject: body)

        let (data, _) = try await URLSession.shared.data(for: req)
        if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
           let choices = json["choices"] as? [[String: Any]],
           let msg = choices.first?["message"] as? [String: Any],
           let content = msg["content"] as? String {
            return content
        }
        // Surface API errors
        if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
           let error = json["error"] as? [String: Any],
           let msg = error["message"] as? String {
            throw NSError(domain: "OpenAI", code: -1, userInfo: [NSLocalizedDescriptionKey: msg])
        }
        throw NischayError.decodingFailed
    }

    // MARK: - Helpers

    private func imageToBase64JPEG(_ image: NSImage) -> String? {
        guard let tiff = image.tiffRepresentation,
              let bmp  = NSBitmapImageRep(data: tiff),
              let jpeg = bmp.representation(using: .jpeg, properties: [.compressionFactor: 0.7])
        else { return nil }
        return jpeg.base64EncodedString()
    }
}
