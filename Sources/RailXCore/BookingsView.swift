import SwiftUI

/// Trips tab — the signed-in user's bookings from the shared Supabase
/// backend, including tickets booked on RailX Android.
public struct BookingsView: View {
    @State private var bookings: [Booking] = []
    @State private var isLoading: Bool = true
    @State private var needsSignIn: Bool = false
    @State private var errorMessage: String?

    private let bookingService = BookingService()

    public init() {}

    public var body: some View {
        NavigationStack {
            Group {
                if isLoading {
                    ProgressView("Loading your trips…")
                } else if needsSignIn {
                    VStack(spacing: 12) {
                        Image(systemName: "person.crop.circle.badge.questionmark")
                            .font(.largeTitle)
                            .foregroundStyle(.secondary)
                        Text("Sign in to see your trips — they're stored in your RailX account, on Android and iOS alike.")
                            .multilineTextAlignment(.center)
                            .foregroundStyle(.secondary)
                        NavigationLink("Sign in") { LoginView() }
                    }
                    .padding()
                } else if let errorMessage {
                    VStack(spacing: 12) {
                        Text(errorMessage)
                            .multilineTextAlignment(.center)
                            .foregroundStyle(.secondary)
                        Button("Try again") { Task { await load() } }
                    }
                    .padding()
                } else if bookings.isEmpty {
                    VStack(spacing: 12) {
                        Image(systemName: "ticket")
                            .font(.largeTitle)
                            .foregroundStyle(.secondary)
                        Text("No bookings yet. Tickets you book on RailX Android or iOS will appear here.")
                            .multilineTextAlignment(.center)
                            .foregroundStyle(.secondary)
                    }
                    .padding()
                } else {
                    List(bookings) { booking in
                        NavigationLink {
                            BookingDetailView(booking: booking)
                        } label: {
                            BookingRow(booking: booking)
                        }
                    }
                    .refreshable { await load() }
                }
            }
            .navigationTitle("Trips")
            .task { await load() }
        }
    }

    private func load() async {
        isLoading = true
        defer { isLoading = false }
        do {
            bookings = try await bookingService.myBookings()
            needsSignIn = false
            errorMessage = nil
        } catch RailXServiceError.notSignedIn {
            needsSignIn = true
        } catch RailXServiceError.notConfigured {
            errorMessage = "Backend isn't configured in this build."
        } catch {
            errorMessage = "Couldn't load your trips: \(error.localizedDescription)"
        }
    }
}

struct BookingRow: View {
    let booking: Booking

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text("\(booking.fromCode) → \(booking.toCode)")
                    .font(.headline)
                Spacer()
                Text(booking.status)
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundStyle(booking.isCancelled ? .red : .green)
            }
            Text("\(booking.trainNumber) · \(booking.trainName)")
                .font(.subheadline)
            Text("\(booking.journeyDate) · \(booking.travelClassCode) · PNR \(booking.pnr)")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .padding(.vertical, 2)
    }
}
