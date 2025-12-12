import SwiftUI

// MARK: - Welcome Page View

/// Displays a single page of content within the welcome carousel.
///
/// `WelcomePageView` presents an individual onboarding page with:
/// - A large, colorful SF Symbol icon
/// - A prominent title using app typography
/// - A descriptive subtitle with additional context
///
/// ## Layout Structure
/// The view uses a centered vertical stack with:
/// 1. Icon (72pt system font with hierarchical rendering)
/// 2. Title (app title font)
/// 3. Description (secondary text, max width 320pt)
///
/// ## Typography
/// - **Title**: Uses ``AppTheme/Typography/titleFont`` for consistency
/// - **Description**: Secondary color for visual hierarchy
///
/// ## Usage
/// Typically used within ``WelcomeView``'s TabView:
/// ```swift
/// TabView {
///     WelcomePageView(
///         icon: "star.fill",
///         iconColor: .yellow,
///         title: "Welcome",
///         description: "Get started with the app."
///     )
/// }
/// ```
///
/// Or create pages from data models:
/// ```swift
/// ForEach(pages) { page in
///     WelcomePageView(
///         icon: page.icon,
///         iconColor: page.iconColor,
///         title: page.title,
///         description: page.description
///     )
/// }
/// ```
///
/// - SeeAlso: ``WelcomeView`` for the carousel container
/// - SeeAlso: ``WelcomePageData`` for page content configuration
struct WelcomePageView: View {
    // MARK: - Properties

    /// The SF Symbol name to display as the page icon
    let icon: String

    /// The color to apply to the icon
    let iconColor: Color

    /// The main title text for this page
    let title: String

    /// The descriptive text explaining this page's content
    let description: String

    // MARK: - Body

    var body: some View {
        VStack(spacing: Metrics.spacingL) {
            Spacer()

            // Icon
            Image(systemName: icon)
                .font(.system(size: 72))
                .foregroundStyle(iconColor)
                .symbolRenderingMode(.hierarchical)

            // Text Content
            VStack(spacing: Metrics.spacingS) {
                Text(title)
                    .font(.appTitle)
                    .multilineTextAlignment(.center)

                Text(description)
                    .font(.appBody)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .frame(maxWidth: 320)
            }

            Spacer()
            Spacer()
        }
        .padding(Metrics.spacingXL)
    }
}

// MARK: - Welcome Page Data

/// Data model representing a single page in the welcome carousel.
///
/// Use this model to define the content for each onboarding page shown in ``WelcomeView``.
///
/// ## Example
/// ```swift
/// let page = WelcomePageData(
///     icon: "star.fill",
///     iconColor: .yellow,
///     title: "Feature Name",
///     description: "Detailed explanation of the feature."
/// )
/// ```
///
/// - SeeAlso: ``defaultPages`` for the standard onboarding flow
struct WelcomePageData: Identifiable {
    /// Unique identifier for this page
    let id = UUID()

    /// SF Symbol name for the page icon
    let icon: String

    /// Color to apply to the icon
    let iconColor: Color

    /// Main title for the page
    let title: String

    /// Descriptive text explaining the feature or concept
    let description: String
}

// MARK: - Default Pages

extension WelcomePageData {
    /// The default onboarding pages shown on first app launch.
    ///
    /// This array defines the standard welcome flow for WindowCleaner, including:
    /// 1. **Welcome**: Introduction to the app
    /// 2. **Tracking**: Explains app monitoring
    /// 3. **Smart Detection**: Staleness scoring
    /// 4. **Insights**: Usage analytics
    /// 5. **Get Started**: Permissions and setup
    static let defaultPages: [WelcomePageData] = [
        WelcomePageData(
            icon: "macwindow.badge.plus",
            iconColor: .appPrimary,
            title: "Welcome to Window Cleaner",
            description: "Keep your Mac running smoothly by identifying and closing stale, resource-heavy apps."
        ),
        WelcomePageData(
            icon: "eye",
            iconColor: .blue,
            title: "Track Running Apps",
            description: "Window Cleaner monitors all running apps, tracking memory usage, CPU activity, and how long each app has been idle."
        ),
        WelcomePageData(
            icon: "sparkles",
            iconColor: .orange,
            title: "Smart Staleness Detection",
            description: "Our intelligent scoring algorithm identifies apps that are using resources but haven't been active, suggesting them for cleanup."
        ),
        WelcomePageData(
            icon: "chart.bar.xaxis",
            iconColor: .purple,
            title: "Usage Insights",
            description: "View detailed analytics about your app usage patterns, memory trends, and discover which apps consume the most resources."
        ),
        WelcomePageData(
            icon: "checkmark.circle.fill",
            iconColor: .green,
            title: "Ready to Get Started",
            description: "Window Cleaner is ready to help you manage your apps. Access it from the menu bar or the main window anytime."
        ),
    ]
}

// MARK: - Preview

#Preview("Welcome Page") {
    WelcomePageView(
        icon: "star.fill",
        iconColor: .yellow,
        title: "Welcome",
        description: "This is a sample welcome page with a description that explains a feature."
    )
    .frame(width: 500, height: 400)
}

#Preview("All Pages") {
    TabView {
        ForEach(WelcomePageData.defaultPages) { page in
            WelcomePageView(
                icon: page.icon,
                iconColor: page.iconColor,
                title: page.title,
                description: page.description
            )
        }
    }
    .frame(width: 500, height: 400)
}
