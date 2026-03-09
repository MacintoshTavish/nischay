import XCTest
@testable import Nischay

final class ConfigManagerTests: XCTestCase {
    
    override func setUp() {
        super.setUp()
        // Clear out any existing keys for testing
        let domain = Bundle.main.bundleIdentifier ?? "test.domain"
        UserDefaults.standard.removePersistentDomain(forName: domain)
    }
    
    // Test that the singleton initializes with safe defaults
    func testDefaultValues() {
        let config = ConfigManager.shared
        XCTAssertEqual(config.supabaseURL, "")
        XCTAssertEqual(config.supabaseAnonKey, "")
        XCTAssertEqual(config.openAIAPIKey, "")
        XCTAssertFalse(config.useVisionMode)
        XCTAssertFalse(config.isShortAnswerMode)
    }
    
    // Test reading and writing boolean properties directly to UserDefaults
    func testFlags() {
        let config = ConfigManager.shared
        
        config.isShortAnswerMode = true
        config.useVisionMode = true
        
        // Ensure values are stored in UserDefaults correctly
        XCTAssertTrue(UserDefaults.standard.bool(forKey: "isShortAnswerMode"))
        XCTAssertTrue(UserDefaults.standard.bool(forKey: "useVisionMode"))
        
        // Ensure properties read correctly
        XCTAssertTrue(config.isShortAnswerMode)
        XCTAssertTrue(config.useVisionMode)
    }
    
    // Test API Keys are securely persisted without caching issues
    func testAPIKeyStorage() {
        let config = ConfigManager.shared
        
        let testURL = "https://example.supabase.co"
        let testKey = "sk-test1234"
        
        config.supabaseURL = testURL
        config.openAIAPIKey = testKey
        
        XCTAssertEqual(UserDefaults.standard.string(forKey: "supabaseURL"), testURL)
        XCTAssertEqual(UserDefaults.standard.string(forKey: "openAIAPIKey"), testKey)
        
        XCTAssertEqual(config.supabaseURL, testURL)
        XCTAssertEqual(config.openAIAPIKey, testKey)
    }
}
