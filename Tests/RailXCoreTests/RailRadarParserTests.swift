import XCTest
@testable import RailXCore

final class RailRadarParserTests: XCTestCase {

    private let betweenFixture = """
    {
      "success": true,
      "data": {
        "trains": [
          {
            "train": {"number": "12952", "name": "Mumbai Rajdhani", "runDays": ["Mon", "Tue"]},
            "from": {"name": "New Delhi", "code": "NDLS", "departure": "2026-11-26T16:55:00"},
            "to": {"name": "Mumbai Central", "code": "MMCT", "arrival": "2026-11-27T08:35:00"},
            "duration": 940,
            "distance": 1384
          },
          {
            "train": {"number": "12002", "name": "Bhopal Shatabdi"},
            "from": {"name": "New Delhi", "code": "NDLS", "departure": "06:00"},
            "to": {"name": "Bhopal Jn", "code": "BPL", "arrival": "14:37"},
            "duration": "517",
            "distance": 707
          }
        ]
      }
    }
    """

    func testParsesRailRadarBetweenResponse() throws {
        let response = try JSONDecoder().decode(
            RailRadarBetweenResponse.self, from: Data(betweenFixture.utf8))
        let trains = try RailRadarParser.parse(response)
        XCTAssertEqual(trains.count, 2)
        XCTAssertEqual(trains[0].number, "12952")
        XCTAssertEqual(trains[0].depart, "16:55")
        XCTAssertEqual(trains[0].arrive, "08:35")
        XCTAssertEqual(trains[0].duration, "15h 40m")
        XCTAssertEqual(trains[0].distance, "1384 km")
        XCTAssertEqual(trains[0].fromStation, "New Delhi")
        // Duration arriving as a JSON string must parse too.
        XCTAssertEqual(trains[1].duration, "8h 37m")
        XCTAssertEqual(trains[1].depart, "06:00")
    }

    func testErrorEnvelopeThrowsWithRailRadarMessage() throws {
        let json = """
        {"success": false, "error": {"message": "Plan quota exhausted", "code": "PLAN_UPGRADE_REQUIRED"}}
        """
        let response = try JSONDecoder().decode(
            RailRadarBetweenResponse.self, from: Data(json.utf8))
        XCTAssertThrowsError(try RailRadarParser.parse(response)) { error in
            XCTAssertEqual(error as? TrainSearchError, .searchFailed("Plan quota exhausted"))
        }
    }

    func testSearchThroughMockProxy() async throws {
        let mock = MockEdgeInvoker()
        mock.responses["railradar-proxy"] = Data(betweenFixture.utf8)
        let search = RailRadarTrainSearch(invoker: mock)
        let query = TrainSearchQuery(fromCode: "NDLS", toCode: "MMCT", date: Date())
        let trains = try await search.search(query)
        XCTAssertEqual(trains.count, 2)
        XCTAssertEqual(mock.calledFunctions, ["railradar-proxy"])
    }

    func testPadTrainNumber() {
        XCTAssertEqual(RailRadarParser.padTrainNumber("12952"), "12952")
        XCTAssertEqual(RailRadarParser.padTrainNumber("652"), "00652")
    }
}
