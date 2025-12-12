import SwiftUI

// MARK: - Welcome View

/// A carousel-style onboarding experience shown on first app launch.
///
/// `WelcomeView` displays a multi-page introduction to the app in a standalone window.
/// It uses a `TabView` to provide swipeable pages with navigation controls and
/// progress indicators.
///
/// ## Features
/// - Carousel navigation with swipe gestures
/// - Page indicators showing current position
/// - Skip button to bypass onboarding
/// - Back/Next navigation buttons
/// - "Get Started" action on the final page
/// - Automatic dismissal and preference persistence
///
/// ## Window Configuration
/// The view is designed as a standalone window scene:
/// ```swift
/// Window("Welcome to WindowCleaner", id: WindowID.welcome.rawValue) {
///     WelcomeView()
/// }
/// .windowResizability(.contentSize)
/// .windowStyle(.hiddenTitleBar)
/// .defaultPosition(.center)
/// ```
///
/// ## Opening the Welcome Window
/// ```swift
/// @Environment(\.openWindow) private var openWindow
///
/// WindowManager.openWelcome(using: openWindow)
/// ```
///
/// ## Customization
/// Provide custom pages by passing a different page array:
/// ```swift
/// WelcomeView(pages: myCustomPages)
/// ```
///
/// ## First Launch Behavior
/// The view automatically shows on first launch (controlled by ``UserDefaultsKey/showWelcomeScreen``).
/// When dismissed, it sets the preference to prevent future automatic displays.
///
/// - SeeAlso: ``WelcomePageView`` for individual page layout
/// - SeeAlso: ``WelcomePageData`` for page content configuration
/// - SeeAlso: ``WindowManager`` for window management utilities
struct WelcomeView: View {
    // MARK: - Environment

    /// Environment action to dismiss this window
    @Environment(\.dismissWindow)
    private var dismissWindow

    // MARK: - Properties

    /// The pages to display in the carousel. Defaults to ``WelcomePageData/defaultPages``.
    var pages: [WelcomePageData] = WelcomePageData.defaultPages

    // MARK: - State

    /// The index of the currently displayed page in the carousel
    @State
    private var currentPage = 0

    // MARK: - Computed Properties

    /// Whether the current page is the last page in the carousel
    private var isLastPage: Bool {
        currentPage == pages.count - 1
    }

    /// Whether the current page is the first page in the carousel
    private var isFirstPage: Bool {
        currentPage == 0
    }

    // MARK: - Body

    var body: some View {
        VStack(spacing: 0) {
            // Page Content
            TabView(selection: $currentPage) {
                ForEach(Array(pages.enumerated()), id: \.element.id) { index, page in
                    WelcomePageView(
                        icon: page.icon,
                        iconColor: page.iconColor,
                        title: page.title,
                        description: page.description
                    )
                    .tag(index)
                }
            }
            .tabViewStyle(.automatic)

            // Navigation Controls
            navigationControls
                .padding(.horizontal, Metrics.spacingXL)
                .padding(.bottom, Metrics.spacingL)
        }
        .frame(width: 540, height: 460)
        .background(Color.appBackground)
    }

    // MARK: - Navigation Controls

    @ViewBuilder private var navigationControls: some View {
        HStack {
            // Skip Button (hidden on last page)
            Button("Skip") {
                dismissWelcome()
            }
            .buttonStyle(.plain)
            .foregroundStyle(.secondary)
            .opacity(isLastPage ? 0 : 1)

            Spacer()

            // Page Indicators
            pageIndicators

            Spacer()

            // Next / Get Started Button
            if isLastPage {
                Button("Get Started") {
                    dismissWelcome()
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
            } else {
                HStack(spacing: Metrics.spacingS) {
                    // Back Button
                    Button {
                        withAnimation(AppTheme.Animation.standard) {
                            currentPage -= 1
                        }
                    } label: {
                        Image(systemName: "chevron.left")
                    }
                    .buttonStyle(.plain)
                    .disabled(isFirstPage)
                    .opacity(isFirstPage ? 0.3 : 1)

                    // Next Button
                    Button {
                        withAnimation(AppTheme.Animation.standard) {
                            currentPage += 1
                        }
                    } label: {
                        HStack(spacing: 4) {
                            Text("Next")
                            Image(systemName: "chevron.right")
                        }
                    }
                    .buttonStyle(.borderedProminent)
                    .controlSize(.large)
                }
            }
        }
    }

    // MARK: - Page Indicators

    @ViewBuilder private var pageIndicators: some View {
        HStack(spacing: 8) {
            ForEach(0 ..< pages.count, id: \.self) { index in
                Circle()
                    .fill(index == currentPage ? Color.appPrimary : Color.secondary.opacity(0.3))
                    .frame(width: 8, height: 8)
                    .scaleEffect(index == currentPage ? 1.2 : 1.0)
                    .animation(AppTheme.Animation.fast, value: currentPage)
            }
        }
    }

    // MARK: - Actions

    /// Dismisses the welcome window and persists the user preference.
    ///
    /// This method:
    /// 1. Sets ``UserDefaultsKey/showWelcomeScreen`` to `false` to prevent future automatic displays
    /// 2. Dismisses the window using ``WindowManager/dismissWelcome(using:)``
    private func dismissWelcome() {
        // Mark welcome as shown (won't show again on next launch)
        UserDefaults.standard.set(false, forKey: UserDefaultsKey.showWelcomeScreen)
        WindowManager.dismissWelcome(using: dismissWindow)
    }
}

// MARK: - Preview

#Preview("Welcome View") {
    WelcomeView()
}

#Preview("Last Page") {
    if let lastPage = WelcomePageData.defaultPages.last {
        WelcomeView(pages: [lastPage])
    }
}
