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
    /// This array defines the standard welcome flow for MacAppTemplate, including:
    /// 1. **Welcome**: Introduction to the template
    /// 2. **SwiftData**: Highlights the persistence layer
    /// 3. **Keyboard Shortcuts**: Emphasizes keyboard-first navigation
    /// 4. **Customization**: Encourages users to extend the template
    ///
    /// ## Customization
    /// Replace these pages with your own content:
    /// ```swift
    /// WelcomeView(pages: myCustomPages)
    /// ```
    static let defaultPages: [WelcomePageData] = [
        WelcomePageData(
            icon: "macwindow",
            iconColor: .appPrimary,
            title: "Welcome to MacAppTemplate",
            description: "A modern foundation for building macOS apps with SwiftUI and SwiftData."
        ),
        WelcomePageData(
            icon: "square.stack.3d.up.fill",
            iconColor: .purple,
            title: "SwiftData Powered",
            description: "Your data is persisted and synced using Apple's latest persistence framework."
        ),
        WelcomePageData(
            icon: "keyboard",
            iconColor: .orange,
            title: "Keyboard First",
            description: "Navigate efficiently with keyboard shortcuts. Press ⌘N to create, Delete to remove."
        ),
        WelcomePageData(
            icon: "paintbrush.fill",
            iconColor: .pink,
            title: "Ready to Customize",
            description: "Built with best practices in mind. Extend the template to create your perfect app."
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
