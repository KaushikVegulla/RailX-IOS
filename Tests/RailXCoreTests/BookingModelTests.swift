import XCTest
@testable import RailXCore

final class BookingModelTests: XCTestCase {

    private let bookingJSON = """
    {
      "id": "11111111-2222-3333-4444-555555555555",
      "user_id": "aaaaaaaa-bbbb-cccc-dddd-eeeeeeeeeeee",
      "pnr": "0044952507",
      "train_number": "12952",
      "train_name": "Mumbai Rajdhani",
      "from_code": "NDLS",
      "to_code": "MMCT",
      "from_name": "New Delhi",
      "to_name": "Mumbai Central",
      "travel_class_code": "1A",
      "travel_class_name": "First AC",
      "fare": 4520,
      "journey_date": "20 Nov 2026",
      "quota": "GN",
      "passengers": [
        {"name": "Kaushik", "age": "20", "gender": "Male", "berth": "Lower", "concession": "None"},
        {"name": "Guest", "age": 45, "gender": "Female", "berth": "Upper", "concession": "None"}
      ],
      "contact": "9999999999",
      "status": "CONFIRMED",
      "amount": 9040,
      "payment_id": "pay_test123",
      "order_id": "order_test123"
    }
    """

    func testBookingDecodesPostgrestRow() throws {
        let booking = try JSONDecoder().decode(Booking.self, from: Data(bookingJSON.utf8))
        XCTAssertEqual(booking.pnr, "0044952507")
        XCTAssertEqual(booking.trainNumber, "12952")
        XCTAssertEqual(booking.fromCode, "NDLS")
        XCTAssertEqual(booking.travelClassCode, "1A")
        XCTAssertEqual(booking.fare, 4520)
        XCTAssertEqual(booking.amount, 9040)
        XCTAssertEqual(booking.passengers.count, 2)
        XCTAssertEqual(booking.passengers[0].age, "20")
        // Age stored as a JSON number must also decode (as its string form).
        XCTAssertEqual(booking.passengers[1].age, "45")
        XCTAssertFalse(booking.isCancelled)
    }

    func testProfileDecodes() throws {
        let json = """
        {"id": "aaaaaaaa-bbbb-cccc-dddd-eeeeeeeeeeee", "username": "Admin",
         "full_name": "Kaushik", "email": "vegullakaushik@gmail.com",
         "mobile": "9999999999", "profile_complete": true}
        """
        let profile = try JSONDecoder().decode(Profile.self, from: Data(json.utf8))
        XCTAssertEqual(profile.username, "Admin")
        XCTAssertEqual(profile.fullName, "Kaushik")
        XCTAssertTrue(profile.profileComplete)
    }

    func testSavedPassengerDecodesNullAge() throws {
        let json = """
        {"id": "p1", "full_name": "Kaushik", "age": null, "gender": "Male",
         "berth_preference": "Lower", "concession": "None"}
        """
        let passenger = try JSONDecoder().decode(SavedPassenger.self, from: Data(json.utf8))
        XCTAssertNil(passenger.age)
        XCTAssertEqual(passenger.berthPreference, "Lower")
    }

    func testJourneyDateParsing() {
        XCTAssertNotNil(JourneyDate.parse("26 Nov 2026"))
        XCTAssertNotNil(JourneyDate.parse("2026-11-26"))
        XCTAssertNil(JourneyDate.parse("not a date"))
        let departure = JourneyDate.departure(journeyDateString: "20 Nov 2026")
        XCTAssertNotNil(departure)
        let components = Calendar.current.dateComponents([.hour, .minute], from: departure!)
        XCTAssertEqual(components.hour, 23)
        XCTAssertEqual(components.minute, 59)
    }

    func testCancellationQuoteMatchesAndroidSlabs() throws {
        let booking = try JSONDecoder().decode(Booking.self, from: Data(bookingJSON.utf8))
        // One passenger at the booking's per-passenger fare would be ideal,
        // but this fixture has 2 passengers; use a single-passenger copy.
        var single = booking
        single.passengers = [booking.passengers[0]]
        // Departure = 20 Nov 2026 23:59. Now = 19 Nov 2026 04:59 -> 43h left,
        // inside the 48-12h slab: 25% of 4520 = 1130, +5% GST = 1187 charge.
        var components = DateComponents()
        components.year = 2026
        components.month = 11
        components.day = 19
        components.hour = 4
        components.minute = 59
        let now = Calendar.current.date(from: components)!
        let quote = single.cancellationQuote(now: now)
        XCTAssertNotNil(quote)
        XCTAssertEqual(quote!.totalCharge, 1187, accuracy: 0.001)
        XCTAssertEqual(quote!.refund, 3333, accuracy: 0.001)
    }

    func testCancelledBookingHasNoQuote() throws {
        var booking = try JSONDecoder().decode(Booking.self, from: Data(bookingJSON.utf8))
        booking.status = "CANCELLED"
        XCTAssertNil(booking.cancellationQuote())
    }

    func testTravelClassMappingMatchesAndroid() {
        XCTAssertEqual(TravelClass.from(code: "3E"), .thirdAC)
        XCTAssertEqual(TravelClass.from(code: "CC"), .thirdAC)
        XCTAssertEqual(TravelClass.from(code: "SL"), .sleeper)
        XCTAssertEqual(TravelClass.from(code: "XX"), .secondSitting)
    }

    func testBookingServiceUnconfiguredThrows() async {
        let service = BookingService(config: .unconfigured)
        do {
            _ = try await service.myBookings()
            XCTFail("Expected notConfigured")
        } catch let error as RailXServiceError {
            XCTAssertEqual(error, .notConfigured)
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
    }
}
