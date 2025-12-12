import os
import StoreKit
import SwiftUI

// MARK: - Type Aliases

/// StoreKit Transaction type (to avoid ambiguity with SwiftData)
typealias StoreTransaction = StoreKit.Transaction

// MARK: - Store Manager

/// Centralized service for managing In-App Purchases using StoreKit 2.
///
/// This service handles:
/// - Loading products from the App Store
/// - Processing purchases and verifying transactions
/// - Tracking entitlements (subscriptions, non-consumables, consumables)
/// - Listening for transaction updates
///
/// Usage:
/// ```swift
/// struct MyView: View {
///     @Environment(StoreManager.self) private var storeManager
///
///     var body: some View {
///         if storeManager.isPremium {
///             PremiumContentView()
///         } else {
///             PaywallView()
///         }
///     }
/// }
/// ```
@Observable
@MainActor
final class StoreManager {
    // MARK: - Shared Instance

    /// Shared instance for app-wide access
    static let shared = StoreManager()

    // MARK: - Products

    /// All loaded products
    private(set) var products: [Product] = []

    /// Consumable products
    var consumables: [Product] {
        products.filter { StoreProductID.consumables.contains($0.id) }
    }

    /// Non-consumable products
    var nonConsumables: [Product] {
        products.filter { StoreProductID.nonConsumables.contains($0.id) }
    }

    /// Subscription products
    var subscriptions: [Product] {
        products.filter { StoreProductID.subscriptions.contains($0.id) }
    }

    // MARK: - State

    /// Whether products are currently loading
    private(set) var isLoading = false

    /// Current error, if any
    private(set) var error: StoreError?

    /// Whether a purchase is in progress
    private(set) var isPurchasing = false

    // MARK: - Entitlements

    /// Current premium entitlement status
    private(set) var entitlement: PremiumEntitlement = .none

    /// Whether the user has Pro lifetime access
    private(set) var hasProLifetime = false

    /// Active subscription transaction
    @ObservationIgnored private(set) var activeSubscription: StoreTransaction?

    /// Current token balance (consumable)
    var tokenBalance: Int {
        get { UserDefaults.standard.integer(forKey: UserDefaultsKey.tokenBalance) }
        set { UserDefaults.standard.set(newValue, forKey: UserDefaultsKey.tokenBalance) }
    }

    /// Whether the user has any premium access (Pro or subscription)
    var isPremium: Bool {
        entitlement.isActive
    }

    /// Whether the user has an active subscription
    var hasActiveSubscription: Bool {
        activeSubscription != nil
    }

    // MARK: - Private Properties

    /// Transaction listener task
    @ObservationIgnored private var transactionListenerTask: Task<Void, Never>?

    /// Logger for store operations
    @ObservationIgnored private let logger = Logger(
        subsystem: Bundle.main.bundleIdentifier ?? "WindowCleaner",
        category: "Store"
    )

    // MARK: - Initialization

    private init() {
        // Start listening for transactions immediately
        startTransactionListener()

        // Load products and check entitlements on init
        Task {
            await loadProducts()
            await updateEntitlements()
        }
    }

    // MARK: - Product Loading

    /// Loads all products from the App Store.
    func loadProducts() async {
        guard !isLoading else { return }

        isLoading = true
        error = nil

        do {
            products = try await Product.products(for: StoreProductID.all)
            let productCount = products.count
            logger.info("Loaded \(productCount) products")
        } catch {
            logger.error("Failed to load products: \(error.localizedDescription)")
            self.error = .failedToLoadProducts
        }

        isLoading = false
    }

    // MARK: - Purchasing

    /// Purchases a product.
    /// - Parameter product: The product to purchase
    /// - Returns: The verified transaction if successful
    @discardableResult
    func purchase(_ product: Product) async throws -> StoreTransaction {
        isPurchasing = true
        defer { isPurchasing = false }

        do {
            let result = try await product.purchase()

            switch result {
            case let .success(verification):
                let transaction = try checkVerification(verification)

                // Process the transaction
                await processTransaction(transaction)

                // Finish the transaction
                await transaction.finish()

                logger.info("Purchase successful: \(product.id)")
                return transaction

            case .userCancelled:
                logger.info("Purchase cancelled by user")
                throw StoreError.purchaseCancelled

            case .pending:
                logger.info("Purchase pending")
                throw StoreError.purchasePending

            @unknown default:
                throw StoreError.unknown
            }
        } catch let storeError as StoreError {
            throw storeError
        } catch {
            logger.error("Purchase failed: \(error.localizedDescription)")
            throw StoreError.purchaseFailed(error)
        }
    }

    /// Restores purchases by syncing with the App Store.
    func restorePurchases() async throws {
        logger.info("Restoring purchases...")

        do {
            try await AppStore.sync()
            await updateEntitlements()
            logger.info("Purchases restored successfully")
        } catch {
            logger.error("Failed to restore purchases: \(error.localizedDescription)")
            throw StoreError.purchaseFailed(error)
        }
    }

    // MARK: - Entitlement Management

    /// Updates the current entitlements by checking all transactions.
    func updateEntitlements() async {
        logger.debug("Updating entitlements...")

        var foundProLifetime = false
        var foundSubscription: StoreTransaction?

        // Check all current entitlements
        for await result in StoreTransaction.currentEntitlements {
            guard case let .verified(transaction) = result else {
                continue
            }

            switch transaction.productID {
            case StoreProductID.proLifetime:
                foundProLifetime = true
                logger.debug("Found Pro lifetime entitlement")

            case StoreProductID.subscriptionMonthly, StoreProductID.subscriptionYearly:
                // Keep the most recent subscription
                if foundSubscription == nil ||
                    transaction.purchaseDate > (foundSubscription?.purchaseDate ?? .distantPast) {
                    foundSubscription = transaction
                }
                logger.debug("Found subscription entitlement: \(transaction.productID)")

            default:
                break
            }
        }

        // Update state
        hasProLifetime = foundProLifetime
        activeSubscription = foundSubscription

        // Determine overall entitlement
        if foundProLifetime {
            entitlement = .proLifetime
        } else if let subscription = foundSubscription {
            entitlement = .subscription(expirationDate: subscription.expirationDate)
        } else {
            entitlement = .none
        }

        let displayName = entitlement.displayName
        logger.info("Entitlement updated: \(displayName)")

        // Post notification for observers
        NotificationCenter.default.post(name: .entitlementsDidUpdate, object: nil)
    }

    // MARK: - Transaction Processing

    /// Processes a verified transaction.
    private func processTransaction(_ transaction: StoreTransaction) async {
        switch transaction.productID {
        case StoreProductID.tokenPack:
            // Add tokens for consumable purchase
            let tokensToAdd = 100 // Configure based on your product
            tokenBalance += tokensToAdd
            let newBalance = tokenBalance
            logger.info("Added \(tokensToAdd) tokens. New balance: \(newBalance)")

        case StoreProductID.proLifetime:
            hasProLifetime = true
            entitlement = .proLifetime
            logger.info("Pro lifetime unlocked")

        case StoreProductID.subscriptionMonthly, StoreProductID.subscriptionYearly:
            activeSubscription = transaction
            entitlement = .subscription(expirationDate: transaction.expirationDate)
            logger.info("Subscription activated: \(transaction.productID)")

        default:
            logger.warning("Unknown product: \(transaction.productID)")
        }
    }

    // MARK: - Transaction Listener

    /// Starts listening for transaction updates.
    private func startTransactionListener() {
        transactionListenerTask = Task(priority: .background) { [weak self] in
            for await result in StoreTransaction.updates {
                guard let self else { return }

                switch result {
                case let .verified(transaction):
                    await processTransaction(transaction)
                    await transaction.finish()
                    await updateEntitlements()

                case let .unverified(transaction, verificationError):
                    let transactionID = transaction.id
                    let errorDescription = verificationError.localizedDescription
                    await MainActor.run {
                        self.logger.error(
                            "Unverified transaction \(transactionID): \(errorDescription)"
                        )
                    }
                }
            }
        }
    }

    /// Cancels the transaction listener (call when no longer needed).
    func cancelTransactionListener() {
        transactionListenerTask?.cancel()
        transactionListenerTask = nil
    }

    // MARK: - Verification

    /// Verifies a transaction result.
    private func checkVerification<T>(_ result: VerificationResult<T>) throws -> T {
        switch result {
        case let .verified(safe):
            return safe
        case .unverified:
            throw StoreError.verificationFailed
        }
    }

    // MARK: - Helpers

    /// Gets a product by ID.
    func product(for id: String) -> Product? {
        products.first { $0.id == id }
    }

    /// Checks if a specific product is purchased.
    func isPurchased(_ productID: String) async -> Bool {
        for await result in StoreTransaction.currentEntitlements {
            if case let .verified(transaction) = result, transaction.productID == productID {
                return true
            }
        }
        return false
    }

    /// Consumes tokens (for consumable usage).
    /// - Parameter amount: Number of tokens to consume
    /// - Returns: `true` if tokens were consumed, `false` if insufficient balance
    @discardableResult
    func consumeTokens(_ amount: Int) -> Bool {
        let currentBalance = tokenBalance
        guard currentBalance >= amount else {
            logger.warning("Insufficient tokens. Balance: \(currentBalance), requested: \(amount)")
            return false
        }

        tokenBalance -= amount
        let newBalance = tokenBalance
        logger.info("Consumed \(amount) tokens. New balance: \(newBalance)")
        return true
    }

    // MARK: - Debug Helpers

    #if DEBUG
        /// Resets all local store state for testing purposes.
        ///
        /// This clears:
        /// - Token balance
        /// - Paywall seen flag
        /// - Local entitlement state
        ///
        /// Note: To clear StoreKit sandbox transactions, use Xcode's StoreKit Transaction Manager
        /// (Debug > StoreKit > Manage Transactions) or edit the StoreKit configuration file.
        func resetForTesting() async {
            logger.info("Debug: Resetting local store state for testing...")

            // Reset local state
            tokenBalance = 0
            UserDefaults.standard.removeObject(forKey: UserDefaultsKey.hasSeenPaywall)
            entitlement = .none
            hasProLifetime = false
            activeSubscription = nil

            // Refresh entitlements from actual transaction history
            // (This will restore any actual sandbox purchases that still exist)
            await updateEntitlements()

            // Notify observers
            NotificationCenter.default.post(name: .entitlementsDidUpdate, object: nil)

            logger.info("Debug: Local store state reset complete")
            logger.info("Debug: To clear sandbox transactions, use Xcode > Debug > StoreKit > Manage Transactions")
        }
    #endif
}

// MARK: - Environment Key

/// Environment key for injecting StoreManager
private struct StoreManagerKey: EnvironmentKey {
    @MainActor
    static let defaultValue = StoreManager.shared
}

extension EnvironmentValues {
    /// Access the shared StoreManager instance
    var storeManager: StoreManager {
        get { self[StoreManagerKey.self] }
        set { self[StoreManagerKey.self] = newValue }
    }
}

// MARK: - View Extension for Paywall

extension View {
    /// Presents a paywall sheet when the user is not premium.
    /// - Parameters:
    ///   - isPresented: Binding to control sheet presentation
    ///   - onPurchase: Optional callback when a purchase is completed
    func paywallSheet(
        isPresented: Binding<Bool>,
        onPurchase: (() -> Void)? = nil
    ) -> some View {
        sheet(isPresented: isPresented) {
            PaywallView(onPurchase: onPurchase)
        }
    }
}
