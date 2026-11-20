import SwiftUI
import RailXCore

/// App entry point for the RailX iOS app.
/// This file is used by the Xcode project generated from `project.yml`
/// (XcodeGen) in Phase 1. The SwiftPM package itself builds and tests
/// RailXCore on CI without the app target.
@main
struct RailXApp: App {
    var body: some Scene {
        WindowGroup {
            RailXHomeView()
        }
    }
}
