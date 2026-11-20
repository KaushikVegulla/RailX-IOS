import SwiftUI

/// Sign-in / sign-up screen backed by AuthService (Supabase Auth).
public struct LoginView: View {
    @State private var email: String = ""
    @State private var password: String = ""
    @State private var status: String?
    @State private var isBusy: Bool = false

    private let auth = AuthService()

    public init() {}

    public var body: some View {
        Form {
            Section("RailX account") {
                TextField("Email", text: $email)
                    .textInputAutocapitalization(.never)
                    .keyboardType(.emailAddress)
                    .autocorrectionDisabled()
                SecureField("Password", text: $password)
            }
            Section {
                Button("Sign in") { Task { await run { try await auth.signIn(email: email, password: password) } } }
                    .disabled(email.isEmpty || password.isEmpty || isBusy)
                Button("Create account") { Task { await run { try await auth.signUp(email: email, password: password) } } }
                    .disabled(email.isEmpty || password.isEmpty || isBusy)
            }
            if let status {
                Section {
                    Text(status)
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
            }
            Section {
                Text("Use the same account as RailX Android — both apps share one Supabase backend.")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
        }
        .navigationTitle("Sign in")
    }

    private func run(_ action: @escaping () async throws -> String) async {
        isBusy = true
        defer { isBusy = false }
        do {
            let signedInEmail = try await action()
            status = "Signed in as \(signedInEmail)"
        } catch {
            status = "Failed: \(error.localizedDescription)"
        }
    }
}

#Preview {
    NavigationStack { LoginView() }
}
