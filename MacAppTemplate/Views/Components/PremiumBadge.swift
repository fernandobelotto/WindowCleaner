import SwiftUI

// MARK: - Premium Badge

/// A visual indicator for premium features.
///
/// Use this badge to mark features that require a premium subscription or purchase.
/// It can be displayed in different sizes and styles.
///
/// Usage:
/// ```swift
/// HStack {
///     Text("Advanced Export")
///     PremiumBadge()
/// }
///
/// // Or with custom style
/// PremiumBadge(style: .prominent)
/// ```
struct PremiumBadge: View {
    // MARK: - Properties

    /// The visual style of the badge
    var style: BadgeStyle = .standard

    /// Whether the badge should be interactive (shows paywall on tap)
    var isInteractive = false

    // MARK: - Environment

    @Environment(\.storeManager)
    private var storeManager

    // MARK: - State

    @State
    private var showingPaywall = false

    // MARK: - Body

    var body: some View {
        Group {
            switch style {
            case .standard:
                standardBadge
            case .compact:
                compactBadge
            case .prominent:
                prominentBadge
            case .icon:
                iconBadge
            }
        }
        .opacity(storeManager.isPremium ? 0 : 1)
        .onTapGesture {
            if isInteractive, !storeManager.isPremium {
                showingPaywall = true
            }
        }
        .sheet(isPresented: $showingPaywall) {
            PaywallView()
        }
    }

    // MARK: - Standard Badge

    private var standardBadge: some View {
        HStack(spacing: 4) {
            Image(systemName: "crown.fill")
                .font(.caption2)

            Text("PRO")
                .font(.caption.weight(.semibold))
        }
        .foregroundStyle(.white)
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(
            LinearGradient(
                colors: [.orange, .yellow],
                startPoint: .leading,
                endPoint: .trailing
            ),
            in: Capsule()
        )
    }

    // MARK: - Compact Badge

    private var compactBadge: some View {
        Text("PRO")
            .font(.caption2.weight(.bold))
            .foregroundStyle(.white)
            .padding(.horizontal, 6)
            .padding(.vertical, 2)
            .background(.orange.gradient, in: Capsule())
    }

    // MARK: - Prominent Badge

    private var prominentBadge: some View {
        HStack(spacing: 6) {
            Image(systemName: "crown.fill")
                .font(.subheadline)

            Text("Premium Feature")
                .font(.subheadline.weight(.medium))
        }
        .foregroundStyle(.white)
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .background(
            LinearGradient(
                colors: [.purple, .blue],
                startPoint: .leading,
                endPoint: .trailing
            ),
            in: Capsule()
        )
        .shadow(color: .purple.opacity(0.3), radius: 8, x: 0, y: 4)
    }

    // MARK: - Icon Badge

    private var iconBadge: some View {
        Image(systemName: "crown.fill")
            .font(.caption)
            .foregroundStyle(.orange)
    }
}

// MARK: - Badge Style

extension PremiumBadge {
    /// Visual style options for the premium badge
    enum BadgeStyle {
        /// Standard pill-shaped badge with icon and "PRO" text
        case standard

        /// Smaller badge with just "PRO" text
        case compact

        /// Larger, more visually prominent badge
        case prominent

        /// Just the crown icon
        case icon
    }
}

// MARK: - Premium Feature Modifier

/// A view modifier that adds a premium badge overlay and optional paywall trigger.
struct PremiumFeatureModifier: ViewModifier {
    let badgeStyle: PremiumBadge.BadgeStyle
    let alignment: Alignment
    let showPaywallOnTap: Bool

    @Environment(\.storeManager)
    private var storeManager

    @State
    private var showingPaywall = false

    func body(content: Content) -> some View {
        content
            .overlay(alignment: alignment) {
                if !storeManager.isPremium {
                    PremiumBadge(style: badgeStyle)
                        .padding(4)
                }
            }
            .onTapGesture {
                if showPaywallOnTap, !storeManager.isPremium {
                    showingPaywall = true
                }
            }
            .sheet(isPresented: $showingPaywall) {
                PaywallView()
            }
    }
}

extension View {
    /// Adds a premium badge overlay to the view.
    /// - Parameters:
    ///   - style: The badge style to use
    ///   - alignment: Where to position the badge
    ///   - showPaywallOnTap: Whether tapping shows the paywall
    /// - Returns: The modified view with a premium badge
    func premiumBadge(
        style: PremiumBadge.BadgeStyle = .compact,
        alignment: Alignment = .topTrailing,
        showPaywallOnTap: Bool = false
    ) -> some View {
        modifier(PremiumFeatureModifier(
            badgeStyle: style,
            alignment: alignment,
            showPaywallOnTap: showPaywallOnTap
        ))
    }
}

// MARK: - Premium Gate Modifier

/// A view modifier that requires premium access to interact with content.
struct PremiumGateModifier: ViewModifier {
    @Environment(\.storeManager)
    private var storeManager

    @State
    private var showingPaywall = false

    func body(content: Content) -> some View {
        content
            .disabled(!storeManager.isPremium)
            .opacity(storeManager.isPremium ? 1 : 0.5)
            .overlay {
                if !storeManager.isPremium {
                    Color.clear
                        .contentShape(Rectangle())
                        .onTapGesture {
                            showingPaywall = true
                        }
                }
            }
            .sheet(isPresented: $showingPaywall) {
                PaywallView()
            }
    }
}

extension View {
    /// Gates the view behind premium access.
    /// When not premium, the view is disabled and tapping shows the paywall.
    func premiumGated() -> some View {
        modifier(PremiumGateModifier())
    }
}

// MARK: - Previews

#Preview("Badge Styles") {
    VStack(spacing: 20) {
        HStack {
            Text("Standard:")
            Spacer()
            PremiumBadge(style: .standard)
        }

        HStack {
            Text("Compact:")
            Spacer()
            PremiumBadge(style: .compact)
        }

        HStack {
            Text("Prominent:")
            Spacer()
            PremiumBadge(style: .prominent)
        }

        HStack {
            Text("Icon:")
            Spacer()
            PremiumBadge(style: .icon)
        }
    }
    .padding()
    .frame(width: 300)
}

#Preview("Badge Overlay") {
    VStack(spacing: 20) {
        Button("Export as PDF") {}
            .buttonStyle(.borderedProminent)
            .premiumBadge()

        Text("Advanced Settings")
            .font(.headline)
            .padding()
            .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 8))
            .premiumBadge(style: .standard, alignment: .topTrailing)
    }
    .padding()
}

#Preview("Gated Content") {
    VStack(spacing: 20) {
        Button("Free Feature") {
            // This works
        }
        .buttonStyle(.bordered)

        Button("Premium Feature") {
            // This is gated
        }
        .buttonStyle(.borderedProminent)
        .premiumGated()
    }
    .padding()
}
