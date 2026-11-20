import Foundation

/// Live train search through the railradar-proxy Edge Function.
/// The RailRadar API key stays in server secrets; the app only ever
/// holds the user's Supabase JWT. Response parsing mirrors Android's
/// RailKitClient.searchTrains field for field.
public struct RailRadarTrainSearch: TrainSearching {
    private let invoker: (any EdgeFunctionInvoking)?

    public init(config: RailXBackendConfig = .live) {
        invoker = SupabaseEdgeInvoker(config: config)
    }

    /// Test seam.
    public init(invoker: (any EdgeFunctionInvoking)?) {
        self.invoker = invoker
    }

    public func search(_ query: TrainSearchQuery) async throws -> [TrainResult] {
        guard let invoker else { throw TrainSearchError.liveDataUnavailable }
        struct Body: Encodable { let path: String }
        let iso = Self.isoDateString(from: query.date)
        let path = "trains/between/\(query.fromCode)/\(query.toCode)?date=\(iso)"
        do {
            let response: RailRadarBetweenResponse = try await invoker.invoke(
                "railradar-proxy", body: Body(path: path))
            return try RailRadarParser.parse(response)
        } catch let error as TrainSearchError {
            throw error
        } catch {
            // A missing (404) or unconfigured (500, "not configured")
            // proxy means live data simply isn't deployed yet.
            let description = String(describing: error).lowercased()
            if description.contains("404") || description.contains("not configured") ||
                description.contains("not found") {
                throw TrainSearchError.liveDataUnavailable
            }
            throw TrainSearchError.searchFailed(error.localizedDescription)
        }
    }

    static func isoDateString(from date: Date) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.string(from: date)
    }
}

/// The RailRadar /trains/between envelope: {success, data:{trains:[...]}, error}
public struct RailRadarBetweenResponse: Decodable {
    public var success: Bool
    public var trains: [RailRadarTrainRow]
    public var errorMessage: String?

    private enum RootKeys: String, CodingKey { case success, data, error }
    private enum DataKeys: String, CodingKey { case trains }
    private enum ErrorKeys: String, CodingKey { case message, code }

    public init(from decoder: Decoder) throws {
        let root = try decoder.container(keyedBy: RootKeys.self)
        success = try root.decodeIfPresent(Bool.self, forKey: .success) ?? false
        if let data = try? root.nestedContainer(keyedBy: DataKeys.self, forKey: .data) {
            trains = try data.decodeIfPresent([RailRadarTrainRow].self, forKey: .trains) ?? []
        } else {
            trains = []
        }
        if let message = try? root.decode(String.self, forKey: .error) {
            errorMessage = message
        } else if let error = try? root.nestedContainer(keyedBy: ErrorKeys.self, forKey: .error) {
            errorMessage = try error.decodeIfPresent(String.self, forKey: .message)
                ?? error.decodeIfPresent(String.self, forKey: .code)
        }
    }
}

public struct RailRadarTrainRow: Decodable {
    public var number: String
    public var name: String
    public var fromName: String
    public var fromCode: String
    public var departure: String
    public var toName: String
    public var toCode: String
    public var arrival: String
    public var durationMinutes: Int
    public var distanceKm: Int

    private enum RowKeys: String, CodingKey { case train, from, to, duration, distance }
    private enum TrainKeys: String, CodingKey { case number, name }
    private enum StationKeys: String, CodingKey { case name, code, departure, arrival }

    public init(from decoder: Decoder) throws {
        let row = try decoder.container(keyedBy: RowKeys.self)
        let train = try row.nestedContainer(keyedBy: TrainKeys.self, forKey: .train)
        number = try train.decodeIfPresent(String.self, forKey: .number) ?? ""
        name = try train.decodeIfPresent(String.self, forKey: .name) ?? ""
        let from = try row.nestedContainer(keyedBy: StationKeys.self, forKey: .from)
        fromName = try from.decodeIfPresent(String.self, forKey: .name) ?? ""
        fromCode = try from.decodeIfPresent(String.self, forKey: .code) ?? ""
        departure = try from.decodeIfPresent(String.self, forKey: .departure) ?? ""
        let to = try row.nestedContainer(keyedBy: StationKeys.self, forKey: .to)
        toName = try to.decodeIfPresent(String.self, forKey: .name) ?? ""
        toCode = try to.decodeIfPresent(String.self, forKey: .code) ?? ""
        arrival = try to.decodeIfPresent(String.self, forKey: .arrival) ?? ""
        durationMinutes = Int(try Self.flexibleDouble(row, .duration))
        distanceKm = Int(try Self.flexibleDouble(row, .distance))
    }

    /// RailRadar returns some numbers as JSON strings; accept both.
    private static func flexibleDouble(
        _ container: KeyedDecodingContainer<RowKeys>, _ key: RowKeys
    ) throws -> Double {
        if let value = try? container.decode(Double.self, forKey: key) { return value }
        if let string = try? container.decode(String.self, forKey: key) {
            return Double(string) ?? 0
        }
        return 0
    }
}

public enum RailRadarParser {
    public static func parse(_ response: RailRadarBetweenResponse) throws -> [TrainResult] {
        guard response.success else {
            throw TrainSearchError.searchFailed(response.errorMessage ?? "Train search failed")
        }
        return response.trains.map { row in
            TrainResult(
                number: padTrainNumber(row.number),
                name: row.name,
                depart: timePart(row.departure),
                arrive: timePart(row.arrival),
                duration: formatDuration(minutes: row.durationMinutes),
                fromStation: row.fromName.isEmpty ? row.fromCode : row.fromName,
                toStation: row.toName.isEmpty ? row.toCode : row.toName,
                distance: row.distanceKm > 0 ? "\(row.distanceKm) km" : "")
        }
    }

    /// Same helpers Android's RailKitClient applies.
    static func padTrainNumber(_ number: String) -> String {
        let digits = number.filter { $0.isNumber }
        return String(String(repeating: "0", count: max(0, 5 - digits.count)) + digits.suffix(5))
    }

    static func timePart(_ iso: String) -> String {
        if iso.isEmpty || iso == "null" { return "--" }
        let time = iso.contains("T") ? String(iso.split(separator: "T").last ?? "") : iso
        return String(time.prefix(5))
    }

    static func formatDuration(minutes: Int) -> String {
        guard minutes > 0 else { return "" }
        return "\(minutes / 60)h \(minutes % 60)m"
    }
}
