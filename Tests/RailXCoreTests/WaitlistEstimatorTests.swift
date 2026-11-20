import XCTest
@testable import RailXCore

final class WaitlistEstimatorTests: XCTestCase {

    func testLowWaitlistIsHighChance() {
        let estimate = WaitlistEstimator.estimate(waitlistPosition: 1, daysToDeparture: 10)
        XCTAssertEqual(estimate.chancePercent, 95)
        XCTAssertEqual(estimate.band, "High")
    }

    func testDeepWaitlistIsLowChance() {
        let estimate = WaitlistEstimator.estimate(waitlistPosition: 30, daysToDeparture: 1)
        XCTAssertEqual(estimate.chancePercent, 5)
        XCTAssertEqual(estimate.band, "Low")
    }

    func testDisclaimerIsPresent() {
        XCTAssertTrue(WaitlistEstimator.disclaimer.contains("not official"))
    }
}
