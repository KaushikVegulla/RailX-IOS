import Foundation

// Row models for the shared RailX Supabase tables.
// Column names and shapes mirror supabase/schema.sql and the Android
// app's SupabaseModels.kt exactly, so both apps read the same rows.

/// One passenger inside a booking's `passengers` jsonb array.
/// Shape written by Android: {name, age, gender, berth, concession}.
/// Android stores age as a string, but decoding also accepts a number.
public struct BookingPassenger: Codable, Equatable, Sendable, Hashable {
    public var name: String
    public var age: String
    public var gender: String
    public var berth: String
    public var concession: String

    public init(name: String = "", age: String = "", gender: String = "",
                berth: String = "No Preference", concession: String = "None") {
        self.name = name
        self.age = age
        self.gender = gender
        self.berth = berth
        self.concession = concession
    }

    private enum CodingKeys: String, CodingKey {
        case name, age, gender, berth, concession
    }

    public init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        name = try c.decodeIfPresent(String.self, forKey: .name) ?? ""
        if let s = try? c.decode(String.self, forKey: .age) {
            age = s
        } else if let i = try? c.decode(Int.self, forKey: .age) {
            age = String(i)
        } else {
            age = ""
        }
        gender = try c.decodeIfPresent(String.self, forKey: .gender) ?? ""
        berth = try c.decodeIfPresent(String.self, forKey: .berth) ?? "No Preference"
        concession = try c.decodeIfPresent(String.self, forKey: .concession) ?? "None"
    }
}

/// A row of public.bookings — one RailX ticket, from either app.
public struct Booking: Codable, Equatable, Sendable, Hashable, Identifiable {
    public var id: String
    public var userId: String
    public var pnr: String
    public var trainNumber: String
    public var trainName: String
    public var fromCode: String
    public var toCode: String
    public var fromName: String
    public var toName: String
    public var travelClassCode: String
    public var travelClassName: String
    public var fare: Int
    public var journeyDate: String
    public var quota: String
    public var passengers: [BookingPassenger]
    public var contact: String
    public var status: String
    public var amount: Int
    public var paymentId: String
    public var orderId: String

    private enum CodingKeys: String, CodingKey {
        case id
        case userId = "user_id"
        case pnr
        case trainNumber = "train_number"
        case trainName = "train_name"
        case fromCode = "from_code"
        case toCode = "to_code"
        case fromName = "from_name"
        case toName = "to_name"
        case travelClassCode = "travel_class_code"
        case travelClassName = "travel_class_name"
        case fare
        case journeyDate = "journey_date"
        case quota
        case passengers
        case contact
        case status
        case amount
        case paymentId = "payment_id"
        case orderId = "order_id"
    }

    public init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id = try c.decodeIfPresent(String.self, forKey: .id) ?? ""
        userId = try c.decodeIfPresent(String.self, forKey: .userId) ?? ""
        pnr = try c.decodeIfPresent(String.self, forKey: .pnr) ?? ""
        trainNumber = try c.decodeIfPresent(String.self, forKey: .trainNumber) ?? ""
        trainName = try c.decodeIfPresent(String.self, forKey: .trainName) ?? ""
        fromCode = try c.decodeIfPresent(String.self, forKey: .fromCode) ?? ""
        toCode = try c.decodeIfPresent(String.self, forKey: .toCode) ?? ""
        fromName = try c.decodeIfPresent(String.self, forKey: .fromName) ?? ""
        toName = try c.decodeIfPresent(String.self, forKey: .toName) ?? ""
        travelClassCode = try c.decodeIfPresent(String.self, forKey: .travelClassCode) ?? ""
        travelClassName = try c.decodeIfPresent(String.self, forKey: .travelClassName) ?? ""
        fare = try c.decodeIfPresent(Int.self, forKey: .fare) ?? 0
        journeyDate = try c.decodeIfPresent(String.self, forKey: .journeyDate) ?? ""
        quota = try c.decodeIfPresent(String.self, forKey: .quota) ?? ""
        passengers = try c.decodeIfPresent([BookingPassenger].self, forKey: .passengers) ?? []
        contact = try c.decodeIfPresent(String.self, forKey: .contact) ?? ""
        status = try c.decodeIfPresent(String.self, forKey: .status) ?? "CONFIRMED"
        amount = try c.decodeIfPresent(Int.self, forKey: .amount) ?? 0
        paymentId = try c.decodeIfPresent(String.self, forKey: .paymentId) ?? ""
        orderId = try c.decodeIfPresent(String.self, forKey: .orderId) ?? ""
    }

    /// Memberwise init for tests and previews.
    public init(id: String = "", userId: String = "", pnr: String = "",
                trainNumber: String = "", trainName: String = "",
                fromCode: String = "", toCode: String = "",
                fromName: String = "", toName: String = "",
                travelClassCode: String = "", travelClassName: String = "",
                fare: Int = 0, journeyDate: String = "", quota: String = "",
                passengers: [BookingPassenger] = [], contact: String = "",
                status: String = "CONFIRMED", amount: Int = 0,
                paymentId: String = "", orderId: String = "") {
        self.id = id
        self.userId = userId
        self.pnr = pnr
        self.trainNumber = trainNumber
        self.trainName = trainName
        self.fromCode = fromCode
        self.toCode = toCode
        self.fromName = fromName
        self.toName = toName
        self.travelClassCode = travelClassCode
        self.travelClassName = travelClassName
        self.fare = fare
        self.journeyDate = journeyDate
        self.quota = quota
        self.passengers = passengers
        self.contact = contact
        self.status = status
        self.amount = amount
        self.paymentId = paymentId
        self.orderId = orderId
    }

    public var isCancelled: Bool { status.uppercased().contains("CANCEL") }

    /// Estimated cancellation quote from the ported IRCTC slabs.
    /// Mirrors Android's RefundPolicy fallback: when no departure time is
    /// stored (cloud bookings don't keep one), departure is taken as
    /// 23:59 on the journey date.
    public func cancellationQuote(now: Date = Date()) -> CancellationQuote? {
        guard !isCancelled,
              let departure = JourneyDate.departure(journeyDateString: journeyDate) else {
            return nil
        }
        let hours = departure.timeIntervalSince(now) / 3600
        guard hours > 0 else { return nil }
        guard let travelClass = TravelClass.from(code: travelClassCode) else { return nil }
        let pax = max(1, passengers.count)
        let totalFare = Double(max(fare, 0) * pax)
        let perPassengerCharge = RefundCalculator.cancellationCharge(
            ticketFare: Double(fare), travelClass: travelClass, hoursBeforeDeparture: hours)
        let totalCharge = min(totalFare, perPassengerCharge * Double(pax))
        return CancellationQuote(
            hoursLeft: hours,
            totalCharge: totalCharge,
            refund: max(0, totalFare - totalCharge))
    }
}

public struct CancellationQuote: Equatable, Sendable {
    public let hoursLeft: Double
    public let totalCharge: Double
    public let refund: Double

    public init(hoursLeft: Double, totalCharge: Double, refund: Double) {
        self.hoursLeft = hoursLeft
        self.totalCharge = totalCharge
        self.refund = refund
    }
}

/// A row of public.profiles.
public struct Profile: Codable, Equatable, Sendable, Hashable, Identifiable {
    public var id: String
    public var username: String
    public var fullName: String
    public var email: String
    public var mobile: String
    public var gender: String
    public var dob: String
    public var occupation: String
    public var maritalStatus: String
    public var nationality: String
    public var addressLine: String
    public var city: String
    public var state: String
    public var country: String
    public var pinCode: String
    public var profileComplete: Bool

    private enum CodingKeys: String, CodingKey {
        case id, username, email, mobile, gender, dob, occupation, nationality, city, state, country
        case fullName = "full_name"
        case maritalStatus = "marital_status"
        case addressLine = "address_line"
        case pinCode = "pin_code"
        case profileComplete = "profile_complete"
    }

    public init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id = try c.decodeIfPresent(String.self, forKey: .id) ?? ""
        username = try c.decodeIfPresent(String.self, forKey: .username) ?? ""
        fullName = try c.decodeIfPresent(String.self, forKey: .fullName) ?? ""
        email = try c.decodeIfPresent(String.self, forKey: .email) ?? ""
        mobile = try c.decodeIfPresent(String.self, forKey: .mobile) ?? ""
        gender = try c.decodeIfPresent(String.self, forKey: .gender) ?? ""
        dob = try c.decodeIfPresent(String.self, forKey: .dob) ?? ""
        occupation = try c.decodeIfPresent(String.self, forKey: .occupation) ?? ""
        maritalStatus = try c.decodeIfPresent(String.self, forKey: .maritalStatus) ?? ""
        nationality = try c.decodeIfPresent(String.self, forKey: .nationality) ?? ""
        addressLine = try c.decodeIfPresent(String.self, forKey: .addressLine) ?? ""
        city = try c.decodeIfPresent(String.self, forKey: .city) ?? ""
        state = try c.decodeIfPresent(String.self, forKey: .state) ?? ""
        country = try c.decodeIfPresent(String.self, forKey: .country) ?? ""
        pinCode = try c.decodeIfPresent(String.self, forKey: .pinCode) ?? ""
        profileComplete = try c.decodeIfPresent(Bool.self, forKey: .profileComplete) ?? false
    }
}

/// A row of public.passengers — a saved passenger, reusable across bookings.
public struct SavedPassenger: Codable, Equatable, Sendable, Hashable, Identifiable {
    public var id: String
    public var fullName: String
    public var age: Int?
    public var gender: String
    public var berthPreference: String
    public var concession: String

    private enum CodingKeys: String, CodingKey {
        case id, age, gender, concession
        case fullName = "full_name"
        case berthPreference = "berth_preference"
    }

    public init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id = try c.decodeIfPresent(String.self, forKey: .id) ?? ""
        fullName = try c.decodeIfPresent(String.self, forKey: .fullName) ?? ""
        age = try c.decodeIfPresent(Int.self, forKey: .age)
        gender = try c.decodeIfPresent(String.self, forKey: .gender) ?? ""
        berthPreference = try c.decodeIfPresent(String.self, forKey: .berthPreference) ?? "No Preference"
        concession = try c.decodeIfPresent(String.self, forKey: .concession) ?? "None"
    }
}

/// A row of public.favourite_routes.
public struct FavouriteRoute: Codable, Equatable, Sendable, Hashable, Identifiable {
    public var id: String
    public var fromCode: String
    public var toCode: String

    private enum CodingKeys: String, CodingKey {
        case id
        case fromCode = "from_code"
        case toCode = "to_code"
    }

    public init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id = try c.decodeIfPresent(String.self, forKey: .id) ?? ""
        fromCode = try c.decodeIfPresent(String.self, forKey: .fromCode) ?? ""
        toCode = try c.decodeIfPresent(String.self, forKey: .toCode) ?? ""
    }
}

/// Parses the journey_date text RailX stores ("26 Nov 2026", sometimes ISO).
public enum JourneyDate {
    private static let formatters: [DateFormatter] = ["d MMM yyyy", "dd MMM yyyy", "yyyy-MM-dd"].map { format in
        let f = DateFormatter()
        f.locale = Locale(identifier: "en_US_POSIX")
        f.dateFormat = format
        return f
    }

    public static func parse(_ string: String) -> Date? {
        let trimmed = string.trimmingCharacters(in: .whitespaces)
        for formatter in formatters {
            if let date = formatter.date(from: trimmed) { return date }
        }
        return nil
    }

    /// Departure instant used by the Cancellation Advisor: 23:59 local on
    /// the journey date, the same fallback Android's RefundPolicy uses
    /// when a train's departure time is not stored.
    public static func departure(journeyDateString: String) -> Date? {
        guard let day = parse(journeyDateString) else { return nil }
        var components = Calendar.current.dateComponents([.year, .month, .day], from: day)
        components.hour = 23
        components.minute = 59
        return Calendar.current.date(from: components)
    }

    public static func string(from date: Date) -> String {
        let f = DateFormatter()
        f.locale = Locale(identifier: "en_US_POSIX")
        f.dateFormat = "d MMM yyyy"
        return f.string(from: date)
    }
}

extension TravelClass {
    /// Maps an IRCTC class code to the refund slab class, matching
    /// Android RefundPolicy's flat-charge table (3E/CC price like 3A,
    /// anything unlisted prices like 2S).
    public static func from(code: String) -> TravelClass? {
        switch code.uppercased() {
        case "1A": return .firstAC
        case "2A": return .secondAC
        case "3A", "3E", "CC": return .thirdAC
        case "SL": return .sleeper
        case "2S": return .secondSitting
        default: return .secondSitting
        }
    }
}
