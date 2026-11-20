import XCTest
@testable import RailXCore

final class PaymentsTests: XCTestCase {

    func testCreateOrderDecodesFunctionResponse() async throws {
        let mock = MockEdgeInvoker()
        mock.responses["create-order"] = Data("""
        {"orderId": "order_NX123", "keyId": "rzp_test_abc", "amountPaise": 10000, "currency": "INR"}
        """.utf8)
        let service = PaymentService(invoker: mock)
        let order = try await service.createOrder(amountRupees: 100)
        XCTAssertEqual(order.orderId, "order_NX123")
        XCTAssertEqual(order.keyId, "rzp_test_abc")
        XCTAssertEqual(order.amountPaise, 10000)
        XCTAssertEqual(mock.calledFunctions, ["create-order"])
    }

    func testVerifyPaymentTrueAndFalse() async throws {
        let mock = MockEdgeInvoker()
        let service = PaymentService(invoker: mock)
        mock.responses["verify-payment"] = Data(#"{"verified": true}"#.utf8)
        let ok = try await service.verifyPayment(orderId: "o1", paymentId: "p1", signature: "s1")
        XCTAssertTrue(ok)
        mock.responses["verify-payment"] = Data(#"{"verified": false}"#.utf8)
        let bad = try await service.verifyPayment(orderId: "o1", paymentId: "p1", signature: "bad")
        XCTAssertFalse(bad)
    }

    func testUnconfiguredServiceThrows() async {
        let service = PaymentService(invoker: nil)
        do {
            _ = try await service.createOrder(amountRupees: 10)
            XCTFail("Expected notConfigured")
        } catch let error as PaymentError {
            XCTAssertEqual(error, .notConfigured)
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
    }

    func testInvalidAmountRejected() async {
        let service = PaymentService(invoker: MockEdgeInvoker())
        do {
            _ = try await service.createOrder(amountRupees: 0)
            XCTFail("Expected invalidAmount")
        } catch let error as PaymentError {
            XCTAssertEqual(error, .invalidAmount)
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
    }
}
