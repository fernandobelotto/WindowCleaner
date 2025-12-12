import Foundation
import os

// MARK: - Application Logger

/// Centralized logging using Apple's unified logging system (os.Logger).
/// Use these loggers instead of `print()` for production-quality logging.
///
/// Usage:
/// ```swift
/// Log.general.info("App launched")
/// Log.data.debug("Fetched \(count) items")
/// Log.ui.error("Failed to load view: \(error)")
/// ```
enum Log {
    /// The app's bundle identifier used as the logging subsystem
    private static let subsystem = Bundle.main.bundleIdentifier ?? "com.fernandobelotto.MacAppTemplate"

    /// General application events and lifecycle
    static let general = Logger(subsystem: subsystem, category: "general")

    /// Data operations: SwiftData, persistence, caching
    static let data = Logger(subsystem: subsystem, category: "data")

    /// UI-related events: view lifecycle, user interactions
    static let ui = Logger(subsystem: subsystem, category: "ui")

    /// Network operations: API calls, downloads, uploads
    static let network = Logger(subsystem: subsystem, category: "network")

    /// Performance measurements and metrics
    static let performance = Logger(subsystem: subsystem, category: "performance")

    /// Store and In-App Purchase operations
    static let store = Logger(subsystem: subsystem, category: "store")

    /// Navigation events: route changes, deep linking, stack operations
    static let navigation = Logger(subsystem: subsystem, category: "navigation")

    /// Factory method for creating category-specific loggers
    /// - Parameter category: The category name for the logger
    /// - Returns: A configured Logger instance
    static func logger(category: String) -> Logger {
        Logger(subsystem: subsystem, category: category)
    }
}

// MARK: - Logger Extensions

extension Logger {
    /// Log a message with timing information
    /// - Parameters:
    ///   - message: The message to log
    ///   - startTime: The start time for duration calculation
    func timing(_ message: String, since startTime: Date) {
        let duration = Date().timeIntervalSince(startTime)
        info("\(message) (took \(String(format: "%.2f", duration * 1000))ms)")
    }
}
