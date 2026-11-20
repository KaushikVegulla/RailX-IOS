import Foundation

/// Minimal abstraction over Supabase Edge Function calls so services
/// can be unit-tested with a mock invoker (no network, no Supabase).
public protocol EdgeFunctionInvoking: Sendable {
    func invoke<T: Decodable, B: Encodable>(_ name: String, body: B) async throws -> T
}

public enum EdgeFunctionError: Error, Equatable {
    case notConfigured
}
