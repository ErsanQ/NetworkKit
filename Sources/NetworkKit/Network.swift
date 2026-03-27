import Foundation

// MARK: - Network (Static API)

/// A static interface to the shared ``NetworkClient``.
///
/// Perfect for quick requests without setup:
///
/// ```swift
/// // GET — decode response
/// let users: [User] = try await Network.get("https://api.example.com/users")
///
/// // POST — with body
/// let post: Post = try await Network.post("https://api.example.com/posts", body: newPost)
///
/// // Custom request
/// let response = try await Network.response(for:
///     NetworkRequest(url: "https://api.example.com/upload")
///         .method(.post)
///         .header("Authorization", value: "Bearer \(token)")
///         .body(data)
///         .timeout(60)
/// )
/// ```
///
/// For multiple requests to the same API, configure a dedicated client:
/// ```swift
/// let api = NetworkClient(baseURL: "https://api.example.com")
/// api.defaultHeaders["Authorization"] = "Bearer \(token)"
///
/// let me: User = try await api.get("/me")
/// ```
public enum Network {

    /// The shared client used by all static methods.
    ///
    /// Configure this once at app startup:
    /// ```swift
    /// Network.shared.defaultHeaders["Authorization"] = "Bearer \(token)"
    /// ```
    public static let shared = NetworkClient()

    // MARK: - GET

    /// Sends a GET request and decodes the response.
    public static func get<T: Decodable>(
        _ url: String,
        query: [String: String] = [:]
    ) async throws -> T {
        try await shared.get(url, query: query)
    }

    // MARK: - POST

    /// Sends a POST request with a JSON-encoded body and decodes the response.
    public static func post<Body: Encodable, Response: Decodable>(
        _ url: String,
        body: Body
    ) async throws -> Response {
        try await shared.post(url, body: body)
    }

    /// Sends a POST request and discards the response.
    public static func post<Body: Encodable>(_ url: String, body: Body) async throws {
        try await shared.post(url, body: body)
    }

    // MARK: - PUT

    /// Sends a PUT request with a JSON-encoded body and decodes the response.
    public static func put<Body: Encodable, Response: Decodable>(
        _ url: String,
        body: Body
    ) async throws -> Response {
        try await shared.put(url, body: body)
    }

    // MARK: - PATCH

    /// Sends a PATCH request with a JSON-encoded body and decodes the response.
    public static func patch<Body: Encodable, Response: Decodable>(
        _ url: String,
        body: Body
    ) async throws -> Response {
        try await shared.patch(url, body: body)
    }

    // MARK: - DELETE

    /// Sends a DELETE request.
    public static func delete(_ url: String) async throws {
        try await shared.delete(url)
    }

    // MARK: - Custom Request

    /// Executes a custom ``NetworkRequest`` and returns the full ``NetworkResponse``.
    public static func response(for request: NetworkRequest) async throws -> NetworkResponse {
        try await shared.response(for: request)
    }
}
