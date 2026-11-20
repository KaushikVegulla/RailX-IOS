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

    public init(query: TrainSearchQuery, searcher: any TrainSearching = UnavailableTrainSearch()) {
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
            message = "Live train data isn't connected on iOS yet.\n\nOn Android it comes from RailRadar, whose API key isn't shipped in this app. It will arrive through a Supabase Edge Function proxy — no trains are invented in the meantime.\n\nYour existing bookings are under the Trips tab."
        } catch {
            message = "Search failed: \(error.localizedDescription)"
        }
    }
}
