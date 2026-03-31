import Foundation

/// A high-performance, asynchronous network client designed for the ErsanQ ecosystem.
///
/// `NetworkClient` provides a type-safe way to perform RESTful API requests using
/// modern Swift concurrency features. It handles request encoding, response decoding,
/// and error mapping automatically.
///
/// ## Usage
/// ```swift
/// let client = NetworkClient(baseURL: URL(string: "https://api.example.com")!)
/// let user: User = try await client.execute(.getUser(id: 123))
/// ```
public final class NetworkClient: Sendable {
    
    /// The base URL prepended to all relative request paths.
    public let baseURL: URL
    private let session: URLSession
    private let decoder: JSONDecoder
    
    /// Creates a new NetworkClient instance.
    ///
    /// - Parameters:
    ///   - baseURL: The root URL for all requests.
    ///   - session: An optional custom `URLSession`. Defaults to `.shared`.
    ///   - decoder: An optional custom `JSONDecoder`. Defaults to a standard decoder.
    public init(baseURL: URL, session: URLSession = .shared, decoder: JSONDecoder = JSONDecoder()) {
        self.baseURL = baseURL
        self.session = session
        self.decoder = decoder
    }
    
    /// Executes a network request and decodes the response into a specified type.
    ///
    /// - Parameter request: A `NetworkRequest` object defining the endpoint and parameters.
    /// - Returns: A decoded instance of the generic type `T`.
    /// - Throws: `NetworkError` if the request fails or decoding fails.
    public func execute<T: Decodable>(_ request: NetworkRequest) async throws -> T {
        let urlRequest = try request.buildURLRequest(with: baseURL)
        
        let (data, response) = try await session.data(for: urlRequest)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw NetworkError.invalidResponse
        }
        
        guard (200...299).contains(httpResponse.statusCode) else {
            throw NetworkError.httpError(httpResponse.statusCode)
        }
        
        do {
            return try decoder.decode(T.self, from: data)
        } catch {
            throw NetworkError.decodingError(error)
        }
    }
}
