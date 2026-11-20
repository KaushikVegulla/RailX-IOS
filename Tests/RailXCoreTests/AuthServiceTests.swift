import XCTest
@testable import RailXCore

final class AuthServiceTests: XCTestCase {

    func testLiveConfigMatchesAndroidBackend() {
        XCTAssertEqual(
            RailXBackendConfig.live.url.absoluteString,
            "https://etaaufimazvjdmpladom.supabase.co")
        XCTAssertTrue(RailXBackendConfig.live.publishableKey.hasPrefix("sb_publishable_"))
        XCTAssertTrue(RailXBackendConfig.live.isConfigured)
    }

    func testLiveAuthServiceIsConfigured() async {
        let auth = AuthService()
        let configured = await auth.isConfigured
        XCTAssertTrue(configured)
    }

    func testUnconfiguredAuthThrows() async {
        let auth = AuthService(config: .unconfigured)
        do {
            _ = try await auth.signIn(email: "test@example.com", password: "password123")
            XCTFail("Expected notConfigured to be thrown")
        } catch let error as RailXAuthError {
            XCTAssertEqual(error, .notConfigured)
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
    }

    func testUnconfiguredHasNoSession() async {
        let auth = AuthService(config: .unconfigured)
        let email = await auth.signedInEmail()
        XCTAssertNil(email)
    }
}
