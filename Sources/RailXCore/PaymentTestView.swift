import SwiftUI

/// Outcome of one Razorpay checkout presentation.
public enum CheckoutResult: Sendable {
    case success(paymentId: String, signature: String)
    case failure(String)
}

/// Dependency inversion for the Razorpay checkout UI: the SDK is
/// UIKit-based and lives in the app target, which registers a handler
/// at launch. RailXCore stays free of the Razorpay dependency while
/// owning the whole payment flow (order → checkout → verify).
public enum CheckoutBridge {
    public typealias Handler = (RazorpayOrder, @escaping (CheckoutResult) -> Void) -> Void
    public static var handler: Handler?
}

/// Phase 3 payment test screen — runs the real flow in Razorpay test
/// mode: create-order Edge Function → Razorpay Checkout →
/// verify-payment Edge Function. Until the functions are deployed it
/// reports the server error plainly; nothing is simulated.
public struct PaymentTestView: View {
    @State private var amountText: String = "1"
    @State private var status: String?
    @State private var isBusy: Bool = false

    private let payments = PaymentService()

    public init() {}

    public var body: some View {
        Form {
            Section("Test payment") {
                HStack {
                    Text("Amount")
                    Spacer()
                    TextField("Rupees", text: $amountText)
                        .keyboardType(.numberPad)
                        .multilineTextAlignment(.trailing)
                        .frame(width: 100)
                    Text("INR")
                        .foregroundStyle(.secondary)
                }
                Button("Pay with Razorpay") {
                    Task { await pay() }
                }
                .disabled(isBusy || Int(amountText) == nil)
            }
            if let status {
                Section("Result") {
                    Text(status)
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
            }
            Section {
                Text("Uses Razorpay test mode via the create-order and verify-payment Supabase Edge Functions — the Razorpay secret never enters this app. You must be signed in, and the functions must be deployed (see supabase/README.md).")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
        }
        .navigationTitle("Payments")
    }

    private func pay() async {
        guard let amount = Int(amountText), amount >= 1 else {
            status = "Enter an amount of at least ₹1."
            return
        }
        guard let handler = CheckoutBridge.handler else {
            status = "Razorpay checkout isn't wired in this build."
            return
        }
        isBusy = true
        defer { isBusy = false }
        do {
            let order = try await payments.createOrder(amountRupees: amount)
            let result: CheckoutResult = await withCheckedContinuation { continuation in
                handler(order) { continuation.resume(returning: $0) }
            }
            switch result {
            case .success(let paymentId, let signature):
                let verified = try await payments.verifyPayment(
                    orderId: order.orderId, paymentId: paymentId, signature: signature)
                status = verified
                    ? "Payment \(paymentId) verified by the server. Order \(order.orderId)."
                    : "Payment completed but the server could not verify its signature — treat it as unpaid."
            case .failure(let message):
                status = "Checkout failed or was cancelled: \(message)"
            }
        } catch {
            status = "Failed: \(error.localizedDescription)"
        }
    }
}

#Preview {
    NavigationStack { PaymentTestView() }
}
