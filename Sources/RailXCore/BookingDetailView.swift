import SwiftUI

/// Booking detail — full ticket from Supabase, plus the Cancellation
/// Advisor ported from Android (IRCTC slabs, live refund countdown).
public struct BookingDetailView: View {
    public let booking: Booking

    public init(booking: Booking) {
        self.booking = booking
    }

    public var body: some View {
        List {
            Section("Train") {
                LabeledContent("Train", value: "\(booking.trainNumber) · \(booking.trainName)")
                LabeledContent("Route", value: "\(booking.fromName) (\(booking.fromCode)) → \(booking.toName) (\(booking.toCode))")
                LabeledContent("Date", value: booking.journeyDate)
                LabeledContent("Class", value: "\(booking.travelClassName) (\(booking.travelClassCode))")
                LabeledContent("Quota", value: booking.quota)
                LabeledContent("Status", value: booking.status)
            }

            Section("Ticket") {
                LabeledContent("PNR", value: booking.pnr)
                LabeledContent("Fare", value: "₹\(booking.fare)")
                LabeledContent("Amount paid", value: "₹\(booking.amount)")
                if !booking.paymentId.isEmpty {
                    LabeledContent("Payment ID", value: booking.paymentId)
                }
                if !booking.contact.isEmpty {
                    LabeledContent("Contact", value: booking.contact)
                }
            }

            if !booking.passengers.isEmpty {
                Section("Passengers") {
                    ForEach(Array(booking.passengers.enumerated()), id: \.offset) { _, passenger in
                        VStack(alignment: .leading, spacing: 2) {
                            Text(passenger.name).font(.headline)
                            Text("\(passenger.age) · \(passenger.gender) · \(passenger.berth)")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
            }

            if let quote = booking.cancellationQuote() {
                Section("Cancellation Advisor") {
                    LabeledContent("Time left", value: "\(Int(quote.hoursLeft))h")
                    LabeledContent("Cancellation charge", value: "₹\(Int(quote.totalCharge))")
                    LabeledContent("Estimated refund", value: "₹\(Int(quote.refund))")
                    Text("Estimate from the IRCTC slabs. Cloud bookings don't store the train's departure time, so 23:59 on the journey date is used — the same fallback as Android.")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .navigationTitle("PNR \(booking.pnr)")
    }
}
