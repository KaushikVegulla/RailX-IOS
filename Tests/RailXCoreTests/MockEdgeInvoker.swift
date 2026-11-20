import Foundation
@testable import RailXCore

/// Test double for EdgeFunctionInvoking: returns canned JSON per
/// function name, decoded into whatever type the caller asks for.
final class MockEdgeInvoker: EdgeFunctionInvoking, @unchecked Sendable {
    var responses: [String: Data] = [:]
    private(set) var calledFunctions: [String] = []

    func invoke<T: Decodable, B: Encodable>(_ name: String, body: B) async throws -> T {
        calledFunctions.append(name)
        guard let data = responses[name] else { throw EdgeFunctionError.notConfigured }
        return try JSONDecoder().decode(T.self, from: data)
    }
}
