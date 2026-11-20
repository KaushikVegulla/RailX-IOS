import SwiftUI

/// RailX iOS Search tab — journey form, favourite-route shortcuts from
/// Supabase, and navigation to results. Mirrors Android's home screen
/// order of importance: search first.
public struct RailXHomeView: View {
    @State private var fromCode: String = ""
    @State private var toCode: String = ""
    @State private var journeyDate: Date = Date()
    @State private var classCode: String = "3A"
    @State private var quota: String = "GN"
    @State private var favourites: [FavouriteRoute] = []

    private let classCodes = ["1A", "2A", "3A", "SL", "2S", "CC"]
    private let quotas = ["GN", "TQ", "PT", "LD", "SS"]
    private let bookingService = BookingService()

    public init() {}

    private var query: TrainSearchQuery {
        TrainSearchQuery(
            fromCode: fromCode.trimmingCharacters(in: .whitespaces).uppercased(),
            toCode: toCode.trimmingCharacters(in: .whitespaces).uppercased(),
            date: journeyDate,
            classCode: classCode,
            quota: quota)
    }

    private var canSearch: Bool {
        query.fromCode.count >= 2 && query.toCode.count >= 2 && query.fromCode != query.toCode
    }

    public var body: some View {
        NavigationStack {
            Form {
                Section("Journey") {
                    TextField("From station code (e.g. NDLS)", text: $fromCode)
                        .textInputAutocapitalization(.characters)
                        .autocorrectionDisabled()
                    HStack {
                        TextField("To station code (e.g. MMCT)", text: $toCode)
                            .textInputAutocapitalization(.characters)
                            .autocorrectionDisabled()
                        Button {
                            let temp = fromCode
                            fromCode = toCode
                            toCode = temp
                        } label: {
                            Image(systemName: "arrow.up.arrow.down")
                        }
                        .buttonStyle(.borderless)
                        .accessibilityLabel("Swap stations")
                    }
                    DatePicker("Date", selection: $journeyDate, in: Date()..., displayedComponents: .date)
                    Picker("Class", selection: $classCode) {
                        ForEach(classCodes, id: \.self) { Text($0).tag($0) }
                    }
                    Picker("Quota", selection: $quota) {
                        ForEach(quotas, id: \.self) { Text($0).tag($0) }
                    }
                }

                if !favourites.isEmpty {
                    Section("Favourite routes") {
                        ForEach(favourites) { route in
                            Button("\(route.fromCode) → \(route.toCode)") {
                                fromCode = route.fromCode
                                toCode = route.toCode
                            }
                        }
                    }
                }

                Section {
                    NavigationLink {
                        TrainResultsView(query: query)
                    } label: {
                        Text("Search trains")
                    }
                    .disabled(!canSearch)
                    NavigationLink("Sign in") {
                        LoginView()
                    }
                }

                Section("About") {
                    Text("RailX for iOS — native SwiftUI, reusing the same Supabase backend as RailX Android. Your Android bookings appear under Trips.")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
            }
            .navigationTitle("RailX")
            .task {
                favourites = (try? await bookingService.favouriteRoutes()) ?? []
            }
        }
    }
}

#Preview {
    RailXHomeView()
}
