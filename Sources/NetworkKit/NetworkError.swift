import Foundation

/// The types of errors that can occur during network operations in the ErsanQ ecosystem.
public enum NetworkError: Error, Sendable {
    /// The server's response was not in a valid HTTP format.
    case invalidResponse
    /// A non-2xx HTTP status code was returned.
    case httpError(Int)
    /// The received data could not be decoded into the expected type.
    case decodingError(Error)
    /// An underlying system error (e.g., connection timed out).
    case underlying(Error)
}

extension NetworkError: LocalizedError {
    public var errorDescription: String? {
        switch self {
        case .invalidResponse:
            return "The server returned an invalid response."
        case .httpError(let code):
            return "The server returned an HTTP error: \(code)."
        case .decodingError:
            return "Failed to decode the server response."
        case .underlying(let error):
            return error.localizedDescription
        }
    }
}
