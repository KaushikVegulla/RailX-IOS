import XCTest
@testable import RailXCore

final class RefundCalculatorTests: XCTestCase {

    func testFlatChargeSlabBeyond48Hours() {
        // SL, Rs 1000 fare, 72h before departure -> flat Rs 120 charge, no GST (non-AC)
        let refund = RefundCalculator.refund(
            ticketFare: 1000, travelClass: .sleeper, hoursBeforeDeparture: 72)
        XCTAssertEqual(refund, 880, accuracy: 0.001)
    }

    func testMatchesRecordedAndroidCase() {
        // Verified on RailX Android (19 Nov 2026): 1A ticket Rs 4520 cancelled
        // ~19h before departure -> charge Rs 1187 (25% = 1130 + 5% GST), refund Rs 3333.
        let refund = RefundCalculator.refund(
            ticketFare: 4520, travelClass: .firstAC, hoursBeforeDeparture: 19)
        XCTAssertEqual(refund, 3333, accuracy: 0.001)
    }

    func testFiftyPercentSlab() {
        // 2A, Rs 2000 fare, 8h before departure -> 50% = 1000 + 5% GST = 1050 charge
        let refund = RefundCalculator.refund(
            ticketFare: 2000, travelClass: .secondAC, hoursBeforeDeparture: 8)
        XCTAssertEqual(refund, 950, accuracy: 0.001)
    }

    func testNoRefundWithin4Hours() {
        let refund = RefundCalculator.refund(
            ticketFare: 1000, travelClass: .thirdAC, hoursBeforeDeparture: 2)
        XCTAssertEqual(refund, 0, accuracy: 0.001)
    }
}
