import os
import SwiftUI

// MARK: - Navigation Routes

/// Type-safe navigation destinations for the detail area.
///
/// Usage:
/// ```swift
/// NavigationManager.shared.navigate(to: .itemDetail(item.id))
/// ```
enum NavigationRoute: Hashable {
    /// Shows the detail view for a specific item
    case itemDetail(UUID)

    /// Shows the edit view for a specific item
    case itemEdit(UUID)

    // Future routes can be added here:
    // case statistics
    // case profile
}

// MARK: - Navigation Manager

/// Centralized service for managing in-app navigation state.
///
/// This manager handles programmatic navigation within the detail area
/// of the NavigationSplitView using a NavigationPath.
///
/// Usage:
/// ```swift
/// // Navigate to a route
/// NavigationManager.shared.navigate(to: .itemDetail(item.id))
///
/// // Pop to root
/// NavigationManager.shared.popToRoot()
///
/// // Go back one level
/// NavigationManager.shared.pop()
/// ```
@Observable
final class NavigationManager {
    // MARK: - Shared Instance

    /// Shared singleton instance for global access
    static let shared = NavigationManager()

    // MARK: - State

    /// The navigation path controlling the NavigationStack
    var path = NavigationPath()

    // MARK: - Initialization

    private init() {}

    // MARK: - Navigation Actions

    /// Navigates to a specific route by pushing it onto the stack.
    /// - Parameter route: The destination route to navigate to.
    func navigate(to route: NavigationRoute) {
        path.append(route)
        Log.navigation.debug("Navigated to: \(String(describing: route))")
    }

    /// Pops the top view from the navigation stack.
    func pop() {
        guard !path.isEmpty else {
            Log.navigation.debug("Pop ignored: navigation stack is empty")
            return
        }
        path.removeLast()
        Log.navigation.debug("Popped navigation stack")
    }

    /// Pops all views and returns to the root of the navigation stack.
    func popToRoot() {
        path = NavigationPath()
        Log.navigation.debug("Popped to root")
    }

    /// Replaces the current navigation stack with a single route.
    /// - Parameter route: The route to navigate to.
    func replace(with route: NavigationRoute) {
        path = NavigationPath()
        path.append(route)
        Log.navigation.debug("Replaced stack with: \(String(describing: route))")
    }

    /// Returns the current depth of the navigation stack.
    var stackDepth: Int {
        path.count
    }

    /// Whether the navigation stack is at the root level.
    var isAtRoot: Bool {
        path.isEmpty
    }

    /// Resets the navigation state (useful for testing).
    func reset() {
        path = NavigationPath()
    }
}

// MARK: - Environment Key

/// Environment key for injecting NavigationManager
private struct NavigationManagerKey: EnvironmentKey {
    static let defaultValue = NavigationManager.shared
}

extension EnvironmentValues {
    /// Access the shared NavigationManager instance
    var navigationManager: NavigationManager {
        get { self[NavigationManagerKey.self] }
        set { self[NavigationManagerKey.self] = newValue }
    }
}
