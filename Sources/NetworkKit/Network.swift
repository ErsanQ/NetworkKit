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
    public static let shared = NetworkClient(baseURL: URL(string: "http://localhost")!)

    // MARK: - GET

    /// Sends a GET request and decodes the response.
    public static func get<T: Decodable>(
        _ url: String,
        query: [String: String] = [:]
    ) async throws -> T {
        let request = NetworkRequest(
            path: url,
            method: .get,
            queryItems: query.map { URLQueryItem(name: $0.key, value: $0.value) }
        )
        return try await shared.execute(request)
    }

    // MARK: - POST

    /// Sends a POST request with a JSON-encoded body and decodes the response.
    public static func post<Body: Encodable, Response: Decodable>(
        _ url: String,
        body: Body
    ) async throws -> Response {
        let data = try JSONEncoder().encode(body)
        let request = NetworkRequest(path: url, method: .post, body: data)
        return try await shared.execute(request)
    }

    /// Sends a POST request and discards the response.
    public static func post<Body: Encodable>(_ url: String, body: Body) async throws {
        let _: EmptyResponse = try await post(url, body: body)
    }

    // MARK: - PUT

    /// Sends a PUT request with a JSON-encoded body and decodes the response.
    public static func put<Body: Encodable, Response: Decodable>(
        _ url: String,
        body: Body
    ) async throws -> Response {
        let data = try JSONEncoder().encode(body)
        let request = NetworkRequest(path: url, method: .put, body: data)
        return try await shared.execute(request)
    }

    // MARK: - PATCH

    /// Sends a PATCH request with a JSON-encoded body and decodes the response.
    public static func patch<Body: Encodable, Response: Decodable>(
        _ url: String,
        body: Body
    ) async throws -> Response {
        let data = try JSONEncoder().encode(body)
        let request = NetworkRequest(path: url, method: .patch, body: data)
        return try await shared.execute(request)
    }

    // MARK: - DELETE

    /// Sends a DELETE request.
    public static func delete(_ url: String) async throws {
        let request = NetworkRequest(path: url, method: .delete)
        let _: EmptyResponse = try await shared.execute(request)
    }

    // MARK: - Custom Request

    /// Executes a custom ``NetworkRequest`` and returns the full ``NetworkResponse``.
    public static func response(for request: NetworkRequest) async throws -> NetworkResponse {
        let urlRequest = try request.buildURLRequest(with: shared.baseURL)
        let (data, response) = try await URLSession.shared.data(for: urlRequest)
        guard let http = response as? HTTPURLResponse else { throw NetworkError.invalidResponse }
        return NetworkResponse(statusCode: http.statusCode, data: data, headers: http.allHeaderFields.reduce(into: [:]) { partial, item in
            if let key = item.key as? String, let value = item.value as? String {
                partial[key] = value
            }
        })
    }
}

private struct EmptyResponse: Codable {}
