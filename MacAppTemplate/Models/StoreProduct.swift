import Foundation
import StoreKit

// MARK: - Store Product Identifiers

/// Product identifiers for In-App Purchases.
/// Configure these in App Store Connect to match your app's bundle ID.
enum StoreProductID {
    // MARK: Consumables

    /// Token pack consumable (e.g., 100 tokens)
    static let tokenPack = "com.example.macapptemplate.consumable.tokens"

    // MARK: Non-Consumables

    /// Lifetime Pro unlock (one-time purchase)
    static let proLifetime = "com.example.macapptemplate.pro"

    // MARK: Subscriptions

    /// Monthly subscription
    static let subscriptionMonthly = "com.example.macapptemplate.subscription.monthly"

    /// Yearly subscription
    static let subscriptionYearly = "com.example.macapptemplate.subscription.yearly"

    /// Subscription group identifier
    static let subscriptionGroupID = "macapptemplate_premium"

    /// All product identifiers
    static let all: Set<String> = [
        tokenPack,
        proLifetime,
        subscriptionMonthly,
        subscriptionYearly,
    ]

    /// All subscription identifiers
    static let subscriptions: Set<String> = [
        subscriptionMonthly,
        subscriptionYearly,
    ]

    /// All non-consumable identifiers
    static let nonConsumables: Set<String> = [
        proLifetime,
    ]

    /// All consumable identifiers
    static let consumables: Set<String> = [
        tokenPack,
    ]
}

// MARK: - Entitlement Types

/// Represents the user's premium entitlement status.
enum PremiumEntitlement: Equatable, Sendable {
    /// User has no premium access
    case none

    /// User has lifetime Pro access (non-consumable purchase)
    case proLifetime

    /// User has active subscription
    case subscription(expirationDate: Date?)

    /// Whether the user has any premium access
    var isActive: Bool {
        switch self {
        case .none:
            false
        case .proLifetime, .subscription:
            true
        }
    }

    /// Human-readable description of the entitlement
    var displayName: String {
        switch self {
        case .none:
            return "Free"
        case .proLifetime:
            return "Pro (Lifetime)"
        case let .subscription(expiration):
            if let expiration {
                let formatter = DateFormatter()
                formatter.dateStyle = .medium
                return "Premium (renews \(formatter.string(from: expiration)))"
            }
            return "Premium"
        }
    }
}

// MARK: - Store Error

/// Errors that can occur during store operations.
enum StoreError: LocalizedError {
    case failedToLoadProducts
    case purchaseFailed(Error)
    case purchaseCancelled
    case purchasePending
    case verificationFailed
    case unknown

    var errorDescription: String? {
        switch self {
        case .failedToLoadProducts:
            "Failed to load products from the App Store"
        case let .purchaseFailed(error):
            "Purchase failed: \(error.localizedDescription)"
        case .purchaseCancelled:
            "Purchase was cancelled"
        case .purchasePending:
            "Purchase is pending approval"
        case .verificationFailed:
            "Could not verify purchase"
        case .unknown:
            "An unknown error occurred"
        }
    }

    var recoverySuggestion: String? {
        switch self {
        case .failedToLoadProducts:
            "Check your internet connection and try again."
        case .purchaseFailed:
            "Please try again or contact support if the problem persists."
        case .purchaseCancelled:
            nil
        case .purchasePending:
            "Your purchase requires approval. You'll be notified when it's complete."
        case .verificationFailed:
            "Please try restoring your purchases."
        case .unknown:
            "Please try again."
        }
    }
}

// MARK: - User Defaults Keys for Store

extension UserDefaultsKey {
    /// Stored token balance for consumables
    static let tokenBalance = "store.tokenBalance"

    /// Whether user has seen the paywall
    static let hasSeenPaywall = "store.hasSeenPaywall"
}

// MARK: - Notification Names for Store

extension Notification.Name {
    /// Posted when entitlements are updated
    static let entitlementsDidUpdate = Notification.Name("entitlementsDidUpdate")

    /// Posted when the store should be shown
    static let showStore = Notification.Name("showStore")
}
