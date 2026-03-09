import Foundation
import AppKit

// MARK: - Shared Data Models

struct ChatMessage: Codable, Identifiable {
    var id = UUID()
    let role: String       // "user" or "assistant"
    let content: String
    let timestamp: Date

    enum CodingKeys: String, CodingKey {
        case id, role, content
        case timestamp = "created_at"
    }
}

// MARK: - Notification Names

extension Notification.Name {
    static let nischayAnalysisUpdate    = Notification.Name("nischayAnalysisUpdate")
    static let nischayAnalysisError     = Notification.Name("nischayAnalysisError")
    static let nischayChatHistoryLoaded = Notification.Name("nischayChatHistoryLoaded")
    static let nischayAuthStateChanged  = Notification.Name("nischayAuthStateChanged")
}

// MARK: - Delegate Protocols

@MainActor
protocol ScreenCaptureDelegate: AnyObject {
    func didCaptureFrame(_ image: NSImage)
}

@MainActor
protocol ChatInputDelegate: AnyObject {
    func didSubmitQuery(_ query: String)
}
