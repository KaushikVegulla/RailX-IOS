import Foundation

/// Heuristic waitlist confirmation estimator, ported from RailX Android.
/// This is a RailX estimate only — it is NOT official IRCTC data.
public enum WaitlistEstimator {

    public static let disclaimer = "RailX estimate, not official IRCTC data."

    public struct Estimate: Equatable, Sendable {
        public let chancePercent: Int
        public let band: String

        public init(chancePercent: Int, band: String) {
            self.chancePercent = chancePercent
            self.band = band
        }
    }

    public static func estimate(waitlistPosition: Int, daysToDeparture: Int) -> Estimate {
        let raw = 95 - (max(0, waitlistPosition) * 4) + (max(0, daysToDeparture) * 2)
        let chance = min(95, max(5, raw))
        let band: String
        if chance >= 70 {
            band = "High"
        } else if chance >= 40 {
            band = "Medium"
        } else {
            band = "Low"
        }
        return Estimate(chancePercent: chance, band: band)
    }
}
