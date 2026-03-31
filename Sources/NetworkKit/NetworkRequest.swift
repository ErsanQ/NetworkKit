import Foundation

/// A structured representation of a network request in the ErsanQ ecosystem.
public struct NetworkRequest: Sendable {
    
    /// The relative path of the endpoint (e.g., "/v1/users").
    public let path: String
    /// The HTTP method to use for the request.
    public let method: HTTPMethod
    /// URL query parameters.
    public let queryItems: [URLQueryItem]?
    /// Custom HTTP headers.
    public let headers: [String: String]?
    /// The body data for POST/PUT requests.
    public let body: Data?
    
    /// Creates a new NetworkRequest.
    ///
    /// - Parameters:
    ///   - path: The endpoint path.
    ///   - method: The HTTP verb.
    ///   - queryItems: Optional URL parameters.
    ///   - headers: Optional request headers.
    ///   - body: Optional body data.
    public init(
        path: String,
        method: HTTPMethod = .get,
        queryItems: [URLQueryItem]? = nil,
        headers: [String: String]? = nil,
        body: Data? = nil
    ) {
        self.path = path
        self.method = method
        self.queryItems = queryItems
        self.headers = headers
        self.body = body
    }
    
    /// Internal helper to transform the `NetworkRequest` into a native `URLRequest`.
    func buildURLRequest(with baseURL: URL) throws -> URLRequest {
        var url = baseURL.appendingPathComponent(path)
        
        if let queryItems = queryItems, var components = URLComponents(url: url, resolvingAgainstBaseURL: false) {
            components.queryItems = queryItems
            if let newURL = components.url {
                url = newURL
            }
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = method.rawValue
        request.httpBody = body
        
        headers?.forEach { request.addValue($1, forHTTPHeaderField: $0) }
        
        return request
    }
}

/// Supported HTTP methods for NetworkKit.
public enum HTTPMethod: String, Sendable {
    case get = "GET"
    case post = "POST"
    case put = "PUT"
    case delete = "DELETE"
    case patch = "PATCH"
}
