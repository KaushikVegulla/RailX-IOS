import Foundation

/// Response of the create-order Edge Function — field names match the
/// function (and Android) exactly.
public struct RazorpayOrder: Codable, Equatable, Sendable {
    public var orderId: String
    public var keyId: String
    public var amountPaise: Int
    public var currency: String

    public init(orderId: String, keyId: String, amountPaise: Int, currency: String) {
        self.orderId = orderId
        self.keyId = keyId
        self.amountPaise = amountPaise
        self.currency = currency
    }
}

public enum PaymentError: Error, Equatable {
    /// No backend configured in this build.
    case notConfigured
    /// The user must be signed in — the Edge Functions reject guests.
    case notSignedIn
    /// Signature verification failed on the server.
    case verificationFailed
    /// Amount below the server minimum of 1 rupee.
    case invalidAmount
}

/// Razorpay payments, server-side where it matters:
/// 1. create-order Edge Function creates the order (secret stays server-side)
/// 2. the app opens Razorpay Checkout with the returned order_id
/// 3. verify-payment Edge Function checks the signature before the
///    payment is treated as real — same flow as RailX Android.
public actor PaymentService {
    private let invoker: (any EdgeFunctionInvoking)?

    public init(config: RailXBackendConfig = .live) {
        invoker = SupabaseEdgeInvoker(config: config)
    }

    /// Test seam.
    public init(invoker: (any EdgeFunctionInvoking)?) {
        self.invoker = invoker
    }

    public var isConfigured: Bool { invoker != nil }

    private struct CreateOrderBody: Encodable {
        let amountRupees: Int
        let receipt: String
    }

    private struct VerifyBody: Encodable {
        let paymentId: String
        let orderId: String
        let signature: String
    }

    private struct VerifyResponse: Decodable {
        let verified: Bool
    }

    public func createOrder(amountRupees: Int, receipt: String = "railx_ios") async throws -> RazorpayOrder {
        guard let invoker else { throw PaymentError.notConfigured }
        guard amountRupees >= 1 else { throw PaymentError.invalidAmount }
        return try await invoker.invoke(
            "create-order",
            body: CreateOrderBody(amountRupees: amountRupees, receipt: receipt))
    }

    /// Returns true only when the server confirms the signature.
    public func verifyPayment(orderId: String, paymentId: String, signature: String) async throws -> Bool {
        guard let invoker else { throw PaymentError.notConfigured }
        do {
            let response: VerifyResponse = try await invoker.invoke(
                "verify-payment",
                body: VerifyBody(paymentId: paymentId, orderId: orderId, signature: signature))
            return response.verified
        } catch {
            // verify-payment answers HTTP 400 with {verified:false} for a
            // bad signature; the functions client surfaces that as a throw.
            // Treat any verify-call failure as "not verified", not success.
            return false
        }
    }
}
