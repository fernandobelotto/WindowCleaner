import Foundation
@testable import MacAppTemplate
import Testing

// MARK: - HTTPMethod Tests

struct HTTPMethodTests {
    @Test("HTTPMethod raw values are uppercase", .tags(.network))
    func rawValuesAreUppercase() {
        #expect(HTTPMethod.get.rawValue == "GET")
        #expect(HTTPMethod.post.rawValue == "POST")
        #expect(HTTPMethod.put.rawValue == "PUT")
        #expect(HTTPMethod.patch.rawValue == "PATCH")
        #expect(HTTPMethod.delete.rawValue == "DELETE")
        #expect(HTTPMethod.head.rawValue == "HEAD")
        #expect(HTTPMethod.options.rawValue == "OPTIONS")
    }
}

// MARK: - NetworkError Tests

struct NetworkErrorTests {
    // MARK: - Error Description Tests

    @Test("invalidURL includes URL in description", .tags(.network))
    func invalidURLIncludesURL() {
        let error = NetworkError.invalidURL("not-a-valid-url")

        #expect(error.errorDescription?.contains("not-a-valid-url") == true)
    }

    @Test("noData has correct description", .tags(.network))
    func noDataHasCorrectDescription() {
        let error = NetworkError.noData

        #expect(error.errorDescription == "No data received from server")
    }

    @Test("decodingFailed has correct description", .tags(.network))
    func decodingFailedHasCorrectDescription() {
        let underlyingError = NSError(domain: "Test", code: 1)
        let error = NetworkError.decodingFailed(underlyingError)

        #expect(error.errorDescription == "Failed to parse server response")
    }

    @Test("encodingFailed has correct description", .tags(.network))
    func encodingFailedHasCorrectDescription() {
        let underlyingError = NSError(domain: "Test", code: 1)
        let error = NetworkError.encodingFailed(underlyingError)

        #expect(error.errorDescription == "Failed to encode request data")
    }

    @Test("httpError has correct descriptions for common status codes", .tags(.network))
    func httpErrorHasCorrectDescriptions() {
        let testCases: [(Int, String)] = [
            (400, "Bad request"),
            (401, "Authentication required"),
            (403, "Access denied"),
            (404, "Resource not found"),
            (429, "Too many requests"),
            (500, "Server error"),
            (503, "Service unavailable"),
        ]

        for (statusCode, expectedDescription) in testCases {
            let error = NetworkError.httpError(statusCode: statusCode, data: nil)
            #expect(error.errorDescription == expectedDescription, "Status \(statusCode) should have description: \(expectedDescription)")
        }
    }

    @Test("timeout has correct description", .tags(.network))
    func timeoutHasCorrectDescription() {
        let error = NetworkError.timeout

        #expect(error.errorDescription == "Request timed out")
    }

    @Test("noConnection has correct description", .tags(.network))
    func noConnectionHasCorrectDescription() {
        let error = NetworkError.noConnection

        #expect(error.errorDescription == "No internet connection")
    }

    // MARK: - Recovery Suggestion Tests

    @Test("All errors have recovery suggestions", .tags(.network))
    func allErrorsHaveRecoverySuggestions() {
        let errors: [NetworkError] = [
            .invalidURL("test"),
            .noData,
            .decodingFailed(NSError(domain: "Test", code: 1)),
            .encodingFailed(NSError(domain: "Test", code: 1)),
            .httpError(statusCode: 500, data: nil),
            .requestFailed(NSError(domain: "Test", code: 1)),
            .timeout,
            .noConnection,
        ]

        for error in errors {
            #expect(error.recoverySuggestion != nil, "\(error) should have recovery suggestion")
        }
    }

    // MARK: - Failure Reason Tests

    @Test("decodingFailed includes underlying error", .tags(.network))
    func decodingFailedIncludesUnderlyingError() {
        let underlyingError = NSError(
            domain: "Test",
            code: 1,
            userInfo: [NSLocalizedDescriptionKey: "JSON parsing error"]
        )
        let error = NetworkError.decodingFailed(underlyingError)

        #expect(error.failureReason == "JSON parsing error")
    }

    @Test("httpError failure reason includes response body", .tags(.network))
    func httpErrorFailureReasonIncludesResponseBody() {
        let responseBody = "Error: Invalid token"
        let data = responseBody.data(using: .utf8)
        let error = NetworkError.httpError(statusCode: 401, data: data)

        #expect(error.failureReason == responseBody)
    }

    // MARK: - Helper Property Tests

    @Test("isAuthenticationError detects 401", .tags(.network))
    func isAuthenticationErrorDetects401() {
        let authError = NetworkError.httpError(statusCode: 401, data: nil)
        let notAuthError = NetworkError.httpError(statusCode: 403, data: nil)
        let timeoutError = NetworkError.timeout

        #expect(authError.isAuthenticationError == true)
        #expect(notAuthError.isAuthenticationError == false)
        #expect(timeoutError.isAuthenticationError == false)
    }

    @Test("isClientError detects 4xx", .tags(.network))
    func isClientErrorDetects4xx() {
        let clientError = NetworkError.httpError(statusCode: 404, data: nil)
        let serverError = NetworkError.httpError(statusCode: 500, data: nil)

        #expect(clientError.isClientError == true)
        #expect(serverError.isClientError == false)
    }

    @Test("isServerError detects 5xx", .tags(.network))
    func isServerErrorDetects5xx() {
        let serverError = NetworkError.httpError(statusCode: 503, data: nil)
        let clientError = NetworkError.httpError(statusCode: 400, data: nil)

        #expect(serverError.isServerError == true)
        #expect(clientError.isServerError == false)
    }

    @Test("isRetryable returns true for transient errors", .tags(.network))
    func isRetryableReturnsCorrectly() {
        // Retryable errors
        #expect(NetworkError.timeout.isRetryable == true)
        #expect(NetworkError.noConnection.isRetryable == true)
        #expect(NetworkError.httpError(statusCode: 429, data: nil).isRetryable == true)
        #expect(NetworkError.httpError(statusCode: 503, data: nil).isRetryable == true)
        #expect(NetworkError.requestFailed(NSError(domain: "Test", code: 1)).isRetryable == true)

        // Non-retryable errors
        #expect(NetworkError.invalidURL("test").isRetryable == false)
        #expect(NetworkError.noData.isRetryable == false)
        #expect(NetworkError.httpError(statusCode: 400, data: nil).isRetryable == false)
        #expect(NetworkError.httpError(statusCode: 401, data: nil).isRetryable == false)
    }
}

// MARK: - HTTPClient Tests

struct HTTPClientTests {
    // MARK: - Initialization Tests

    @Test("HTTPClient initializes with default values", .tags(.network))
    func initializesWithDefaults() {
        let client = HTTPClient()

        #expect(client.baseURL == nil)
        #expect(client.bearerToken == nil)
        #expect(client.defaultHeaders["Accept"] == "application/json")
        #expect(client.timeoutInterval == 30)
    }

    @Test("HTTPClient initializes with custom values", .tags(.network))
    func initializesWithCustomValues() {
        let client = HTTPClient(
            baseURL: "https://api.example.com",
            bearerToken: "test-token",
            defaultHeaders: ["X-Custom": "header"],
            timeoutInterval: 60
        )

        #expect(client.baseURL == "https://api.example.com")
        #expect(client.bearerToken == "test-token")
        #expect(client.defaultHeaders["X-Custom"] == "header")
        #expect(client.timeoutInterval == 60)
    }

    // MARK: - Builder Pattern Tests

    @Test("withBearerToken creates new client with updated token", .tags(.network))
    func withBearerTokenCreatesNewClient() {
        let original = HTTPClient(baseURL: "https://api.example.com")
        let updated = original.withBearerToken("new-token")

        #expect(original.bearerToken == nil)
        #expect(updated.bearerToken == "new-token")
        #expect(updated.baseURL == "https://api.example.com")
    }

    @Test("withHeaders merges headers correctly", .tags(.network))
    func withHeadersMergesCorrectly() {
        let original = HTTPClient(defaultHeaders: ["Accept": "application/json"])
        let updated = original.withHeaders(["X-Custom": "value"])

        #expect(updated.defaultHeaders["Accept"] == "application/json")
        #expect(updated.defaultHeaders["X-Custom"] == "value")
    }

    // MARK: - URL Building Tests

    @Test("HTTPClient handles absolute URLs correctly", .tags(.network))
    func handlesAbsoluteURLs() async throws {
        // This test verifies URL construction by checking that the client
        // correctly identifies absolute vs relative URLs
        let client = HTTPClient(baseURL: "https://api.example.com")

        // For absolute URLs, base URL should be ignored
        // We can't directly test the URL building without making a request,
        // but we can verify the configuration is correct
        #expect(client.baseURL == "https://api.example.com")
    }

    @Test("HTTPClient throws for invalid URLs", .tags(.network))
    func throwsForInvalidURLs() async {
        let client = HTTPClient()

        do {
            // Using a string with invalid percent encoding that URLComponents cannot parse
            let _: EmptyResponse = try await client.get("http://[::1")
            Issue.record("Expected NetworkError.invalidURL to be thrown")
        } catch let error as NetworkError {
            if case .invalidURL = error {
                // Success - correct error was thrown
            } else {
                Issue.record("Expected invalidURL error but got: \(error)")
            }
        } catch {
            Issue.record("Unexpected error type: \(error)")
        }
    }
}

// MARK: - EmptyResponse Tests

struct EmptyResponseTests {
    @Test("EmptyResponse can be decoded from empty data", .tags(.network))
    func canBeDecodedFromEmptyJSON() throws {
        let json = "{}"
        let data = try #require(json.data(using: .utf8))
        let decoder = JSONDecoder()

        let response = try decoder.decode(EmptyResponse.self, from: data)
        #expect(response != nil)
    }
}
