import Testing

// MARK: - Test Tags

/// Tags for organizing and filtering tests.
///
/// Usage:
/// ```swift
/// @Test("Item initializes correctly", .tags(.model))
/// func testItemInit() { ... }
/// ```
extension Tag {
    /// Tests for SwiftData models
    @Tag static var model: Self

    /// Tests for service layer components
    @Tag static var service: Self

    /// Integration tests that span multiple components
    @Tag static var integration: Self

    /// Tests for utility functions and helpers
    @Tag static var utility: Self

    /// Tests for view-related logic (not UI tests)
    @Tag static var view: Self

    /// Tests for network/HTTP client components
    @Tag static var network: Self
}
