import XCTest
@testable import Nischay

final class ModelsTests: XCTestCase {
    
    func testChatMessageCodable() throws {
        // Test Encoding
        let message = ChatMessage(role: "user", content: "What is this?", timestamp: Date())
        let encoder = JSONEncoder()
        let data = try encoder.encode(message)
        
        // Test Decoding
        let decoder = JSONDecoder()
        let decodedMessage = try decoder.decode(ChatMessage.self, from: data)
        
        XCTAssertEqual(decodedMessage.role, "user")
        XCTAssertEqual(decodedMessage.content, "What is this?")
    }
}
