import Foundation
import Supabase

public enum RailXAuthError: Error, Equatable {
    case notConfigured
}

/// Email/password auth against the shared RailX Supabase project —
/// the same accounts RailX Android users sign in with (email or the
/// account created on Android both live in the same Auth user pool).
public actor AuthService {
    private let client: SupabaseClient?

    public init(config: RailXBackendConfig = .live) {
        if config.isConfigured {
            client = SupabaseClient(supabaseURL: config.url, supabaseKey: config.publishableKey)
        } else {
            client = nil
        }
    }

    public var isConfigured: Bool { client != nil }

    private func requireClient() throws -> SupabaseClient {
        guard let client else { throw RailXAuthError.notConfigured }
        return client
    }

    /// Signs in and returns the account email.
    public func signIn(email: String, password: String) async throws -> String {
        let session = try await requireClient().auth.signIn(email: email, password: password)
        return session.user.email ?? email
    }

    /// Creates an account and returns its email.
    public func signUp(email: String, password: String) async throws -> String {
        let response = try await requireClient().auth.signUp(email: email, password: password)
        return response.user.email ?? email
    }

    public func signOut() async throws {
        try await requireClient().auth.signOut()
    }

    /// Email of the restored session, if the user is still signed in.
    /// The Supabase Swift SDK persists the session in the Keychain,
    /// matching Android's behaviour of staying signed in across launches.
    public func signedInEmail() async -> String? {
        guard let client else { return nil }
        return try? await client.auth.session.user.email
    }
}
