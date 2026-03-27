import Foundation

// MARK: - NetworkClient

/// The configurable HTTP client that executes requests.
///
/// Use the shared ``Network`` singleton for most cases,
/// or create a custom `NetworkClient` for specific base URLs or auth headers:
///
/// ```swift
/// let api = NetworkClient(baseURL: "https://api.example.com")
/// api.defaultHeaders["Authorization"] = "Bearer \(token)"
///
/// let user: User = try await api.get("/me")
/// let posts: [Post] = try await api.get("/posts", query: ["page": "1"])
/// try await api.post("/posts", body: newPost)
/// ```
public final class NetworkClient: @unchecked Sendable {

    // MARK: - Properties

    /// Optional base URL prepended to all relative paths.
    public var baseURL: String?

    /// Headers added to every request automatically.
    public var defaultHeaders: [String: String] = [:]

    /// Default timeout for all requests. Defaults to `30` seconds.
    public var defaultTimeout: TimeInterval = 30

    private let session: URLSession
    private let decoder: JSONDecoder
    private let encoder: JSONEncoder

    // MARK: - Init

    public init(
        baseURL: String? = nil,
        session: URLSession = .shared,
        decoder: JSONDecoder = .init(),
        encoder: JSONEncoder = .init()
    ) {
        self.baseURL = baseURL
        self.session = session
        self.decoder = decoder
        self.encoder = encoder
    }

    // MARK: - Execute: Decodable Response

    /// Sends a request and decodes the response body into `T`.
    public func send<T: Decodable>(_ request: NetworkRequest) async throws -> T {
        let response = try await execute(request)
        return try response.decode(T.self, decoder: decoder)
    }

    /// Sends a request and discards the response body.
    public func send(_ request: NetworkRequest) async throws {
        _ = try await execute(request)
    }

    // MARK: - Execute: Raw Response

    /// Sends a request and returns the full ``NetworkResponse``.
    public func response(for request: NetworkRequest) async throws -> NetworkResponse {
        try await execute(request)
    }

    // MARK: - Convenience: GET

    /// Sends a GET request and decodes the response.
    ///
    /// ```swift
    /// let users: [User] = try await client.get("/users")
    /// let user: User = try await client.get("/users/42")
    /// ```
    public func get<T: Decodable>(_ path: String, query: [String: String] = [:]) async throws -> T {
        var request = NetworkRequest(url: resolve(path))
        query.forEach { request = request.query($0.key, value: $0.value) }
        return try await send(request)
    }

    /// Sends a GET request and discards the response.
    public func get(_ path: String) async throws {
        let request = NetworkRequest(url: resolve(path))
        try await send(request)
    }

    // MARK: - Convenience: POST

    /// Sends a POST request with a JSON-encoded body and decodes the response.
    ///
    /// ```swift
    /// let created: Post = try await client.post("/posts", body: newPost)
    /// ```
    public func post<Body: Encodable, Response: Decodable>(
        _ path: String,
        body: Body
    ) async throws -> Response {
        let request = try NetworkRequest(url: resolve(path))
            .method(.post)
            .body(body, encoder: encoder)
        return try await send(request)
    }

    /// Sends a POST request and discards the response.
    public func post<Body: Encodable>(_ path: String, body: Body) async throws {
        let request = try NetworkRequest(url: resolve(path))
            .method(.post)
            .body(body, encoder: encoder)
        try await send(request)
    }

    // MARK: - Convenience: PUT

    /// Sends a PUT request with a JSON-encoded body and decodes the response.
    public func put<Body: Encodable, Response: Decodable>(
        _ path: String,
        body: Body
    ) async throws -> Response {
        let request = try NetworkRequest(url: resolve(path))
            .method(.put)
            .body(body, encoder: encoder)
        return try await send(request)
    }

    // MARK: - Convenience: PATCH

    /// Sends a PATCH request with a JSON-encoded body and decodes the response.
    public func patch<Body: Encodable, Response: Decodable>(
        _ path: String,
        body: Body
    ) async throws -> Response {
        let request = try NetworkRequest(url: resolve(path))
            .method(.patch)
            .body(body, encoder: encoder)
        return try await send(request)
    }

    // MARK: - Convenience: DELETE

    /// Sends a DELETE request and discards the response.
    public func delete(_ path: String) async throws {
        let request = NetworkRequest(url: resolve(path)).method(.delete)
        try await send(request)
    }

    // MARK: - Private

    private func resolve(_ path: String) -> String {
        if path.hasPrefix("http") { return path }
        return (baseURL ?? "") + path
    }

    private func execute(_ request: NetworkRequest) async throws -> NetworkResponse {
        var urlRequest = try request.buildURLRequest()

        // Merge default headers
        defaultHeaders.forEach {
            if urlRequest.value(forHTTPHeaderField: $0.key) == nil {
                urlRequest.setValue($0.value, forHTTPHeaderField: $0.key)
            }
        }

        // Set default timeout
        if urlRequest.timeoutInterval == 30 {
            urlRequest.timeoutInterval = defaultTimeout
        }

        let (data, urlResponse): (Data, URLResponse)
        do {
            (data, urlResponse) = try await session.data(for: urlRequest)
        } catch let error as URLError {
            switch error.code {
            case .notConnectedToInternet, .networkConnectionLost:
                throw NetworkError.noConnection
            case .timedOut:
                throw NetworkError.timeout
            default:
                throw NetworkError.underlying(error)
            }
        }

        guard let http = urlResponse as? HTTPURLResponse else {
            throw NetworkError.underlying(URLError(.badServerResponse))
        }

        // Map status codes to errors
        switch http.statusCode {
        case 200..<300:
            break
        case 401:
            throw NetworkError.unauthorized
        case 403:
            throw NetworkError.forbidden
        case 404:
            throw NetworkError.notFound
        case 500..<600:
            throw NetworkError.serverError(statusCode: http.statusCode)
        default:
            throw NetworkError.unexpectedStatusCode(http.statusCode)
        }

        let headers = http.allHeaderFields.reduce(into: [String: String]()) {
            if let key = $1.key as? String, let value = $1.value as? String {
                $0[key] = value
            }
        }

        return NetworkResponse(statusCode: http.statusCode, data: data, headers: headers)
    }
}
