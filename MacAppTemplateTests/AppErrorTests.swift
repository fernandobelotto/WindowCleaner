import Foundation
@testable import MacAppTemplate
import Testing

// MARK: - AppError Tests

/// Tests for the `AppError` enum and its LocalizedError conformance.
struct AppErrorTests {
    // MARK: - Test Data

    private let sampleUnderlyingError = NSError(
        domain: "TestDomain",
        code: 42,
        userInfo: [NSLocalizedDescriptionKey: "Test underlying error"]
    )

    // MARK: - Error Description Tests

    @Test("fetchFailed has correct error description", .tags(.utility))
    func fetchFailedHasCorrectDescription() {
        let error = AppError.fetchFailed(sampleUnderlyingError)

        #expect(error.errorDescription == "Failed to load data")
    }

    @Test("saveFailed has correct error description", .tags(.utility))
    func saveFailedHasCorrectDescription() {
        let error = AppError.saveFailed(sampleUnderlyingError)

        #expect(error.errorDescription == "Failed to save changes")
    }

    @Test("networkError has correct error description", .tags(.utility))
    func networkErrorHasCorrectDescription() {
        let error = AppError.networkError(sampleUnderlyingError)

        #expect(error.errorDescription == "Network connection failed")
    }

    @Test("validationError uses provided message", .tags(.utility))
    func validationErrorUsesProvidedMessage() {
        let message = "Title cannot be empty"
        let error = AppError.validationError(message)

        #expect(error.errorDescription == message)
    }

    @Test("unauthorized has correct error description", .tags(.utility))
    func unauthorizedHasCorrectDescription() {
        let error = AppError.unauthorized

        #expect(error.errorDescription == "Please sign in to continue")
    }

    @Test("notFound includes resource name", .tags(.utility))
    func notFoundIncludesResourceName() {
        let resource = "Document"
        let error = AppError.notFound(resource)

        #expect(error.errorDescription == "\(resource) not found")
    }

    @Test("unknown has correct error description", .tags(.utility))
    func unknownHasCorrectDescription() {
        let error = AppError.unknown(sampleUnderlyingError)

        #expect(error.errorDescription == "An unexpected error occurred")
    }

    // MARK: - Recovery Suggestion Tests

    @Test("fetchFailed has recovery suggestion", .tags(.utility))
    func fetchFailedHasRecoverySuggestion() {
        let error = AppError.fetchFailed(sampleUnderlyingError)

        #expect(error.recoverySuggestion != nil)
        #expect(error.recoverySuggestion?.contains("refresh") == true)
    }

    @Test("saveFailed has recovery suggestion", .tags(.utility))
    func saveFailedHasRecoverySuggestion() {
        let error = AppError.saveFailed(sampleUnderlyingError)

        #expect(error.recoverySuggestion != nil)
        #expect(error.recoverySuggestion?.contains("storage") == true)
    }

    @Test("networkError has recovery suggestion", .tags(.utility))
    func networkErrorHasRecoverySuggestion() {
        let error = AppError.networkError(sampleUnderlyingError)

        #expect(error.recoverySuggestion != nil)
        #expect(error.recoverySuggestion?.contains("internet") == true)
    }

    @Test("validationError has recovery suggestion", .tags(.utility))
    func validationErrorHasRecoverySuggestion() {
        let error = AppError.validationError("Invalid input")

        #expect(error.recoverySuggestion != nil)
        #expect(error.recoverySuggestion?.contains("correct") == true)
    }

    @Test("unauthorized has recovery suggestion", .tags(.utility))
    func unauthorizedHasRecoverySuggestion() {
        let error = AppError.unauthorized

        #expect(error.recoverySuggestion != nil)
        #expect(error.recoverySuggestion?.contains("sign in") == true)
    }

    @Test("notFound has recovery suggestion", .tags(.utility))
    func notFoundHasRecoverySuggestion() {
        let error = AppError.notFound("Item")

        #expect(error.recoverySuggestion != nil)
        #expect(error.recoverySuggestion?.contains("deleted") == true)
    }

    @Test("unknown has recovery suggestion", .tags(.utility))
    func unknownHasRecoverySuggestion() {
        let error = AppError.unknown(sampleUnderlyingError)

        #expect(error.recoverySuggestion != nil)
        #expect(error.recoverySuggestion?.contains("try again") == true)
    }

    // MARK: - Failure Reason Tests

    @Test("fetchFailed includes underlying error description", .tags(.utility))
    func fetchFailedIncludesUnderlyingError() {
        let error = AppError.fetchFailed(sampleUnderlyingError)

        #expect(error.failureReason != nil)
        #expect(error.failureReason == sampleUnderlyingError.localizedDescription)
    }

    @Test("saveFailed includes underlying error description", .tags(.utility))
    func saveFailedIncludesUnderlyingError() {
        let error = AppError.saveFailed(sampleUnderlyingError)

        #expect(error.failureReason != nil)
    }

    @Test("networkError includes underlying error description", .tags(.utility))
    func networkErrorIncludesUnderlyingError() {
        let error = AppError.networkError(sampleUnderlyingError)

        #expect(error.failureReason != nil)
    }

    @Test("unknown includes underlying error description", .tags(.utility))
    func unknownIncludesUnderlyingError() {
        let error = AppError.unknown(sampleUnderlyingError)

        #expect(error.failureReason != nil)
    }

    @Test("validationError has no failure reason", .tags(.utility))
    func validationErrorHasNoFailureReason() {
        let error = AppError.validationError("Invalid")

        #expect(error.failureReason == nil)
    }

    @Test("unauthorized has no failure reason", .tags(.utility))
    func unauthorizedHasNoFailureReason() {
        let error = AppError.unauthorized

        #expect(error.failureReason == nil)
    }

    @Test("notFound has no failure reason", .tags(.utility))
    func notFoundHasNoFailureReason() {
        let error = AppError.notFound("Resource")

        #expect(error.failureReason == nil)
    }

    // MARK: - Wrap Function Tests

    @Test("wrap returns same error if already AppError", .tags(.utility))
    func wrapReturnsSameAppError() {
        let originalError = AppError.validationError("Test")
        let wrappedError = AppError.wrap(originalError)

        if case let .validationError(message) = wrappedError {
            #expect(message == "Test")
        } else {
            Issue.record("Expected validationError but got \(wrappedError)")
        }
    }

    @Test("wrap converts NSError to unknown", .tags(.utility))
    func wrapConvertsNSErrorToUnknown() {
        let nsError = NSError(domain: "Test", code: 1)
        let wrappedError = AppError.wrap(nsError)

        if case .unknown = wrappedError {
            // Success
        } else {
            Issue.record("Expected unknown but got \(wrappedError)")
        }
    }

    @Test("wrap preserves underlying error in unknown case", .tags(.utility))
    func wrapPreservesUnderlyingError() {
        let nsError = NSError(
            domain: "Test",
            code: 1,
            userInfo: [NSLocalizedDescriptionKey: "Original error"]
        )
        let wrappedError = AppError.wrap(nsError)

        #expect(wrappedError.failureReason == "Original error")
    }

    // MARK: - LocalizedError Conformance Tests

    @Test("All error cases conform to LocalizedError", .tags(.utility))
    func allCasesConformToLocalizedError() {
        let errors: [AppError] = [
            .fetchFailed(sampleUnderlyingError),
            .saveFailed(sampleUnderlyingError),
            .networkError(sampleUnderlyingError),
            .validationError("Test"),
            .unauthorized,
            .notFound("Resource"),
            .unknown(sampleUnderlyingError),
        ]

        for error in errors {
            #expect(error.errorDescription != nil, "Error \(error) should have description")
            #expect(error.recoverySuggestion != nil, "Error \(error) should have recovery suggestion")
        }
    }
}
