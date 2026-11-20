import Razorpay
import RailXCore
import UIKit

/// Registers the Razorpay checkout presenter with RailXCore's
/// CheckoutBridge. Called once at app launch from RailXApp.
/// The Razorpay SDK is UIKit-based, so checkout is presented from
/// the key window's root view controller; only the public key id and
/// the server-created order_id ever reach this code — never a secret.
enum RazorpayCheckoutBridge {
    static func register() {
        CheckoutBridge.handler = { order, completion in
            DispatchQueue.main.async {
                guard let rootViewController = topViewController() else {
                    completion(.failure("No window to present checkout from"))
                    return
                }
                let presenter = CheckoutPresenter(order: order, completion: completion)
                CheckoutPresenterHolder.shared.current = presenter
                presenter.start(from: rootViewController)
            }
        }
    }

    private static func topViewController() -> UIViewController? {
        let scene = UIApplication.shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .first { $0.activationState == .foregroundActive }
            ?? UIApplication.shared.connectedScenes.compactMap { $0 as? UIWindowScene }.first
        var controller = scene?.windows.first(where: { $0.isKeyWindow })?.rootViewController
        while let presented = controller?.presentedViewController {
            controller = presented
        }
        return controller
    }
}

/// Keeps the presenter alive while checkout is on screen.
final class CheckoutPresenterHolder {
    static let shared = CheckoutPresenterHolder()
    var current: CheckoutPresenter?
}

final class CheckoutPresenter: NSObject, RazorpayPaymentCompletionProtocolWithData {
    private let order: RazorpayOrder
    private let completion: (CheckoutResult) -> Void
    private var razorpay: RazorpayCheckout?

    init(order: RazorpayOrder, completion: @escaping (CheckoutResult) -> Void) {
        self.order = order
        self.completion = completion
    }

    func start(from viewController: UIViewController) {
        razorpay = RazorpayCheckout.initWithKey(order.keyId, andDelegate: self)
        let options: [String: Any] = [
            "order_id": order.orderId,
            "amount": order.amountPaise,
            "currency": order.currency,
            "name": "RailX",
            "description": "RailX booking payment",
            "theme": ["color": "#1B4F9C"],
        ]
        razorpay?.open(options, displayController: viewController)
    }

    func onPaymentSuccess(_ payment_id: String, andData response: [AnyHashable: Any]?) {
        let signature = response?["razorpay_signature"] as? String ?? ""
        finish(.success(paymentId: payment_id, signature: signature))
    }

    func onPaymentError(_ code: Int32, description str: String, andData response: [AnyHashable: Any]?) {
        finish(.failure(str))
    }

    private func finish(_ result: CheckoutResult) {
        completion(result)
        CheckoutPresenterHolder.shared.current = nil
    }
}
