import XCTest
@testable import Nischay

final class AuthManagerTests: XCTestCase {
    
    var authManager: AuthManager!
    
    override func setUp() {
        super.setUp()
        authManager = AuthManager.shared
        // Clear defaults
        UserDefaults.standard.removeObject(forKey: "nischay_access_token")
        UserDefaults.standard.removeObject(forKey: "nischay_refresh_token")
    }
    
    func testOAuthCallbackParsingSuccess() {
        // Supabase implicit/PKCE flow returns tokens in the URL fragment (hash)
        let rawURL = "nischay://auth-callback#access_token=test_access_jwt&expires_in=3600&refresh_token=test_refresh_jwt&token_type=bearer"
        let url = URL(string: rawURL)!
        
        authManager.handleCallback(url: url)
        
        // Ensure values were stored
        XCTAssertTrue(authManager.isAuthenticated)
        XCTAssertEqual(UserDefaults.standard.string(forKey: "nischay_access_token"), "test_access_jwt")
        XCTAssertEqual(UserDefaults.standard.string(forKey: "nischay_refresh_token"), "test_refresh_jwt")
    }
    
    func testOAuthCallbackParsingFailure() {
        // Clear first
        authManager.signOut()
        
        // Missing fragment entirely
        let missingFragment = URL(string: "nischay://auth-callback?error=access_denied")!
        authManager.handleCallback(url: missingFragment)
        XCTAssertFalse(authManager.isAuthenticated)
        
        // Missing access token
        let missingToken = URL(string: "nischay://auth-callback#refresh_token=123")!
        authManager.handleCallback(url: missingToken)
        
        // Ensure not authenticated
        XCTAssertFalse(authManager.isAuthenticated)
    }
    
    func testSignOutClearsState() {
        // Setup initial auth State
        UserDefaults.standard.set("fake_jwt", forKey: "nischay_access_token")
        let manager = AuthManager.shared // Reads from defaults on init
        
        XCTAssertTrue(manager.isAuthenticated)
        
        // Perform sign out
        manager.signOut()
        
        XCTAssertFalse(manager.isAuthenticated)
        XCTAssertNil(UserDefaults.standard.string(forKey: "nischay_access_token"))
        XCTAssertNil(UserDefaults.standard.string(forKey: "nischay_refresh_token"))
    }
}
