import os
import StoreKit
import SwiftUI

// MARK: - Paywall View

/// A modal paywall view for gating premium features.
///
/// This view presents subscription options with marketing content,
/// designed to be shown when users attempt to access premium features.
///
/// Usage:
/// ```swift
/// @State private var showPaywall = false
///
/// Button("Premium Feature") {
///     if !storeManager.isPremium {
///         showPaywall = true
///     }
/// }
/// .sheet(isPresented: $showPaywall) {
///     PaywallView()
/// }
/// ```
struct PaywallView: View {
    // MARK: - Environment

    @Environment(\.storeManager)
    private var storeManager

    @Environment(\.dismiss)
    private var dismiss

    // MARK: - Properties

    /// Optional callback when a purchase is completed
    var onPurchase: (() -> Void)?

    // MARK: - State

    @State
    private var showingError = false

    @State
    private var errorMessage = ""

    @State
    private var isRestoring = false

    // MARK: - Body

    var body: some View {
        VStack(spacing: 0) {
            // Header with dismiss button
            header

            ScrollView {
                VStack(spacing: Metrics.spacingL) {
                    // Hero section
                    heroSection

                    // Feature highlights
                    featureHighlights

                    // Subscription options
                    subscriptionSection

                    // Alternative: One-time purchase
                    alternativePurchaseSection

                    // Footer links
                    footerLinks
                }
                .padding(.vertical, Metrics.spacingL)
            }
        }
        .frame(minWidth: 480, idealWidth: 520, maxWidth: 600)
        .frame(minHeight: 650, idealHeight: 700)
        .background(backgroundGradient)
        .alert("Error", isPresented: $showingError) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(errorMessage)
        }
    }

    // MARK: - Header

    private var header: some View {
        HStack {
            Spacer()

            Button {
                dismiss()
            } label: {
                Image(systemName: "xmark.circle.fill")
                    .font(.title2)
                    .foregroundStyle(.secondary)
            }
            .buttonStyle(.plain)
            .keyboardShortcut(.escape, modifiers: [])
        }
        .padding()
    }

    // MARK: - Hero Section

    private var heroSection: some View {
        VStack(spacing: Metrics.spacingM) {
            // Animated crown icon
            Image(systemName: "crown.fill")
                .font(.system(size: 64))
                .foregroundStyle(
                    LinearGradient(
                        colors: [.yellow, .orange],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .shadow(color: .orange.opacity(0.4), radius: 20, x: 0, y: 10)

            Text("Unlock Premium")
                .font(.system(size: 32, weight: .bold, design: .rounded))

            Text("Get the most out of WindowCleaner")
                .font(.appTitle3)
                .foregroundStyle(.secondary)
        }
        .padding(.horizontal)
    }

    // MARK: - Feature Highlights

    private var featureHighlights: some View {
        VStack(spacing: Metrics.spacingM) {
            PaywallFeatureCard(
                icon: "sparkles",
                iconColor: .purple,
                title: "Advanced Features",
                description: "Access all premium tools and capabilities"
            )

            PaywallFeatureCard(
                icon: "bolt.fill",
                iconColor: .orange,
                title: "Priority Support",
                description: "Get help faster with dedicated support"
            )

            PaywallFeatureCard(
                icon: "arrow.down.circle.fill",
                iconColor: .blue,
                title: "Unlimited Exports",
                description: "Export without limits in all formats"
            )

            PaywallFeatureCard(
                icon: "person.2.fill",
                iconColor: .green,
                title: "Family Sharing",
                description: "Share with up to 5 family members"
            )
        }
        .padding(.horizontal, Metrics.spacingL)
    }

    // MARK: - Subscription Section

    private var subscriptionSection: some View {
        VStack(spacing: Metrics.spacingM) {
            Text("Choose Your Plan")
                .font(.appTitle3)
                .padding(.top, Metrics.spacingM)

            SubscriptionStoreView(groupID: StoreProductID.subscriptionGroupID)
                .subscriptionStoreControlStyle(.prominentPicker)
                .subscriptionStorePickerItemBackground(.thinMaterial)
                .storeButton(.hidden, for: .restorePurchases)
                .onInAppPurchaseCompletion { product, result in
                    handlePurchaseCompletion(product: product, result: result)
                }
                .frame(height: 200)
        }
        .padding(.horizontal)
    }

    // MARK: - Alternative Purchase

    private var alternativePurchaseSection: some View {
        VStack(spacing: Metrics.spacingS) {
            Divider()
                .padding(.horizontal, Metrics.spacingXL)

            Text("Or get lifetime access")
                .font(.appSubheadline)
                .foregroundStyle(.secondary)
                .padding(.top, Metrics.spacingM)

            if let proProduct = storeManager.product(for: StoreProductID.proLifetime) {
                ProductView(id: proProduct.id)
                    .productViewStyle(.compact)
                    .onInAppPurchaseCompletion { product, result in
                        handlePurchaseCompletion(product: product, result: result)
                    }
                    .padding(.horizontal, Metrics.spacingL)
            }
        }
    }

    // MARK: - Footer Links

    private var footerLinks: some View {
        VStack(spacing: Metrics.spacingM) {
            // Restore purchases button
            Button {
                Task {
                    isRestoring = true
                    defer { isRestoring = false }

                    do {
                        try await storeManager.restorePurchases()
                        if storeManager.isPremium {
                            onPurchase?()
                            dismiss()
                        }
                    } catch {
                        errorMessage = error.localizedDescription
                        showingError = true
                    }
                }
            } label: {
                if isRestoring {
                    ProgressView()
                        .controlSize(.small)
                } else {
                    Text("Restore Purchases")
                }
            }
            .buttonStyle(.plain)
            .foregroundStyle(.secondary)
            .disabled(isRestoring)

            // Legal links
            HStack(spacing: Metrics.spacingM) {
                if let termsURL = URL(string: "https://example.com/terms") {
                    Link("Terms of Use", destination: termsURL)
                }
                Text("•").foregroundStyle(.tertiary)
                if let privacyURL = URL(string: "https://example.com/privacy") {
                    Link("Privacy Policy", destination: privacyURL)
                }
            }
            .font(.appCaption)
            .foregroundStyle(.secondary)
        }
        .padding(.top, Metrics.spacingM)
        .padding(.bottom, Metrics.spacingL)
    }

    // MARK: - Background

    private var backgroundGradient: some View {
        LinearGradient(
            colors: [
                Color(nsColor: .windowBackgroundColor),
                Color(nsColor: .windowBackgroundColor).opacity(0.95),
            ],
            startPoint: .top,
            endPoint: .bottom
        )
        .ignoresSafeArea()
    }

    // MARK: - Helpers

    private func handlePurchaseCompletion(
        product _: Product,
        result: Result<Product.PurchaseResult, Error>
    ) {
        switch result {
        case let .success(purchaseResult):
            switch purchaseResult {
            case let .success(verification):
                switch verification {
                case let .verified(transaction):
                    Log.store.info("Purchase verified: \(transaction.productID)")
                    Task {
                        await transaction.finish()
                        await storeManager.updateEntitlements()
                        onPurchase?()
                        dismiss()
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
                errorMessage = "Your purchase is pending approval. You'll be notified when complete."
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

// MARK: - Paywall Feature Card

private struct PaywallFeatureCard: View {
    let icon: String
    let iconColor: Color
    let title: String
    let description: String

    var body: some View {
        HStack(spacing: Metrics.spacingM) {
            ZStack {
                Circle()
                    .fill(iconColor.opacity(0.15))
                    .frame(width: 44, height: 44)

                Image(systemName: icon)
                    .font(.title3)
                    .foregroundStyle(iconColor)
            }

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.appHeadline)

                Text(description)
                    .font(.appSubheadline)
                    .foregroundStyle(.secondary)
            }

            Spacer()
        }
        .padding()
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: Metrics.cornerRadiusM))
    }
}

// MARK: - Previews

#Preview("Paywall") {
    PaywallView()
}

#Preview("Paywall - Dark") {
    PaywallView()
        .preferredColorScheme(.dark)
}
