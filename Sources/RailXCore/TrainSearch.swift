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

    public var id: String { number }

    public init(number: String, name: String, depart: String, arrive: String, duration: String) {
        self.number = number
        self.name = name
        self.depart = depart
        self.arrive = arrive
        self.duration = duration
    }
}

public enum TrainSearchError: Error, Equatable {
    /// Live train data comes from RailRadar on Android, whose API key is
    /// a per-account secret that is not shipped in the iOS app. Live
    /// search lands when the key can be proxied through a Supabase Edge
    /// Function — no train data is ever invented in the meantime.
    case liveDataUnavailable
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
