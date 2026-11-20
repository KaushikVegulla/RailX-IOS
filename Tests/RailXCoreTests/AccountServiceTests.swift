import XCTest
@testable import RailXCore

final class AccountServiceTests: XCTestCase {

    func testDeleteAccountConfirmedByServer() async throws {
        let mock = MockEdgeInvoker()
        mock.responses["delete-account"] = Data(#"{"deleted": true}"#.utf8)
        let service = AccountService(invoker: mock)
        let deleted = try await service.deleteAccount()
        XCTAssertTrue(deleted)
        XCTAssertEqual(mock.calledFunctions, ["delete-account"])
    }

    func testDeleteAccountUnconfiguredThrows() async {
        let service = AccountService(invoker: nil)
        do {
            _ = try await service.deleteAccount()
            XCTFail("Expected notConfigured")
        } catch let error as EdgeFunctionError {
            XCTAssertEqual(error, .notConfigured)
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
    }
}
