import Foundation

/// Account deletion (App Store Review Guideline 5.1.1(v)): calls the
/// delete-account Edge Function, which removes the user's data rows
/// and auth user server-side with the service role key.
public actor AccountService {
    private let invoker: (any EdgeFunctionInvoking)?

    public init(config: RailXBackendConfig = .live) {
        invoker = SupabaseEdgeInvoker(config: config)
    }

    /// Test seam.
    public init(invoker: (any EdgeFunctionInvoking)?) {
        self.invoker = invoker
    }

    private struct EmptyBody: Encodable {}
    private struct DeleteResponse: Decodable { let deleted: Bool }

    /// Returns true when the server confirms the account is gone.
    /// The caller should sign out locally afterwards regardless —
    /// the session's user no longer exists.
    public func deleteAccount() async throws -> Bool {
        guard let invoker else { throw EdgeFunctionError.notConfigured }
        let response: DeleteResponse = try await invoker.invoke("delete-account", body: EmptyBody())
        return response.deleted
    }
}
