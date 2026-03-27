import Foundation

// MARK: - NetworkError

/// Describes errors that can occur during a network request.
///
/// ```swift
/// do {
///     let user: User = try await Network.get("https://api.example.com/me")
/// } catch NetworkError.unauthorized {
///     redirectToLogin()
/// } catch NetworkError.noConnection {
///     showOfflineBanner()
/// } catch {
///     print(error.localizedDescription)
/// }
/// ```
public enum NetworkError: LocalizedError, Sendable {

    /// No internet connection is available.
    case noConnection

    /// The server returned a 401 Unauthorized response.
    case unauthorized

    /// The server returned a 403 Forbidden response.
    case forbidden

    /// The requested resource was not found (404).
    case notFound

    /// The server returned a 5xx error.
    case serverError(statusCode: Int)

    /// The server returned an unexpected HTTP status code.
    case unexpectedStatusCode(Int)

    /// The response data could not be decoded into the expected type.
    case decodingFailed(Error)

    /// The request could not be encoded.
    case encodingFailed(Error)

    /// The URL string is malformed.
    case invalidURL(String)

    /// The request timed out.
    case timeout

    /// An underlying URLSession error.
    case underlying(Error)

    // MARK: - LocalizedError

    public var errorDescription: String? {
        switch self {
        case .noConnection:              return "No internet connection."
        case .unauthorized:              return "Authentication required (401)."
        case .forbidden:                 return "Access denied (403)."
        case .notFound:                  return "Resource not found (404)."
        case .serverError(let code):     return "Server error (\(code))."
        case .unexpectedStatusCode(let code): return "Unexpected status code: \(code)."
        case .decodingFailed(let error): return "Decoding failed: \(error.localizedDescription)"
        case .encodingFailed(let error): return "Encoding failed: \(error.localizedDescription)"
        case .invalidURL(let url):       return "Invalid URL: \(url)"
        case .timeout:                   return "The request timed out."
        case .underlying(let error):     return error.localizedDescription
        }
    }
}
