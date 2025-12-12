import Foundation

// MARK: - Application Errors

/// Application-specific errors with user-friendly messages.
///
/// Usage:
/// ```swift
/// throw AppError.validationError("Title cannot be empty")
/// ```
enum AppError: LocalizedError {
    /// Failed to fetch data from SwiftData or external source
    case fetchFailed(Error)

    /// Failed to save changes to SwiftData
    case saveFailed(Error)

    /// Network request failed
    case networkError(Error)

    /// Data validation failed with a specific message
    case validationError(String)

    /// User is not authorized to perform the action
    case unauthorized

    /// A required resource was not found
    case notFound(String)

    /// An unknown error occurred
    case unknown(Error)

    // MARK: - LocalizedError

    var errorDescription: String? {
        switch self {
        case .fetchFailed:
            "Failed to load data"
        case .saveFailed:
            "Failed to save changes"
        case .networkError:
            "Network connection failed"
        case let .validationError(message):
            message
        case .unauthorized:
            "Please sign in to continue"
        case let .notFound(resource):
            "\(resource) not found"
        case .unknown:
            "An unexpected error occurred"
        }
    }

    var recoverySuggestion: String? {
        switch self {
        case .fetchFailed:
            "Try refreshing the data or restarting the app."
        case .saveFailed:
            "Check available storage and try again."
        case .networkError:
            "Check your internet connection and try again."
        case .validationError:
            "Please correct the input and try again."
        case .unauthorized:
            "Your session may have expired. Please sign in again."
        case .notFound:
            "The requested item may have been deleted."
        case .unknown:
            "Please try again. If the problem persists, restart the app."
        }
    }

    var failureReason: String? {
        switch self {
        case let .fetchFailed(error),
             let .saveFailed(error),
             let .networkError(error),
             let .unknown(error):
            error.localizedDescription
        default:
            nil
        }
    }
}

// MARK: - Error Handling Helpers

extension AppError {
    /// Wraps any error into an AppError if it isn't already one
    static func wrap(_ error: Error) -> AppError {
        if let appError = error as? AppError {
            return appError
        }
        return .unknown(error)
    }
}
