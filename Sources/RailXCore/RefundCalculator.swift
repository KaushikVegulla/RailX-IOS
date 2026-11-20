import Foundation

/// Train travel class, mirroring the classes RailX Android supports.
public enum TravelClass: String, CaseIterable, Sendable {
    case firstAC = "1A"
    case secondAC = "2A"
    case thirdAC = "3A"
    case sleeper = "SL"
    case secondSitting = "2S"

    /// IRCTC minimum (flat) cancellation charge per passenger for this class.
    public var flatCharge: Double {
        switch self {
        case .firstAC: return 240
        case .secondAC: return 200
        case .thirdAC: return 180
        case .sleeper: return 120
        case .secondSitting: return 60
        }
    }

    /// GST (5%) applies on the cancellation charge for AC classes only.
    public var isAC: Bool {
        switch self {
        case .firstAC, .secondAC, .thirdAC: return true
        case .sleeper, .secondSitting: return false
        }
    }
}

/// Cancellation refund rules ported from RailX Android's Cancellation Advisor,
/// which applies the official IRCTC slabs:
/// - More than 48h before departure: flat charge only
/// - 48h to 12h: 25% of fare (minimum the flat charge)
/// - 12h to 4h: 50% of fare (minimum the flat charge)
/// - Within 4h: no refund
/// AC classes add 5% GST on the cancellation charge.
public enum RefundCalculator {

    public static func cancellationCharge(
        ticketFare: Double,
        travelClass: TravelClass,
        hoursBeforeDeparture: Double
    ) -> Double {
        guard ticketFare > 0, hoursBeforeDeparture > 4 else {
            return ticketFare > 0 ? ticketFare : 0
        }

        let percentage: Double
        if hoursBeforeDeparture > 48 {
            percentage = 0
        } else if hoursBeforeDeparture > 12 {
            percentage = 0.25
        } else {
            percentage = 0.50
        }

        var charge = max(travelClass.flatCharge, ticketFare * percentage)
        if travelClass.isAC {
            charge *= 1.05
        }
        return (charge).rounded()
    }

    public static func refund(
        ticketFare: Double,
        travelClass: TravelClass,
        hoursBeforeDeparture: Double
    ) -> Double {
        guard ticketFare > 0 else { return 0 }
        if hoursBeforeDeparture <= 4 { return 0 }
        let charge = cancellationCharge(
            ticketFare: ticketFare,
            travelClass: travelClass,
            hoursBeforeDeparture: hoursBeforeDeparture
        )
        return max(0, ticketFare - charge)
    }
}
