import Foundation

// MARK: - HTTPMethod

/// Standard HTTP request methods.
public enum HTTPMethod: String, Sendable {
    case get    = "GET"
    case post   = "POST"
    case put    = "PUT"
    case patch  = "PATCH"
    case delete = "DELETE"
}

// MARK: - NetworkRequest

/// A fully configured HTTP request ready to be executed.
///
/// Build requests using the fluent API, or use ``Network`` for one-liners:
///
/// ```swift
/// // One-liner
/// let user: User = try await Network.get("https://api.example.com/me")
///
/// // Custom request
/// let request = NetworkRequest(url: "https://api.example.com/users")
///     .method(.post)
///     .body(newUser)
///     .header("X-App-Version", value: "1.0")
///     .timeout(30)
/// ```
public struct NetworkRequest: Sendable {

    // MARK: - Properties

    public let urlString: String
    public var method: HTTPMethod = .get
    public var headers: [String: String] = [:]
    public var body: Data?
    public var timeoutInterval: TimeInterval = 30
    public var queryItems: [URLQueryItem] = []

    // MARK: - Init

    public init(url: String) {
        self.urlString = url
    }

    // MARK: - Fluent Builder

    /// Sets the HTTP method.
    public func method(_ method: HTTPMethod) -> NetworkRequest {
        var copy = self; copy.method = method; return copy
    }

    /// Adds a single header.
    public func header(_ key: String, value: String) -> NetworkRequest {
        var copy = self; copy.headers[key] = value; return copy
    }

    /// Sets multiple headers at once.
    public func headers(_ headers: [String: String]) -> NetworkRequest {
        var copy = self
        headers.forEach { copy.headers[$0.key] = $0.value }
        return copy
    }

    /// Sets the request body from a `Codable` object (JSON-encoded).
    public func body<T: Encodable>(_ value: T, encoder: JSONEncoder = .init()) throws -> NetworkRequest {
        var copy = self
        copy.body = try encoder.encode(value)
        copy.headers["Content-Type"] = "application/json"
        return copy
    }

    /// Sets the request body from raw `Data`.
    public func body(_ data: Data) -> NetworkRequest {
        var copy = self; copy.body = data; return copy
    }

    /// Adds a URL query parameter.
    public func query(_ key: String, value: String) -> NetworkRequest {
        var copy = self
        copy.queryItems.append(URLQueryItem(name: key, value: value))
        return copy
    }

    /// Sets the request timeout in seconds.
    public func timeout(_ seconds: TimeInterval) -> NetworkRequest {
        var copy = self; copy.timeoutInterval = seconds; return copy
    }

    // MARK: - Build URLRequest

    func buildURLRequest() throws -> URLRequest {
        guard var components = URLComponents(string: urlString) else {
            throw NetworkError.invalidURL(urlString)
        }

        if !queryItems.isEmpty {
            components.queryItems = (components.queryItems ?? []) + queryItems
        }

        guard let url = components.url else {
            throw NetworkError.invalidURL(urlString)
        }

        var request = URLRequest(url: url, timeoutInterval: timeoutInterval)
        request.httpMethod = method.rawValue
        request.httpBody = body

        // Default headers
        if headers["Accept"] == nil {
            request.setValue("application/json", forHTTPHeaderField: "Accept")
        }

        headers.forEach { request.setValue($0.value, forHTTPHeaderField: $0.key) }

        return request
    }
}
