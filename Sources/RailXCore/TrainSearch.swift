import Foundation

/// A train search the user has filled in on the Search tab.
public struct TrainSearchQuery: Equatable, Sendable {
    public var fromCode: String
    public var toCode: String
    public var date: Date
    public var classCode: String
    public var quota: String

    public init(fromCode: String, toCode: String, date: Date,
                classCode: String = "3A", quota: String = "GN") {
        self.fromCode = fromCode
        self.toCode = toCode
        self.date = date
        self.classCode = classCode
        self.quota = quota
    }

    public var dateString: String { JourneyDate.string(from: date) }
}

/// One train on a results list (shape RailRadar returns on Android).
public struct TrainResult: Equatable, Sendable, Identifiable {
    public var number: String
    public var name: String
    public var depart: String
    public var arrive: String
    public var duration: String
    public var fromStation: String
    public var toStation: String
    public var distance: String

    public var id: String { number }

    public init(number: String, name: String, depart: String, arrive: String, duration: String,
                fromStation: String = "", toStation: String = "", distance: String = "") {
        self.number = number
        self.name = name
        self.depart = depart
        self.arrive = arrive
        self.duration = duration
        self.fromStation = fromStation
        self.toStation = toStation
        self.distance = distance
    }
}

public enum TrainSearchError: Error, Equatable {
    /// The railradar-proxy Edge Function isn't deployed/configured yet,
    /// so live data can't be reached. No train data is ever invented
    /// in the meantime.
    case liveDataUnavailable
    /// The proxy answered but the search itself failed (message from RailRadar).
    case searchFailed(String)
}

public protocol TrainSearching: Sendable {
    func search(_ query: TrainSearchQuery) async throws -> [TrainResult]
}

/// Placeholder search provider used until the RailRadar proxy exists.
public struct UnavailableTrainSearch: TrainSearching {
    public init() {}
    public func search(_ query: TrainSearchQuery) async throws -> [TrainResult] {
        throw TrainSearchError.liveDataUnavailable
    }
}
