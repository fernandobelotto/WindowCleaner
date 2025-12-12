import Foundation

// MARK: - Network Error

/// Network-specific errors with user-friendly messages.
///
/// Usage:
/// ```swift
/// do {
///     let user: User = try await HTTP.get("/users/1")
/// } catch let error as NetworkError {
///     print(error.localizedDescription)
/// }
/// ```
enum NetworkError: LocalizedError, Sendable {
    /// The URL string could not be converted to a valid URL
    case invalidURL(String)

    /// No data was received when data was expected
    case noData

    /// Failed to decode the response into the expected type
    case decodingFailed(Error)

    /// Failed to encode the request body
    case encodingFailed(Error)

    /// Server returned a non-2xx status code
    case httpError(statusCode: Int, data: Data?)

    /// The underlying URLSession request failed
    case requestFailed(Error)

    /// Request timed out
    case timeout

    /// No network connection available
    case noConnection

    // MARK: - LocalizedError

    var errorDescription: String? {
        switch self {
        case let .invalidURL(url):
            "Invalid URL: \(url)"
        case .noData:
            "No data received from server"
        case .decodingFailed:
            "Failed to parse server response"
        case .encodingFailed:
            "Failed to encode request data"
        case let .httpError(statusCode, _):
            httpErrorMessage(for: statusCode)
        case .requestFailed:
            "Network request failed"
        case .timeout:
            "Request timed out"
        case .noConnection:
            "No internet connection"
        }
    }

    var recoverySuggestion: String? {
        switch self {
        case .invalidURL:
            "Check that the URL is correctly formatted."
        case .noData:
            "The server may be experiencing issues. Try again later."
        case .decodingFailed:
            "The server response format may have changed."
        case .encodingFailed:
            "Check that your data is correctly formatted."
        case let .httpError(statusCode, _):
            httpRecoverySuggestion(for: statusCode)
        case .requestFailed:
            "Check your internet connection and try again."
        case .timeout:
            "The server is taking too long to respond. Try again later."
        case .noConnection:
            "Please check your internet connection and try again."
        }
    }

    var failureReason: String? {
        switch self {
        case let .decodingFailed(error),
             let .encodingFailed(error),
             let .requestFailed(error):
            return error.localizedDescription
        case let .httpError(_, data):
            if let data, let message = String(data: data, encoding: .utf8) {
                return message
            }
            return nil
        default:
            return nil
        }
    }

    // MARK: - Helpers

    private func httpErrorMessage(for statusCode: Int) -> String {
        switch statusCode {
        case 400:
            "Bad request"
        case 401:
            "Authentication required"
        case 403:
            "Access denied"
        case 404:
            "Resource not found"
        case 409:
            "Conflict with current state"
        case 422:
            "Invalid data provided"
        case 429:
            "Too many requests"
        case 500:
            "Server error"
        case 502:
            "Bad gateway"
        case 503:
            "Service unavailable"
        case 504:
            "Gateway timeout"
        default:
            "Request failed with status \(statusCode)"
        }
    }

    private func httpRecoverySuggestion(for statusCode: Int) -> String {
        switch statusCode {
        case 400, 422:
            "Check your input and try again."
        case 401:
            "Please sign in and try again."
        case 403:
            "You don't have permission to access this resource."
        case 404:
            "The requested resource may have been moved or deleted."
        case 429:
            "Please wait a moment before trying again."
        case 500 ... 599:
            "The server is experiencing issues. Try again later."
        default:
            "Please try again. If the problem persists, contact support."
        }
    }
}

// MARK: - HTTP Status Code Helpers

extension NetworkError {
    /// Whether this error represents an authentication failure
    var isAuthenticationError: Bool {
        if case let .httpError(statusCode, _) = self {
            return statusCode == 401
        }
        return false
    }

    /// Whether this error represents a client error (4xx)
    var isClientError: Bool {
        if case let .httpError(statusCode, _) = self {
            return (400 ... 499).contains(statusCode)
        }
        return false
    }

    /// Whether this error represents a server error (5xx)
    var isServerError: Bool {
        if case let .httpError(statusCode, _) = self {
            return (500 ... 599).contains(statusCode)
        }
        return false
    }

    /// Whether this error is likely transient and worth retrying
    var isRetryable: Bool {
        switch self {
        case .timeout, .noConnection:
            true
        case let .httpError(statusCode, _):
            statusCode == 429 || (500 ... 599).contains(statusCode)
        case .requestFailed:
            true
        default:
            false
        }
    }
}
