import Foundation

// MARK: - HTTP Method

/// HTTP methods for network requests.
///
/// Usage:
/// ```swift
/// let method: HTTPMethod = .post
/// print(method.rawValue) // "POST"
/// ```
enum HTTPMethod: String, Sendable {
    case get = "GET"
    case post = "POST"
    case put = "PUT"
    case patch = "PATCH"
    case delete = "DELETE"
    case head = "HEAD"
    case options = "OPTIONS"
}
