import Foundation
import os

// MARK: - HTTP Client

/// A lightweight, async/await HTTP client inspired by Alamofire and Axios.
///
/// Usage:
/// ```swift
/// // Simple GET request
/// let users: [User] = try await HTTP.get("https://api.example.com/users")
///
/// // POST with JSON body
/// let created: User = try await HTTP.post("/users", body: newUser)
///
/// // Configured client with base URL and auth
/// let client = HTTPClient(baseURL: "https://api.example.com", bearerToken: "token123")
/// let data: MyData = try await client.get("/endpoint")
/// ```
final class HTTPClient: Sendable {
    // MARK: - Configuration

    /// Base URL prepended to relative paths
    let baseURL: String?

    /// Bearer token for Authorization header
    let bearerToken: String?

    /// Default headers included in every request
    let defaultHeaders: [String: String]

    /// Request timeout interval in seconds
    let timeoutInterval: TimeInterval

    /// JSON decoder configured for the client
    let decoder: JSONDecoder

    /// JSON encoder configured for the client
    let encoder: JSONEncoder

    /// URLSession used for requests
    private let session: URLSession

    // MARK: - Initialization

    /// Creates a new HTTP client with the specified configuration.
    /// - Parameters:
    ///   - baseURL: Base URL prepended to relative paths (optional)
    ///   - bearerToken: Bearer token for Authorization header (optional)
    ///   - defaultHeaders: Headers included in every request (default: Accept: application/json)
    ///   - timeoutInterval: Request timeout in seconds (default: 30)
    ///   - decoder: JSON decoder to use (default: configured for snake_case conversion)
    ///   - encoder: JSON encoder to use (default: configured for snake_case conversion)
    ///   - session: URLSession to use (default: shared session)
    init(
        baseURL: String? = nil,
        bearerToken: String? = nil,
        defaultHeaders: [String: String] = ["Accept": "application/json"],
        timeoutInterval: TimeInterval = 30,
        decoder: JSONDecoder? = nil,
        encoder: JSONEncoder? = nil,
        session: URLSession = .shared
    ) {
        self.baseURL = baseURL
        self.bearerToken = bearerToken
        self.defaultHeaders = defaultHeaders
        self.timeoutInterval = timeoutInterval
        self.session = session

        // Configure decoder
        let jsonDecoder = decoder ?? JSONDecoder()
        if decoder == nil {
            jsonDecoder.keyDecodingStrategy = .convertFromSnakeCase
            jsonDecoder.dateDecodingStrategy = .iso8601
        }
        self.decoder = jsonDecoder

        // Configure encoder
        let jsonEncoder = encoder ?? JSONEncoder()
        if encoder == nil {
            jsonEncoder.keyEncodingStrategy = .convertToSnakeCase
            jsonEncoder.dateEncodingStrategy = .iso8601
        }
        self.encoder = jsonEncoder
    }

    // MARK: - Convenience Methods

    /// Performs a GET request.
    /// - Parameters:
    ///   - path: URL path or full URL
    ///   - queryItems: Query parameters
    ///   - headers: Additional headers
    /// - Returns: Decoded response of type T
    func get<T: Decodable>(
        _ path: String,
        queryItems: [String: String] = [:],
        headers: [String: String] = [:]
    ) async throws -> T {
        try await request(path, method: .get, queryItems: queryItems, headers: headers)
    }

    /// Performs a POST request.
    /// - Parameters:
    ///   - path: URL path or full URL
    ///   - body: Request body to encode as JSON
    ///   - headers: Additional headers
    /// - Returns: Decoded response of type T
    func post<T: Decodable>(
        _ path: String,
        body: some Encodable,
        headers: [String: String] = [:]
    ) async throws -> T {
        try await request(path, method: .post, body: body, headers: headers)
    }

    /// Performs a POST request without a body.
    /// - Parameters:
    ///   - path: URL path or full URL
    ///   - headers: Additional headers
    /// - Returns: Decoded response of type T
    func post<T: Decodable>(
        _ path: String,
        headers: [String: String] = [:]
    ) async throws -> T {
        try await request(path, method: .post, headers: headers)
    }

    /// Performs a PUT request.
    /// - Parameters:
    ///   - path: URL path or full URL
    ///   - body: Request body to encode as JSON
    ///   - headers: Additional headers
    /// - Returns: Decoded response of type T
    func put<T: Decodable>(
        _ path: String,
        body: some Encodable,
        headers: [String: String] = [:]
    ) async throws -> T {
        try await request(path, method: .put, body: body, headers: headers)
    }

    /// Performs a PATCH request.
    /// - Parameters:
    ///   - path: URL path or full URL
    ///   - body: Request body to encode as JSON
    ///   - headers: Additional headers
    /// - Returns: Decoded response of type T
    func patch<T: Decodable>(
        _ path: String,
        body: some Encodable,
        headers: [String: String] = [:]
    ) async throws -> T {
        try await request(path, method: .patch, body: body, headers: headers)
    }

    /// Performs a DELETE request.
    /// - Parameters:
    ///   - path: URL path or full URL
    ///   - headers: Additional headers
    /// - Returns: Decoded response of type T
    func delete<T: Decodable>(
        _ path: String,
        headers: [String: String] = [:]
    ) async throws -> T {
        try await request(path, method: .delete, headers: headers)
    }

    /// Performs a DELETE request without expecting a response body.
    /// - Parameters:
    ///   - path: URL path or full URL
    ///   - headers: Additional headers
    func delete(
        _ path: String,
        headers: [String: String] = [:]
    ) async throws {
        let _: EmptyResponse = try await request(path, method: .delete, headers: headers)
    }

    // MARK: - Core Request Method

    /// Performs an HTTP request with full configuration.
    /// - Parameters:
    ///   - path: URL path or full URL
    ///   - method: HTTP method
    ///   - queryItems: Query parameters
    ///   - body: Request body to encode (optional)
    ///   - headers: Additional headers
    /// - Returns: Decoded response of type T
    func request<T: Decodable>(
        _ path: String,
        method: HTTPMethod,
        queryItems: [String: String] = [:],
        body: (some Encodable)? = nil,
        headers: [String: String] = [:]
    ) async throws -> T {
        let urlRequest = try buildRequest(
            path: path,
            method: method,
            queryItems: queryItems,
            body: body,
            headers: headers
        )

        return try await execute(urlRequest)
    }

    /// Performs an HTTP request without a body.
    func request<T: Decodable>(
        _ path: String,
        method: HTTPMethod,
        queryItems: [String: String] = [:],
        headers: [String: String] = [:]
    ) async throws -> T {
        let urlRequest = try buildRequest(
            path: path,
            method: method,
            queryItems: queryItems,
            body: EmptyBody?.none,
            headers: headers
        )

        return try await execute(urlRequest)
    }

    // MARK: - Request Building

    private func buildRequest(
        path: String,
        method: HTTPMethod,
        queryItems: [String: String],
        body: (some Encodable)?,
        headers: [String: String]
    ) throws -> URLRequest {
        // Build URL
        let urlString = buildURLString(path: path)
        guard var components = URLComponents(string: urlString) else {
            throw NetworkError.invalidURL(urlString)
        }

        // Add query items
        if !queryItems.isEmpty {
            components.queryItems = queryItems.map { URLQueryItem(name: $0.key, value: $0.value) }
        }

        guard let url = components.url else {
            throw NetworkError.invalidURL(urlString)
        }

        // Build request
        var request = URLRequest(url: url)
        request.httpMethod = method.rawValue
        request.timeoutInterval = timeoutInterval

        // Add default headers
        for (key, value) in defaultHeaders {
            request.setValue(value, forHTTPHeaderField: key)
        }

        // Add bearer token
        if let bearerToken {
            request.setValue("Bearer \(bearerToken)", forHTTPHeaderField: "Authorization")
        }

        // Add custom headers
        for (key, value) in headers {
            request.setValue(value, forHTTPHeaderField: key)
        }

        // Encode body
        if let body {
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            do {
                request.httpBody = try encoder.encode(body)
            } catch {
                throw NetworkError.encodingFailed(error)
            }
        }

        return request
    }

    private func buildURLString(path: String) -> String {
        // If path is already a full URL, use it directly
        if path.hasPrefix("http://") || path.hasPrefix("https://") {
            return path
        }

        // Otherwise, prepend base URL
        guard let baseURL else {
            return path
        }

        let base = baseURL.hasSuffix("/") ? String(baseURL.dropLast()) : baseURL
        let relativePath = path.hasPrefix("/") ? path : "/\(path)"
        return base + relativePath
    }

    // MARK: - Request Execution

    private func execute<T: Decodable>(_ request: URLRequest) async throws -> T {
        let startTime = Date()

        Log.network.debug("→ \(request.httpMethod ?? "?") \(request.url?.absoluteString ?? "?")")

        let data: Data
        let response: URLResponse

        do {
            (data, response) = try await session.data(for: request)
        } catch let error as URLError {
            Log.network.error("✗ Request failed: \(error.localizedDescription)")
            throw mapURLError(error)
        } catch {
            Log.network.error("✗ Request failed: \(error.localizedDescription)")
            throw NetworkError.requestFailed(error)
        }

        guard let httpResponse = response as? HTTPURLResponse else {
            throw NetworkError.requestFailed(
                NSError(domain: "HTTPClient", code: -1, userInfo: [
                    NSLocalizedDescriptionKey: "Invalid response type",
                ])
            )
        }

        let duration = Date().timeIntervalSince(startTime) * 1000
        Log.network.debug("← \(httpResponse.statusCode) (\(String(format: "%.0f", duration))ms)")

        // Check status code
        guard (200 ... 299).contains(httpResponse.statusCode) else {
            Log.network.error("✗ HTTP \(httpResponse.statusCode)")
            throw NetworkError.httpError(statusCode: httpResponse.statusCode, data: data)
        }

        // Handle empty response
        if data.isEmpty {
            if T.self == EmptyResponse.self {
                // swiftlint:disable:next force_cast
                return EmptyResponse() as! T
            }
            throw NetworkError.noData
        }

        // Decode response
        do {
            return try decoder.decode(T.self, from: data)
        } catch {
            Log.network.error("✗ Decoding failed: \(error.localizedDescription)")
            throw NetworkError.decodingFailed(error)
        }
    }

    private func mapURLError(_ error: URLError) -> NetworkError {
        switch error.code {
        case .timedOut:
            .timeout
        case .notConnectedToInternet, .networkConnectionLost:
            .noConnection
        default:
            .requestFailed(error)
        }
    }
}

// MARK: - Empty Types

/// Represents an empty request body
private struct EmptyBody: Encodable {}

/// Represents an empty response body
struct EmptyResponse: Decodable {}

// MARK: - Global Convenience (HTTP Typealias)

/// Global HTTP client for simple requests without configuration.
///
/// Usage:
/// ```swift
/// let users: [User] = try await HTTP.get("https://api.example.com/users")
/// ```
enum HTTP {
    /// Shared client instance for simple requests
    private static let shared = HTTPClient()

    /// Performs a GET request.
    static func get<T: Decodable>(
        _ path: String,
        queryItems: [String: String] = [:],
        headers: [String: String] = [:]
    ) async throws -> T {
        try await shared.get(path, queryItems: queryItems, headers: headers)
    }

    /// Performs a POST request with a body.
    static func post<T: Decodable>(
        _ path: String,
        body: some Encodable,
        headers: [String: String] = [:]
    ) async throws -> T {
        try await shared.post(path, body: body, headers: headers)
    }

    /// Performs a POST request without a body.
    static func post<T: Decodable>(
        _ path: String,
        headers: [String: String] = [:]
    ) async throws -> T {
        try await shared.post(path, headers: headers)
    }

    /// Performs a PUT request.
    static func put<T: Decodable>(
        _ path: String,
        body: some Encodable,
        headers: [String: String] = [:]
    ) async throws -> T {
        try await shared.put(path, body: body, headers: headers)
    }

    /// Performs a PATCH request.
    static func patch<T: Decodable>(
        _ path: String,
        body: some Encodable,
        headers: [String: String] = [:]
    ) async throws -> T {
        try await shared.patch(path, body: body, headers: headers)
    }

    /// Performs a DELETE request.
    static func delete<T: Decodable>(
        _ path: String,
        headers: [String: String] = [:]
    ) async throws -> T {
        try await shared.delete(path, headers: headers)
    }

    /// Performs a DELETE request without expecting a response body.
    static func delete(
        _ path: String,
        headers: [String: String] = [:]
    ) async throws {
        try await shared.delete(path, headers: headers)
    }
}

// MARK: - HTTPClient Builder Pattern

extension HTTPClient {
    /// Creates a new client with an updated bearer token.
    /// - Parameter token: The new bearer token
    /// - Returns: A new HTTPClient instance with the updated token
    func withBearerToken(_ token: String?) -> HTTPClient {
        HTTPClient(
            baseURL: baseURL,
            bearerToken: token,
            defaultHeaders: defaultHeaders,
            timeoutInterval: timeoutInterval,
            decoder: decoder,
            encoder: encoder,
            session: session
        )
    }

    /// Creates a new client with additional default headers.
    /// - Parameter headers: Headers to merge with existing defaults
    /// - Returns: A new HTTPClient instance with the updated headers
    func withHeaders(_ headers: [String: String]) -> HTTPClient {
        var mergedHeaders = defaultHeaders
        for (key, value) in headers {
            mergedHeaders[key] = value
        }
        return HTTPClient(
            baseURL: baseURL,
            bearerToken: bearerToken,
            defaultHeaders: mergedHeaders,
            timeoutInterval: timeoutInterval,
            decoder: decoder,
            encoder: encoder,
            session: session
        )
    }
}
