import SwiftUI

// MARK: - App Theme

/// Centralized design system providing reusable design tokens for the entire application.
///
/// `AppTheme` defines a comprehensive set of design tokens organized into logical groups,
/// ensuring visual consistency and making it easy to "skin" the application with different
/// themes or brand colors.
///
/// ## Design Token Categories
/// - **Colors**: Semantic color palette (``Colors``)
/// - **Typography**: Text styles and font scales (``Typography``)
/// - **Shadows**: Elevation hierarchy via shadow presets (``Shadows``)
/// - **Animation**: Timing curves and durations (``Animation``)
///
/// ## Usage Patterns
///
/// ### Using Colors
/// ```swift
/// Text("Hello")
///     .foregroundStyle(Color.appPrimary)
///     .background(Color.appSurface)
/// ```
///
/// ### Using Typography
/// ```swift
/// Text("Welcome")
///     .font(.appTitle)
///
/// Text("Description")
///     .font(.appBody)
///     .foregroundStyle(Color.appSecondary)
/// ```
///
/// ### Using Shadows
/// ```swift
/// RoundedRectangle(cornerRadius: 12)
///     .shadowMedium()  // Convenience method
///
/// // Or directly:
/// someView.shadow(AppTheme.Shadows.large)
/// ```
///
/// ### Using Animations
/// ```swift
/// withAnimation(AppTheme.Animation.spring) {
///     isExpanded.toggle()
/// }
/// ```
///
/// ## Theming Strategy
/// To rebrand the app, update the values in this file. The entire UI will automatically
/// reflect the changes since all views use these tokens instead of hardcoded values.
///
/// - SeeAlso: ``Metrics`` for layout spacing and sizing constants
/// - SeeAlso: ``Config`` for application-wide configuration
enum AppTheme {
    // MARK: - Colors

    /// Semantic color palette for the application.
    ///
    /// Uses semantic naming (primary, secondary, background) rather than concrete
    /// color names (blue, red, white) to support dynamic appearance changes and
    /// dark mode adaptation.
    ///
    /// ## Color Usage Guidelines
    /// - **Primary**: Main brand color, used for primary actions and accents
    /// - **Secondary**: Supporting color for secondary UI elements
    /// - **Background/Surface**: Different background levels for visual hierarchy
    /// - **Text colors**: Three levels (primary, secondary, tertiary) for content hierarchy
    /// - **State colors**: Success, warning, and error for feedback
    enum Colors {
        /// Primary brand color
        static let primary = Color.accentColor

        /// Secondary accent color
        static let secondary = Color.secondary

        /// Background for main content areas
        static let background = Color(nsColor: .windowBackgroundColor)

        /// Background for grouped content
        static let groupedBackground = Color(nsColor: .controlBackgroundColor)

        /// Surface color for cards and elevated elements
        static let surface = Color(nsColor: .textBackgroundColor)

        /// Primary text color
        static let textPrimary = Color.primary

        /// Secondary text color
        static let textSecondary = Color.secondary

        /// Tertiary text color for captions
        static let textTertiary = Color(nsColor: .tertiaryLabelColor)

        /// Success state color
        static let success = Color.green

        /// Warning state color
        static let warning = Color.orange

        /// Error/destructive state color
        static let error = Color.red

        /// Separator/divider color
        static let separator = Color(nsColor: .separatorColor)
    }

    // MARK: - Typography

    /// Typography scale for consistent text styling across the application.
    ///
    /// Provides a complete typographic hierarchy following Apple's Human Interface Guidelines.
    /// All font styles are based on standard system fonts with appropriate weights.
    ///
    /// ## Type Scale
    /// - **Display**: Large title (34pt) for prominent headers
    /// - **Titles**: Title 1-3 (28pt, 22pt, 20pt) for section headers
    /// - **Body**: Headline, body, callout (17pt, 17pt, 16pt) for content
    /// - **Supporting**: Subheadline, footnote, captions (15pt, 13pt, 12-11pt)
    /// - **Monospaced**: For code, UUIDs, or technical content
    enum Typography {
        /// Large title (34pt, bold)
        static let largeTitle = Font.largeTitle.weight(.bold)

        /// Title 1 (28pt, bold)
        static let title1 = Font.title.weight(.bold)

        /// Title 2 (22pt, semibold)
        static let title2 = Font.title2.weight(.semibold)

        /// Title 3 (20pt, semibold)
        static let title3 = Font.title3.weight(.semibold)

        /// Headline (17pt, semibold)
        static let headline = Font.headline

        /// Body (17pt, regular)
        static let body = Font.body

        /// Callout (16pt, regular)
        static let callout = Font.callout

        /// Subheadline (15pt, regular)
        static let subheadline = Font.subheadline

        /// Footnote (13pt, regular)
        static let footnote = Font.footnote

        /// Caption 1 (12pt, regular)
        static let caption1 = Font.caption

        /// Caption 2 (11pt, regular)
        static let caption2 = Font.caption2

        /// Monospaced body for code
        static let monospaced = Font.body.monospaced()
    }

    // MARK: - Shadows

    /// Shadow presets creating visual elevation hierarchy.
    ///
    /// Provides three levels of shadow depth to establish spatial relationships
    /// and visual hierarchy in the interface.
    ///
    /// ## Shadow Levels
    /// - **Small**: Subtle elevation for cards and list items
    /// - **Medium**: Moderate elevation for floating elements like buttons
    /// - **Large**: Prominent elevation for modals, popovers, and sheets
    ///
    /// ## Usage
    /// ```swift
    /// // Using convenience methods:
    /// cardView.shadowSmall()
    /// buttonView.shadowMedium()
    /// modalView.shadowLarge()
    ///
    /// // Or directly:
    /// view.shadow(AppTheme.Shadows.medium)
    /// ```
    enum Shadows {
        /// Subtle shadow for cards
        static let small = ShadowStyle(
            color: .black.opacity(0.1),
            radius: 2,
            x: 0,
            y: 1
        )

        /// Medium shadow for floating elements
        static let medium = ShadowStyle(
            color: .black.opacity(0.15),
            radius: 8,
            x: 0,
            y: 4
        )

        /// Large shadow for modals and popovers
        static let large = ShadowStyle(
            color: .black.opacity(0.2),
            radius: 16,
            x: 0,
            y: 8
        )
    }

    // MARK: - Animation

    /// Animation timing curves and durations for consistent motion design.
    ///
    /// Defines standard animation curves and durations to create cohesive motion
    /// throughout the application. Choose animations based on interaction type:
    ///
    /// ## Animation Selection Guide
    /// - **Fast**: Quick feedback for toggles, switches, small state changes (0.15s)
    /// - **Standard**: Default for most transitions and UI changes (0.3s)
    /// - **Slow**: Deliberate motion for important changes or large movements (0.5s)
    /// - **Spring**: Bouncy, playful motion for interactive elements
    /// - **Smooth Spring**: Gentle spring for page transitions and navigation
    ///
    /// ## Usage Examples
    /// ```swift
    /// // Toggle animation
    /// withAnimation(AppTheme.Animation.fast) {
    ///     isEnabled.toggle()
    /// }
    ///
    /// // Standard transition
    /// withAnimation(AppTheme.Animation.standard) {
    ///     currentView = .detail
    /// }
    ///
    /// // Spring animation
    /// withAnimation(AppTheme.Animation.spring) {
    ///     scale = 1.2
    /// }
    /// ```
    enum Animation {
        /// Quick interaction feedback (0.15s)
        static let fast: SwiftUI.Animation = .easeInOut(duration: 0.15)

        /// Standard transition (0.3s)
        static let standard: SwiftUI.Animation = .easeInOut(duration: 0.3)

        /// Deliberate motion (0.5s)
        static let slow: SwiftUI.Animation = .easeInOut(duration: 0.5)

        /// Spring animation for bouncy effects
        static let spring: SwiftUI.Animation = .spring(duration: 0.3, bounce: 0.2)

        /// Smooth spring for page transitions
        static let smoothSpring: SwiftUI.Animation = .spring(duration: 0.5, bounce: 0.1)

        // MARK: Durations

        /// Fast duration value
        static let durationFast: Double = 0.15

        /// Standard duration value
        static let durationStandard: Double = 0.3

        /// Slow duration value
        static let durationSlow: Double = 0.5
    }
}

// MARK: - Shadow Style

/// A reusable shadow configuration encapsulating all shadow parameters.
///
/// Combines color, radius, and offset into a single reusable type that can be
/// applied to views using the custom shadow modifier.
///
/// ## Usage
/// ```swift
/// let customShadow = ShadowStyle(
///     color: .black.opacity(0.2),
///     radius: 12,
///     x: 0,
///     y: 6
/// )
///
/// view.shadow(customShadow)
/// ```
struct ShadowStyle {
    /// The shadow color and opacity
    let color: Color

    /// The blur radius of the shadow
    let radius: CGFloat

    /// Horizontal offset of the shadow
    let x: CGFloat

    /// Vertical offset of the shadow
    let y: CGFloat
}

// MARK: - Color Extensions

extension Color {
    /// Primary brand color
    static let appPrimary = AppTheme.Colors.primary

    /// Secondary accent color
    static let appSecondary = AppTheme.Colors.secondary

    /// Background color
    static let appBackground = AppTheme.Colors.background

    /// Surface color for cards
    static let appSurface = AppTheme.Colors.surface

    /// Success color
    static let appSuccess = AppTheme.Colors.success

    /// Warning color
    static let appWarning = AppTheme.Colors.warning

    /// Error color
    static let appError = AppTheme.Colors.error
}

// MARK: - Font Extensions

extension Font {
    /// App large title style
    static let appLargeTitle = AppTheme.Typography.largeTitle

    /// App title style
    static let appTitle = AppTheme.Typography.title1

    /// App title 2 style
    static let appTitle2 = AppTheme.Typography.title2

    /// App title 3 style
    static let appTitle3 = AppTheme.Typography.title3

    /// App headline style
    static let appHeadline = AppTheme.Typography.headline

    /// App body style
    static let appBody = AppTheme.Typography.body

    /// App callout style
    static let appCallout = AppTheme.Typography.callout

    /// App subheadline style
    static let appSubheadline = AppTheme.Typography.subheadline

    /// App footnote style
    static let appFootnote = AppTheme.Typography.footnote

    /// App caption style
    static let appCaption = AppTheme.Typography.caption1

    /// App caption 2 style
    static let appCaption2 = AppTheme.Typography.caption2

    /// App monospaced style
    static let appMonospaced = AppTheme.Typography.monospaced
}

// MARK: - View Extensions

extension View {
    /// Applies a custom shadow style to the view.
    ///
    /// - Parameter style: The ``ShadowStyle`` configuration to apply
    /// - Returns: A view with the shadow applied
    ///
    /// ## Example
    /// ```swift
    /// myView.shadow(AppTheme.Shadows.medium)
    /// ```
    func shadow(_ style: ShadowStyle) -> some View {
        shadow(
            color: style.color,
            radius: style.radius,
            x: style.x,
            y: style.y
        )
    }

    /// Applies the small shadow preset for subtle elevation.
    ///
    /// Use for cards, list items, and slightly elevated content.
    ///
    /// - Returns: A view with a small shadow applied
    func shadowSmall() -> some View {
        shadow(AppTheme.Shadows.small)
    }

    /// Applies the medium shadow preset for moderate elevation.
    ///
    /// Use for floating buttons, toolbars, and interactive elements.
    ///
    /// - Returns: A view with a medium shadow applied
    func shadowMedium() -> some View {
        shadow(AppTheme.Shadows.medium)
    }

    /// Applies the large shadow preset for prominent elevation.
    ///
    /// Use for modals, popovers, sheets, and high-priority overlays.
    ///
    /// - Returns: A view with a large shadow applied
    func shadowLarge() -> some View {
        shadow(AppTheme.Shadows.large)
    }
}

// MARK: - Preview

#Preview("Colors") {
    VStack(alignment: .leading, spacing: 12) {
        ColorRow(name: "Primary", color: .appPrimary)
        ColorRow(name: "Secondary", color: .appSecondary)
        ColorRow(name: "Background", color: .appBackground)
        ColorRow(name: "Surface", color: .appSurface)
        ColorRow(name: "Success", color: .appSuccess)
        ColorRow(name: "Warning", color: .appWarning)
        ColorRow(name: "Error", color: .appError)
    }
    .padding()
    .frame(width: 300)
}

#Preview("Typography") {
    VStack(alignment: .leading, spacing: 8) {
        Text("Large Title").font(.appLargeTitle)
        Text("Title").font(.appTitle)
        Text("Title 2").font(.appTitle2)
        Text("Title 3").font(.appTitle3)
        Text("Headline").font(.appHeadline)
        Text("Body").font(.appBody)
        Text("Callout").font(.appCallout)
        Text("Subheadline").font(.appSubheadline)
        Text("Footnote").font(.appFootnote)
        Text("Caption").font(.appCaption)
        Text("Caption 2").font(.appCaption2)
        Text("Monospaced").font(.appMonospaced)
    }
    .padding()
}

#Preview("Shadows") {
    HStack(spacing: 32) {
        RoundedRectangle(cornerRadius: 12)
            .fill(Color.appSurface)
            .frame(width: 80, height: 80)
            .shadowSmall()
            .overlay(Text("Small").font(.appCaption))

        RoundedRectangle(cornerRadius: 12)
            .fill(Color.appSurface)
            .frame(width: 80, height: 80)
            .shadowMedium()
            .overlay(Text("Medium").font(.appCaption))

        RoundedRectangle(cornerRadius: 12)
            .fill(Color.appSurface)
            .frame(width: 80, height: 80)
            .shadowLarge()
            .overlay(Text("Large").font(.appCaption))
    }
    .padding(40)
    .background(Color.appBackground)
}

// MARK: - Preview Helpers

private struct ColorRow: View {
    let name: String
    let color: Color

    var body: some View {
        HStack {
            RoundedRectangle(cornerRadius: 4)
                .fill(color)
                .frame(width: 40, height: 24)
                .overlay(
                    RoundedRectangle(cornerRadius: 4)
                        .strokeBorder(Color.primary.opacity(0.1))
                )

            Text(name)
                .font(.appBody)

            Spacer()
        }
    }
}
