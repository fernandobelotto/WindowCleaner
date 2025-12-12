import os
import SwiftUI

// MARK: - Error State

/// Observable object to manage error state for views.
///
/// Usage:
/// ```swift
/// @State private var errorState = ErrorState()
///
/// var body: some View {
///     ContentView()
///         .errorAlert(errorState)
/// }
///
/// // To show an error:
/// errorState.show(AppError.fetchFailed(error))
///
/// // With retry action:
/// errorState.show(AppError.networkError(error)) {
///     await retryFetch()
/// }
/// ```
@MainActor
@Observable
final class ErrorState {
    // MARK: - Properties

    /// The current error, if any
    var currentError: AppError?

    /// Whether an error alert is currently presented
    var isPresented = false

    /// Optional retry action
    var retryAction: (() async -> Void)?

    // MARK: - Methods

    /// Shows an error alert.
    /// - Parameters:
    ///   - error: The error to display.
    ///   - retry: Optional async action to perform on retry.
    func show(_ error: AppError, retry: (() async -> Void)? = nil) {
        currentError = error
        retryAction = retry
        isPresented = true
        Log.general.error("Error presented: \(error.errorDescription ?? "Unknown error")")
    }

    /// Shows any error wrapped as AppError.
    /// - Parameters:
    ///   - error: The error to display.
    ///   - retry: Optional async action to perform on retry.
    func show(_ error: Error, retry: (() async -> Void)? = nil) {
        show(AppError.wrap(error), retry: retry)
    }

    /// Clears the current error state.
    func clear() {
        currentError = nil
        retryAction = nil
        isPresented = false
    }
}

// MARK: - Error Alert Modifier

/// A view modifier that presents an alert for errors.
struct ErrorAlertModifier: ViewModifier {
    @Bindable var errorState: ErrorState

    func body(content: Content) -> some View {
        content
            .alert(
                errorState.currentError?.errorDescription ?? "Error",
                isPresented: $errorState.isPresented,
                presenting: errorState.currentError
            ) { _ in
                // Dismiss button
                Button("OK", role: .cancel) {
                    errorState.clear()
                }

                // Retry button (if action provided)
                if errorState.retryAction != nil {
                    Button("Try Again") {
                        Task {
                            await errorState.retryAction?()
                        }
                        errorState.clear()
                    }
                }
            } message: { error in
                if let suggestion = error.recoverySuggestion {
                    Text(suggestion)
                }
            }
    }
}

// MARK: - View Extension

extension View {
    /// Presents an alert when an error occurs.
    /// - Parameter errorState: The error state object to observe.
    /// - Returns: A view that presents alerts for errors.
    func errorAlert(_ errorState: ErrorState) -> some View {
        modifier(ErrorAlertModifier(errorState: errorState))
    }

    /// Presents an alert for a binding to an optional error.
    /// - Parameters:
    ///   - error: Binding to the optional error.
    ///   - onDismiss: Action to perform when the alert is dismissed.
    /// - Returns: A view that presents alerts for errors.
    func errorAlert(
        _ error: Binding<AppError?>,
        onDismiss: @escaping () -> Void = {}
    ) -> some View {
        alert(
            error.wrappedValue?.errorDescription ?? "Error",
            isPresented: Binding(
                get: { error.wrappedValue != nil },
                set: { if !$0 { error.wrappedValue = nil } }
            ),
            presenting: error.wrappedValue
        ) { _ in
            Button("OK", role: .cancel) {
                onDismiss()
            }
        } message: { appError in
            if let suggestion = appError.recoverySuggestion {
                Text(suggestion)
            }
        }
    }
}

// MARK: - Throwing Closure Helper

extension ErrorState {
    /// Executes an async throwing closure and shows an error alert on failure.
    /// - Parameters:
    ///   - operation: The async throwing operation to perform.
    ///   - retry: Whether to include a retry button that re-runs the operation.
    func `try`(
        retry: Bool = false,
        operation: @escaping () async throws -> Void
    ) async {
        do {
            try await operation()
        } catch {
            if retry {
                show(error) { [weak self] in
                    await self?.try(retry: true, operation: operation)
                }
            } else {
                show(error)
            }
        }
    }

    /// Executes an async throwing closure and shows an error alert on failure.
    /// - Parameters:
    ///   - operation: The async throwing operation to perform.
    ///   - retry: Whether to include a retry button that re-runs the operation.
    /// - Returns: The result of the operation, or nil if it failed.
    func `try`<T>(
        retry: Bool = false,
        operation: @escaping () async throws -> T
    ) async -> T? {
        do {
            return try await operation()
        } catch {
            if retry {
                show(error) { [weak self] in
                    _ = await self?.try(retry: true, operation: operation)
                }
            } else {
                show(error)
            }
            return nil
        }
    }
}

// MARK: - Preview

#Preview("Error Alert") {
    struct PreviewView: View {
        @State
        private var errorState = ErrorState()

        var body: some View {
            VStack(spacing: 20) {
                Text("Error Handling Demo")
                    .font(.appTitle)

                Button("Show Fetch Error") {
                    errorState.show(.fetchFailed(NSError(domain: "", code: -1)))
                }

                Button("Show Network Error with Retry") {
                    errorState.show(.networkError(NSError(domain: "", code: -1))) {
                        Log.general.info("Retrying...")
                    }
                }

                Button("Show Validation Error") {
                    errorState.show(.validationError("Name cannot be empty"))
                }
            }
            .padding()
            .frame(width: 400, height: 300)
            .errorAlert(errorState)
        }
    }

    return PreviewView()
}

#Preview("Error Binding") {
    struct PreviewView: View {
        @State
        private var error: AppError?

        var body: some View {
            VStack(spacing: 20) {
                Text("Error Binding Demo")
                    .font(.appTitle)

                Button("Show Error") {
                    error = .notFound("Document")
                }
            }
            .padding()
            .frame(width: 400, height: 300)
            .errorAlert($error)
        }
    }

    return PreviewView()
}
