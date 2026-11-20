import Foundation
import Supabase

public enum RailXServiceError: Error, Equatable {
    case notConfigured
    case notSignedIn
}

extension RailXBackendConfig {
    /// Builds a Supabase client for this config, or nil when unconfigured.
    public func makeClient() -> SupabaseClient? {
        guard isConfigured else { return nil }
        return SupabaseClient(supabaseURL: url, supabaseKey: publishableKey)
    }
}

/// Reads the signed-in user's RailX data from the shared Supabase backend.
/// RLS on every table restricts rows to their owner, so these queries
/// only ever return the current user's own data — same as Android.
public actor BookingService {
    private let client: SupabaseClient?

    public init(config: RailXBackendConfig = .live) {
        client = config.makeClient()
    }

    public var isConfigured: Bool { client != nil }

    private func requireClient() throws -> SupabaseClient {
        guard let client else { throw RailXServiceError.notConfigured }
        return client
    }

    private func requireSession(_ client: SupabaseClient) async throws {
        do {
            _ = try await client.auth.session
        } catch {
            throw RailXServiceError.notSignedIn
        }
    }

    /// The user's bookings, newest first — including tickets booked
    /// from RailX Android, since both apps share this table.
    public func myBookings() async throws -> [Booking] {
        let client = try requireClient()
        try await requireSession(client)
        let bookings: [Booking] = try await client
            .from("bookings")
            .select()
            .order("created_at", ascending: false)
            .execute()
            .value
        return bookings
    }

    /// The user's profile row, or nil if none exists yet.
    public func myProfile() async throws -> Profile? {
        let client = try requireClient()
        try await requireSession(client)
        let profiles: [Profile] = try await client
            .from("profiles")
            .select()
            .limit(1)
            .execute()
            .value
        return profiles.first
    }

    /// The user's saved passengers.
    public func savedPassengers() async throws -> [SavedPassenger] {
        let client = try requireClient()
        try await requireSession(client)
        let passengers: [SavedPassenger] = try await client
            .from("passengers")
            .select()
            .order("created_at", ascending: true)
            .execute()
            .value
        return passengers
    }

    /// The user's favourite routes, shown as search shortcuts.
    public func favouriteRoutes() async throws -> [FavouriteRoute] {
        let client = try requireClient()
        try await requireSession(client)
        let routes: [FavouriteRoute] = try await client
            .from("favourite_routes")
            .select()
            .order("created_at", ascending: false)
            .execute()
            .value
        return routes
    }
}
