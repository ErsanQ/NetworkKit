import Foundation

// MARK: - NetworkResponse

/// The raw response from a network request.
///
/// Returned when you need access to headers or status code alongside the body:
///
/// ```swift
/// let response = try await Network.response(for: request)
/// print(response.statusCode)           // 200
/// print(response.headers["ETag"])      // "abc123"
/// let user = try response.decode(User.self)
/// ```
public struct NetworkResponse: Sendable {

    /// The HTTP status code (e.g. 200, 404).
    public let statusCode: Int

    /// The raw response body.
    public let data: Data

    /// The response headers.
    public let headers: [String: String]

    // MARK: - Convenience

    /// Returns `true` for 2xx status codes.
    public var isSuccess: Bool { (200..<300).contains(statusCode) }

    /// Decodes the response body into the given `Decodable` type.
    public func decode<T: Decodable>(_ type: T.Type, decoder: JSONDecoder = .init()) throws -> T {
        do {
            return try decoder.decode(type, from: data)
        } catch {
            throw NetworkError.decodingFailed(error)
        }
    }

    /// Returns the response body as a UTF-8 string.
    public var string: String? {
        String(data: data, encoding: .utf8)
    }
}
