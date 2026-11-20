import SwiftUI

/// Results screen for a train search. Live data on Android comes from
/// RailRadar; the iOS app does not ship that API key, so until the key
/// is proxied through a Supabase Edge Function this screen says so
/// plainly instead of showing invented trains.
public struct TrainResultsView: View {
    public let query: TrainSearchQuery
    private let searcher: any TrainSearching

    @State private var trains: [TrainResult] = []
    @State private var message: String?
    @State private var isLoading: Bool = true

    public init(query: TrainSearchQuery, searcher: any TrainSearching = RailRadarTrainSearch()) {
        self.query = query
        self.searcher = searcher
    }

    public var body: some View {
        Group {
            if isLoading {
                ProgressView("Searching trains…")
            } else if let message {
                VStack(spacing: 12) {
                    Image(systemName: "antenna.radiowaves.left.and.right.slash")
                        .font(.largeTitle)
                        .foregroundStyle(.secondary)
                    Text(message)
                        .multilineTextAlignment(.center)
                        .foregroundStyle(.secondary)
                }
                .padding()
            } else {
                List(trains) { train in
                    VStack(alignment: .leading, spacing: 4) {
                        Text("\(train.number) · \(train.name)")
                            .font(.headline)
                        Text("\(train.depart) → \(train.arrive) · \(train.duration)")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                        if !train.fromStation.isEmpty {
                            Text("\(train.fromStation) → \(train.toStation)\(train.distance.isEmpty ? "" : " · \(train.distance)")")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
            }
        }
        .navigationTitle("\(query.fromCode) → \(query.toCode)")
        .task {
            await load()
        }
    }

    private func load() async {
        isLoading = true
        defer { isLoading = false }
        do {
            trains = try await searcher.search(query)
            if trains.isEmpty {
                message = "No trains found for \(query.dateString)."
            }
        } catch TrainSearchError.liveDataUnavailable {
            message = "Live train data isn't reachable yet.\n\nSearches go through the railradar-proxy Supabase Edge Function so the RailRadar API key never ships in this app. That function still needs deploying (see supabase/README.md in the repo) — no trains are invented in the meantime.\n\nYour existing bookings are under the Trips tab."
        } catch TrainSearchError.searchFailed(let reason) {
            message = "Train search failed: \(reason)"
        } catch {
            message = "Search failed: \(error.localizedDescription)"
        }
    }
}
