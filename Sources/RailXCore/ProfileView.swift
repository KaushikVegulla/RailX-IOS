import SwiftUI

/// Profile tab — the user's profile row and saved passengers from
/// Supabase, with sign-out. Same account as RailX Android.
public struct ProfileView: View {
    @State private var profile: Profile?
    @State private var passengers: [SavedPassenger] = []
    @State private var signedInEmail: String?
    @State private var isLoading: Bool = true
    @State private var message: String?

    private let bookingService = BookingService()
    private let auth = AuthService()

    public init() {}

    public var body: some View {
        NavigationStack {
            Group {
                if isLoading {
                    ProgressView("Loading profile…")
                } else if signedInEmail == nil {
                    VStack(spacing: 12) {
                        Image(systemName: "person.circle")
                            .font(.largeTitle)
                            .foregroundStyle(.secondary)
                        Text("You're not signed in.")
                            .foregroundStyle(.secondary)
                        NavigationLink("Sign in") { LoginView() }
                    }
                    .padding()
                } else {
                    List {
                        Section("Account") {
                            if let username = profile?.username, !username.isEmpty {
                                LabeledContent("User ID", value: username)
                            }
                            if let name = profile?.fullName, !name.isEmpty {
                                LabeledContent("Name", value: name)
                            }
                            LabeledContent("Email", value: signedInEmail ?? "")
                            if let mobile = profile?.mobile, !mobile.isEmpty {
                                LabeledContent("Mobile", value: mobile)
                            }
                            if let profile {
                                LabeledContent("Profile complete", value: profile.profileComplete ? "Yes" : "No")
                            }
                        }

                        if !passengers.isEmpty {
                            Section("Saved passengers") {
                                ForEach(passengers) { passenger in
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text(passenger.fullName).font(.headline)
                                        Text("\(passenger.age.map { String($0) } ?? "—") · \(passenger.gender) · \(passenger.berthPreference)")
                                            .font(.caption)
                                            .foregroundStyle(.secondary)
                                    }
                                }
                            }
                        }

                        if let message {
                            Section {
                                Text(message)
                                    .font(.footnote)
                                    .foregroundStyle(.secondary)
                            }
                        }

                        Section {
                            Button("Sign out", role: .destructive) {
                                Task { await signOut() }
                            }
                        }
                    }
                }
            }
            .navigationTitle("Profile")
            .task { await load() }
        }
    }

    private func load() async {
        isLoading = true
        defer { isLoading = false }
        signedInEmail = await auth.signedInEmail()
        guard signedInEmail != nil else { return }
        profile = try? await bookingService.myProfile()
        passengers = (try? await bookingService.savedPassengers()) ?? []
    }

    private func signOut() async {
        do {
            try await auth.signOut()
            signedInEmail = nil
            profile = nil
            passengers = []
            message = "Signed out."
        } catch {
            message = "Sign-out failed: \(error.localizedDescription)"
        }
    }
}
