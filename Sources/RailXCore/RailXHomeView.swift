import SwiftUI

/// RailX iOS home screen shell (Phase 1 scaffold).
/// Search is a UI placeholder for now — train data wiring to the shared
/// Supabase backend comes in a later phase, same as the Android roadmap.
public struct RailXHomeView: View {
    @State private var fromStation: String = ""
    @State private var toStation: String = ""
    @State private var journeyDate: Date = Date()

    public init() {}

    public var body: some View {
        NavigationStack {
            Form {
                Section("Journey") {
                    TextField("From station", text: $fromStation)
                    TextField("To station", text: $toStation)
                    DatePicker("Date", selection: $journeyDate, displayedComponents: .date)
                }
                Section {
                    Button("Search trains") {
                        // Phase 2: query the shared RailX backend.
                    }
                }
                Section("About") {
                    Text("RailX for iOS — native SwiftUI, reusing the same Supabase backend as RailX Android.")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
            }
            .navigationTitle("RailX")
        }
    }
}

#Preview {
    RailXHomeView()
}
