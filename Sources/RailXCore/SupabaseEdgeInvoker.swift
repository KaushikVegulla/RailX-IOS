import Foundation
import Supabase

/// EdgeFunctionInvoking backed by a real Supabase client.
/// The signed-in user's JWT is attached automatically by the SDK,
/// which the functions verify server-side.
public struct SupabaseEdgeInvoker: EdgeFunctionInvoking {
    private let client: SupabaseClient

    public init(client: SupabaseClient) {
        self.client = client
    }

    public init?(config: RailXBackendConfig) {
        guard let client = config.makeClient() else { return nil }
        self.init(client: client)
    }

    public func invoke<T: Decodable, B: Encodable>(_ name: String, body: B) async throws -> T {
        try await client.functions.invoke(name, options: FunctionInvokeOptions(body: body))
    }
}
