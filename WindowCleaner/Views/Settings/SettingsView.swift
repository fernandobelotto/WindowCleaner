import os
import StoreKit
import SwiftUI
import UserNotifications

// MARK: - SettingsView

/// The main settings window accessible via ⌘, (Preferences).
struct SettingsView: View {
    var body: some View {
        TabView {
            GeneralSettingsTab()
                .tabItem {
                    Label("General", systemImage: "gear")
                }

            SubscriptionSettingsTab()
                .tabItem {
                    Label("Subscription", systemImage: "crown")
                }

            AboutSettingsTab()
                .tabItem {
                    Label("About", systemImage: "info.circle")
                }
        }
        .frame(width: 480, height: 350)
    }
}

// MARK: - General Settings Tab

/// General application settings.
struct GeneralSettingsTab: View {
    @AppStorage(UserDefaultsKey.showWelcomeScreen)
    private var showWelcomeScreen = true

    @AppStorage(UserDefaultsKey.notificationsEnabled)
    private var notificationsEnabled = true

    @State
    private var notificationStatus: UNAuthorizationStatus = .notDetermined

    var body: some View {
        Form {
            Section {
                Toggle("Show welcome screen on launch", isOn: $showWelcomeScreen)
            } header: {
                Text("Startup")
            }

            Section {
                Toggle("Enable notifications", isOn: $notificationsEnabled)

                if notificationStatus == .denied {
                    HStack {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .foregroundStyle(.orange)
                        Text("Notifications are blocked in System Settings")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        Spacer()
                        Button("Open Settings") {
                            openNotificationSettings()
                        }
                        .buttonStyle(.link)
                        .font(.caption)
                    }
                }

                Button("Send Test Notification") {
                    NotificationManager.shared.notifyCustom(
                        title: "Test Notification",
                        message: "Notifications are working correctly!"
                    )
                }
                .disabled(!notificationsEnabled || notificationStatus == .denied)
            } header: {
                Text("Notifications")
            } footer: {
                Text("Notifications will appear when items are created, deleted, or duplicated.")
                    .font(.caption)
                    .foregroundStyle(.tertiary)
            }

            Section {
                LabeledContent("Data Location") {
                    Text("~/Library/Application Support/WindowCleaner")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .textSelection(.enabled)
                }
            } header: {
                Text("Storage")
            }
        }
        .formStyle(.grouped)
        .padding()
        .task {
            await updateNotificationStatus()
        }
    }

    private func updateNotificationStatus() async {
        await NotificationManager.shared.updateAuthorizationStatus()
        notificationStatus = NotificationManager.shared.authorizationStatus
    }

    private func openNotificationSettings() {
        if let url = URL(string: "x-apple.systempreferences:com.apple.preference.notifications") {
            NSWorkspace.shared.open(url)
        }
    }
}

// MARK: - Subscription Settings Tab

/// Subscription and purchase management settings.
struct SubscriptionSettingsTab: View {
    @Environment(\.storeManager)
    private var storeManager

    @Environment(\.openWindow)
    private var openWindow

    @State
    private var showingStore = false

    @State
    private var isRestoring = false

    @State
    private var showingError = false

    @State
    private var errorMessage = ""

    var body: some View {
        Form {
            // Current Status
            Section {
                HStack {
                    statusIcon
                    VStack(alignment: .leading, spacing: 4) {
                        Text(storeManager.entitlement.displayName)
                            .font(.headline)
                        Text(statusSubtitle)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    Spacer()
                    if !storeManager.isPremium {
                        Button("Upgrade") {
                            showingStore = true
                        }
                        .buttonStyle(.borderedProminent)
                    }
                }
            } header: {
                Text("Subscription Status")
            }

            // Token Balance (if using consumables)
            if storeManager.tokenBalance > 0 || storeManager.isPremium {
                Section {
                    LabeledContent("Token Balance") {
                        HStack(spacing: 4) {
                            Image(systemName: "circle.grid.3x3.fill")
                                .foregroundStyle(.orange)
                            Text("\(storeManager.tokenBalance)")
                                .fontWeight(.medium)
                        }
                    }

                    Button("Purchase More Tokens") {
                        showingStore = true
                    }
                } header: {
                    Text("Tokens")
                }
            }

            // Management Actions
            Section {
                if storeManager.hasActiveSubscription {
                    Button("Manage Subscription") {
                        Task {
                            await openSubscriptionManagement()
                        }
                    }
                }

                Button {
                    Task {
                        isRestoring = true
                        defer { isRestoring = false }

                        do {
                            try await storeManager.restorePurchases()
                        } catch {
                            errorMessage = error.localizedDescription
                            showingError = true
                        }
                    }
                } label: {
                    if isRestoring {
                        HStack {
                            ProgressView()
                                .controlSize(.small)
                            Text("Restoring...")
                        }
                    } else {
                        Text("Restore Purchases")
                    }
                }
                .disabled(isRestoring)

                Button("Open Store") {
                    WindowManager.openStore(using: openWindow)
                }
            } header: {
                Text("Actions")
            }
        }
        .formStyle(.grouped)
        .padding()
        .sheet(isPresented: $showingStore) {
            StoreView()
        }
        .alert("Error", isPresented: $showingError) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(errorMessage)
        }
    }

    @ViewBuilder private var statusIcon: some View {
        switch storeManager.entitlement {
        case .none:
            Image(systemName: "person.circle")
                .font(.largeTitle)
                .foregroundStyle(.secondary)
        case .proLifetime:
            Image(systemName: "star.circle.fill")
                .font(.largeTitle)
                .foregroundStyle(.purple)
        case .subscription:
            Image(systemName: "crown.fill")
                .font(.largeTitle)
                .foregroundStyle(.yellow)
        }
    }

    private var statusSubtitle: String {
        switch storeManager.entitlement {
        case .none:
            return "Upgrade to unlock premium features"
        case .proLifetime:
            return "Lifetime access to all features"
        case let .subscription(expiration):
            if let date = expiration {
                let formatter = DateFormatter()
                formatter.dateStyle = .medium
                return "Renews on \(formatter.string(from: date))"
            }
            return "Active subscription"
        }
    }

    private func openSubscriptionManagement() async {
        // On macOS, open the App Store subscriptions page
        // This URL opens the App Store app to the user's subscriptions
        if let url = URL(string: "macappstores://apps.apple.com/account/subscriptions") {
            NSWorkspace.shared.open(url)
        }
    }
}

// MARK: - About Settings Tab

/// About information and version details.
struct AboutSettingsTab: View {
    var body: some View {
        VStack(spacing: Metrics.spacingL) {
            Spacer()

            // App Icon
            Image(nsImage: NSApp.applicationIconImage)
                .resizable()
                .frame(width: 80, height: 80)

            // App Name
            Text("WindowCleaner")
                .font(.title)
                .fontWeight(.semibold)

            // Version Info
            Text("Version \(Config.fullVersion)")
                .font(.subheadline)
                .foregroundStyle(.secondary)

            // Copyright
            Text("© 2024 Fernando Bosco")
                .font(.caption)
                .foregroundStyle(.tertiary)

            Spacer()

            // Links
            HStack(spacing: Metrics.spacingM) {
                if let githubURL = URL(string: "https://github.com.fernandobelotto.WindowCleaner") {
                    Link("GitHub", destination: githubURL)
                }

                Text("•")
                    .foregroundStyle(.tertiary)

                if let issuesURL = URL(string: "https://github.com.fernandobelotto.WindowCleaner/issues") {
                    Link("Report Issue", destination: issuesURL)
                }
            }
            .font(.caption)

            Spacer()
        }
        .padding()
    }
}

// MARK: - Preview

#Preview("Settings") {
    SettingsView()
}

#Preview("General Tab") {
    GeneralSettingsTab()
        .frame(width: 480, height: 250)
}

#Preview("Subscription Tab") {
    SubscriptionSettingsTab()
        .frame(width: 480, height: 300)
}

#Preview("About Tab") {
    AboutSettingsTab()
        .frame(width: 480, height: 280)
}
