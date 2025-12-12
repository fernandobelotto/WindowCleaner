import SwiftUI

// MARK: - Tracking Settings Tab

/// Settings for configuring app tracking behavior.
struct TrackingSettingsTab: View {
    // MARK: - App Storage

    @AppStorage(UserDefaultsKey.pollingInterval)
    private var pollingInterval: Double = 5.0

    @AppStorage(UserDefaultsKey.historyRetentionDays)
    private var historyRetentionDays: Int = 30

    @AppStorage(UserDefaultsKey.trackHiddenApps)
    private var trackHiddenApps: Bool = true

    @AppStorage(UserDefaultsKey.showSystemApps)
    private var showSystemApps: Bool = false

    // MARK: - Body

    var body: some View {
        Form {
            pollingSection
            historySection
            filteringSection
        }
        .formStyle(.grouped)
        .padding()
    }

    // MARK: - Polling Section

    private var pollingSection: some View {
        Section {
            Picker("Update Interval", selection: $pollingInterval) {
                ForEach(ProcessMonitor.PollingPreset.allCases) { preset in
                    Text(preset.label).tag(preset.rawValue)
                }
            }
            .pickerStyle(.menu)

            Text(pollingDescription)
                .font(.caption)
                .foregroundStyle(.secondary)
        } header: {
            Text("Monitoring")
        } footer: {
            Text("How often to refresh memory and CPU usage for running apps.")
                .font(.caption)
                .foregroundStyle(.tertiary)
        }
    }

    private var pollingDescription: String {
        if let preset = ProcessMonitor.PollingPreset(rawValue: pollingInterval) {
            return preset.description
        }
        return "Custom interval"
    }

    // MARK: - History Section

    private var historySection: some View {
        Section {
            Picker("Keep History For", selection: $historyRetentionDays) {
                Text("7 days").tag(7)
                Text("14 days").tag(14)
                Text("30 days").tag(30)
                Text("90 days").tag(90)
                Text("1 year").tag(365)
                Text("Forever").tag(0)
            }
            .pickerStyle(.menu)

            Button("Clear History Now...") {
                // TODO: Implement clear history
            }
            .foregroundStyle(.red)
        } header: {
            Text("Usage History")
        } footer: {
            Text("Historical usage data is used to show insights and trends. Older data will be automatically deleted.")
                .font(.caption)
                .foregroundStyle(.tertiary)
        }
    }

    // MARK: - Filtering Section

    private var filteringSection: some View {
        Section {
            Toggle("Track hidden apps", isOn: $trackHiddenApps)

            Toggle("Show system apps", isOn: $showSystemApps)
        } header: {
            Text("App Filtering")
        } footer: {
            Text("Hidden apps are apps you've hidden with ⌘H. System apps include Finder, Dock, and other macOS components.")
                .font(.caption)
                .foregroundStyle(.tertiary)
        }
    }
}

// MARK: - UserDefaults Keys

extension UserDefaultsKey {
    static let historyRetentionDays = "historyRetentionDays"
    static let trackHiddenApps = "trackHiddenApps"
    static let showSystemApps = "showSystemApps"
}

// MARK: - Preview

#Preview {
    TrackingSettingsTab()
        .frame(width: 480, height: 400)
}
