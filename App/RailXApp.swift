import SwiftUI
import RailXCore

/// App entry point for the RailX iOS app.
/// The Xcode project is generated from `project.yml` (XcodeGen);
/// CI generates it fresh and builds this target for the simulator.
@main
struct RailXApp: App {
    init() {
        // Wire the Razorpay checkout presenter into RailXCore.
        RazorpayCheckoutBridge.register()
    }

    var body: some Scene {
        WindowGroup {
            RailXRootView()
        }
    }
}
