import SwiftUI

/// RailX iOS root — tabs in Android's order of importance:
/// Search, Trips (bookings/history), Profile.
public struct RailXRootView: View {
    public init() {}

    public var body: some View {
        TabView {
            RailXHomeView()
                .tabItem { Label("Search", systemImage: "magnifyingglass") }
            BookingsView()
                .tabItem { Label("Trips", systemImage: "ticket") }
            ProfileView()
                .tabItem { Label("Profile", systemImage: "person.circle") }
        }
    }
}

#Preview {
    RailXRootView()
}
