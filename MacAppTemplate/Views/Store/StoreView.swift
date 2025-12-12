import os
import StoreKit
import SwiftUI

// MARK: - Store View

/// Main store view displaying all available In-App Purchase products.
///
/// This view demonstrates StoreKit 2's native SwiftUI views:
/// - `ProductView` for consumables and non-consumables
/// - `SubscriptionStoreView` for subscription groups
///
/// Usage:
/// ```swift
/// StoreView()
///     .environment(StoreManager.shared)
/// ```
struct StoreView: View {
    // MARK: - Environment

    @Environment(\.storeManager)
    private var storeManager

    @Environment(\.dismiss)
    private var dismiss

    // MARK: - State

    @State
    private var selectedTab = StoreTab.subscriptions

    @State
    private var showingError = false

    @State
    private var errorMessage = ""

    // MARK: - Body

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: Metrics.spacingL) {
                    // Current Status Banner
                    statusBanner

                    // Tab Picker
                    Picker("Store Section", selection: $selectedTab) {
                        ForEach(StoreTab.allCases) { tab in
                            Text(tab.title).tag(tab)
                        }
                    }
                    .pickerStyle(.segmented)
                    .padding(.horizontal)

                    // Content based on selected tab
                    switch selectedTab {
                    case .subscriptions:
                        subscriptionsSection
                    case .oneTime:
                        oneTimePurchasesSection
                    case .consumables:
                        consumablesSection
                    }

                    // Restore Purchases Button
                    restorePurchasesButton
                }
                .padding(.vertical, Metrics.spacingL)
            }
            .navigationTitle("Store")
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
            .alert("Purchase Error", isPresented: $showingError) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(errorMessage)
            }
        }
        .frame(minWidth: 500, minHeight: 600)
    }

    // MARK: - Status Banner

    @ViewBuilder private var statusBanner: some View {
        if storeManager.isPremium {
            HStack(spacing: Metrics.spacingS) {
                Image(systemName: "checkmark.seal.fill")
                    .foregroundStyle(.green)
                    .font(.title2)

                VStack(alignment: .leading, spacing: 2) {
                    Text("Premium Active")
                        .font(.appHeadline)
                    Text(storeManager.entitlement.displayName)
                        .font(.appCaption)
                        .foregroundStyle(.secondary)
                }

                Spacer()
            }
            .padding()
            .background(.green.opacity(0.1), in: RoundedRectangle(cornerRadius: Metrics.cornerRadiusM))
            .padding(.horizontal)
        }
    }

    // MARK: - Subscriptions Section

    @ViewBuilder private var subscriptionsSection: some View {
        VStack(alignment: .leading, spacing: Metrics.spacingM) {
            SectionHeader(
                title: "Premium Subscription",
                subtitle: "Unlock all features with a subscription"
            )

            // Native SubscriptionStoreView
            SubscriptionStoreView(groupID: StoreProductID.subscriptionGroupID) {
                // Marketing content header
                VStack(spacing: Metrics.spacingM) {
                    Image(systemName: "crown.fill")
                        .font(.system(size: 48))
                        .foregroundStyle(.yellow.gradient)

                    Text("Go Premium")
                        .font(.appTitle)

                    Text("Get unlimited access to all features")
                        .font(.appBody)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)

                    // Feature list
                    VStack(alignment: .leading, spacing: Metrics.spacingS) {
                        FeatureRow(icon: "sparkles", text: "Advanced features unlocked")
                        FeatureRow(icon: "bolt.fill", text: "Priority support")
                        FeatureRow(icon: "arrow.down.circle.fill", text: "Unlimited exports")
                        FeatureRow(icon: "person.2.fill", text: "Family Sharing included")
                    }
                    .padding(.top, Metrics.spacingS)
                }
                .padding()
            }
            .subscriptionStoreControlStyle(.automatic)
            .subscriptionStorePickerItemBackground(.thinMaterial)
            .storeButton(.visible, for: .restorePurchases)
            .onInAppPurchaseCompletion { _, result in
                handlePurchaseCompletion(result)
            }
        }
        .padding(.horizontal)
    }

    // MARK: - One-Time Purchases Section

    @ViewBuilder private var oneTimePurchasesSection: some View {
        VStack(alignment: .leading, spacing: Metrics.spacingM) {
            SectionHeader(
                title: "Lifetime Access",
                subtitle: "One-time purchase, yours forever"
            )

            if let proProduct = storeManager.product(for: StoreProductID.proLifetime) {
                ProductView(id: proProduct.id) {
                    // Custom promotional content
                    VStack(spacing: Metrics.spacingS) {
                        Image(systemName: "star.circle.fill")
                            .font(.system(size: 40))
                            .foregroundStyle(.purple.gradient)

                        Text("Pro Lifetime")
                            .font(.appHeadline)

                        Text("Pay once, use forever")
                            .font(.appCaption)
                            .foregroundStyle(.secondary)
                    }
                }
                .productViewStyle(.large)
                .onInAppPurchaseCompletion { _, result in
                    handlePurchaseCompletion(result)
                }
                .padding()
                .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: Metrics.cornerRadiusL))
            } else {
                loadingPlaceholder
            }
        }
        .padding(.horizontal)
    }

    // MARK: - Consumables Section

    @ViewBuilder private var consumablesSection: some View {
        VStack(alignment: .leading, spacing: Metrics.spacingM) {
            SectionHeader(
                title: "Token Packs",
                subtitle: "Purchase tokens to use in the app"
            )

            // Token balance display
            HStack {
                Image(systemName: "circle.grid.3x3.fill")
                    .foregroundStyle(.orange.gradient)
                    .font(.title2)

                Text("Current Balance:")
                    .font(.appBody)

                Text("\(storeManager.tokenBalance) tokens")
                    .font(.appHeadline)
                    .foregroundStyle(.orange)

                Spacer()
            }
            .padding()
            .background(.orange.opacity(0.1), in: RoundedRectangle(cornerRadius: Metrics.cornerRadiusM))

            if let tokenProduct = storeManager.product(for: StoreProductID.tokenPack) {
                ProductView(id: tokenProduct.id) {
                    VStack(spacing: Metrics.spacingS) {
                        Image(systemName: "plus.circle.fill")
                            .font(.system(size: 40))
                            .foregroundStyle(.orange.gradient)

                        Text("100 Tokens")
                            .font(.appHeadline)

                        Text("Replenish your balance")
                            .font(.appCaption)
                            .foregroundStyle(.secondary)
                    }
                }
                .productViewStyle(.large)
                .onInAppPurchaseCompletion { _, result in
                    handlePurchaseCompletion(result)
                }
                .padding()
                .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: Metrics.cornerRadiusL))
            } else {
                loadingPlaceholder
            }
        }
        .padding(.horizontal)
    }

    // MARK: - Restore Purchases

    private var restorePurchasesButton: some View {
        Button {
            Task {
                do {
                    try await storeManager.restorePurchases()
                } catch {
                    errorMessage = error.localizedDescription
                    showingError = true
                }
            }
        } label: {
            Text("Restore Purchases")
                .font(.appSubheadline)
        }
        .buttonStyle(.plain)
        .foregroundStyle(.secondary)
        .padding(.top, Metrics.spacingM)
    }

    // MARK: - Loading Placeholder

    private var loadingPlaceholder: some View {
        VStack(spacing: Metrics.spacingM) {
            ProgressView()
            Text("Loading products...")
                .font(.appCaption)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(Metrics.spacingXL)
    }

    // MARK: - Helpers

    private func handlePurchaseCompletion(_ result: Result<Product.PurchaseResult, Error>) {
        switch result {
        case let .success(purchaseResult):
            switch purchaseResult {
            case let .success(verification):
                switch verification {
                case let .verified(transaction):
                    Log.store.info("Purchase verified: \(transaction.productID)")
                    Task {
                        await transaction.finish()
                    }
                case let .unverified(_, error):
                    Log.store.error("Purchase verification failed: \(error.localizedDescription)")
                    errorMessage = "Could not verify purchase. Please try again."
                    showingError = true
                }
            case .userCancelled:
                Log.store.debug("User cancelled purchase")
            case .pending:
                Log.store.info("Purchase pending approval")
                errorMessage = "Your purchase is pending approval."
                showingError = true
            @unknown default:
                break
            }
        case let .failure(error):
            Log.store.error("Purchase failed: \(error.localizedDescription)")
            errorMessage = error.localizedDescription
            showingError = true
        }
    }
}

// MARK: - Store Tab

private enum StoreTab: String, CaseIterable, Identifiable {
    case subscriptions
    case oneTime
    case consumables

    var id: String { rawValue }

    var title: String {
        switch self {
        case .subscriptions:
            "Subscriptions"
        case .oneTime:
            "One-Time"
        case .consumables:
            "Tokens"
        }
    }
}

// MARK: - Section Header

private struct SectionHeader: View {
    let title: String
    let subtitle: String

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.appTitle2)
            Text(subtitle)
                .font(.appSubheadline)
                .foregroundStyle(.secondary)
        }
    }
}

// MARK: - Feature Row

private struct FeatureRow: View {
    let icon: String
    let text: String

    var body: some View {
        HStack(spacing: Metrics.spacingS) {
            Image(systemName: icon)
                .foregroundStyle(.green)
                .frame(width: 20)

            Text(text)
                .font(.appSubheadline)
        }
    }
}

// MARK: - Previews

#Preview("Store View") {
    StoreView()
}

#Preview("Store View - Dark") {
    StoreView()
        .preferredColorScheme(.dark)
}
