import AppKit
import SwiftUI

// MARK: - Protected Apps Tab

/// Settings for managing apps that should never be suggested for cleanup.
struct ProtectedAppsTab: View {
    // MARK: - State

    @State private var protectedBundleIds: Set<String> = []
    @State private var showAddSheet = false
    @State private var searchQuery = ""

    // MARK: - Body

    var body: some View {
        VStack(spacing: 0) {
            headerSection
            Divider()
            listSection
            Divider()
            footerSection
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .onAppear {
            loadProtectedApps()
        }
        .sheet(isPresented: $showAddSheet) {
            AddProtectedAppSheet(
                protectedBundleIds: $protectedBundleIds,
                onSave: saveProtectedApps
            )
        }
    }

    // MARK: - Header

    private var headerSection: some View {
        VStack(alignment: .leading, spacing: Metrics.spacingS) {
            Text("Protected Apps")
                .font(.headline)

            Text("These apps will never be suggested for cleanup and cannot be quit from Window Cleaner.")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
    }

    // MARK: - List Section

    private var listSection: some View {
        Group {
            if protectedBundleIds.isEmpty {
                emptyState
            } else {
                ScrollView {
                    LazyVStack(spacing: 1) {
                        ForEach(sortedProtectedApps, id: \.self) { bundleId in
                            ProtectedAppRow(
                                bundleId: bundleId,
                                onRemove: {
                                    removeProtectedApp(bundleId)
                                }
                            )
                        }
                    }
                    .padding(.horizontal, Metrics.spacingS)
                    .padding(.vertical, Metrics.spacingS)
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var emptyState: some View {
        VStack(spacing: Metrics.spacingM) {
            Image(systemName: "lock.shield")
                .font(.system(size: 40))
                .foregroundStyle(.tertiary)

            Text("No Protected Apps")
                .font(.subheadline)
                .foregroundStyle(.secondary)

            Text("Add apps you want to protect from cleanup suggestions.")
                .font(.caption)
                .foregroundStyle(.tertiary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding()
    }

    private var sortedProtectedApps: [String] {
        protectedBundleIds.sorted { lhs, rhs in
            let lhsName = appName(for: lhs)
            let rhsName = appName(for: rhs)
            return lhsName.localizedCaseInsensitiveCompare(rhsName) == .orderedAscending
        }
    }

    // MARK: - Footer

    private var footerSection: some View {
        HStack {
            Text("\(protectedBundleIds.count) app\(protectedBundleIds.count == 1 ? "" : "s") protected")
                .font(.caption)
                .foregroundStyle(.secondary)

            Spacer()

            Button {
                showAddSheet = true
            } label: {
                Label("Add App", systemImage: "plus")
            }
            .buttonStyle(.bordered)
            .controlSize(.small)
        }
        .padding()
    }

    // MARK: - Helpers

    private func appName(for bundleId: String) -> String {
        if let url = NSWorkspace.shared.urlForApplication(withBundleIdentifier: bundleId),
           let bundle = Bundle(url: url),
           let name = bundle.object(forInfoDictionaryKey: "CFBundleName") as? String
        {
            return name
        }
        return bundleId.components(separatedBy: ".").last ?? bundleId
    }

    private func loadProtectedApps() {
        if let data = UserDefaults.standard.data(forKey: UserDefaultsKey.protectedApps),
           let ids = try? JSONDecoder().decode(Set<String>.self, from: data)
        {
            protectedBundleIds = ids
        }
    }

    private func saveProtectedApps() {
        if let data = try? JSONEncoder().encode(protectedBundleIds) {
            UserDefaults.standard.set(data, forKey: UserDefaultsKey.protectedApps)
        }
    }

    private func removeProtectedApp(_ bundleId: String) {
        protectedBundleIds.remove(bundleId)
        saveProtectedApps()
    }
}

// MARK: - Protected App Row

struct ProtectedAppRow: View {
    let bundleId: String
    let onRemove: () -> Void

    @State private var isHovered = false

    var body: some View {
        HStack(spacing: Metrics.spacingS) {
            // App Icon
            appIcon
                .frame(width: 32, height: 32)

            // App Info
            VStack(alignment: .leading, spacing: 2) {
                Text(appName)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .lineLimit(1)

                Text(bundleId)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }

            Spacer()

            // Remove button
            if isHovered {
                Button {
                    onRemove()
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundStyle(.secondary)
                }
                .buttonStyle(.plain)
                .help("Remove protection")
            }
        }
        .padding(.horizontal, Metrics.spacingS)
        .padding(.vertical, Metrics.spacingXS)
        .background(isHovered ? Color.primary.opacity(0.05) : Color.clear)
        .clipShape(RoundedRectangle(cornerRadius: Metrics.cornerRadiusS))
        .onHover { hovering in
            isHovered = hovering
        }
    }

    private var appName: String {
        if let url = NSWorkspace.shared.urlForApplication(withBundleIdentifier: bundleId),
           let bundle = Bundle(url: url),
           let name = bundle.object(forInfoDictionaryKey: "CFBundleName") as? String
        {
            return name
        }
        return bundleId.components(separatedBy: ".").last ?? bundleId
    }

    @ViewBuilder
    private var appIcon: some View {
        if let url = NSWorkspace.shared.urlForApplication(withBundleIdentifier: bundleId) {
            Image(nsImage: NSWorkspace.shared.icon(forFile: url.path))
                .resizable()
                .aspectRatio(contentMode: .fit)
        } else {
            Image(systemName: "app")
                .font(.title2)
                .foregroundStyle(.secondary)
        }
    }
}

// MARK: - Add Protected App Sheet

struct AddProtectedAppSheet: View {
    @Environment(\.dismiss) private var dismiss

    @Binding var protectedBundleIds: Set<String>
    let onSave: () -> Void

    @State private var searchQuery = ""
    @State private var runningApps: [NSRunningApplication] = []

    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Text("Add Protected App")
                    .font(.headline)
                Spacer()
                Button {
                    dismiss()
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundStyle(.secondary)
                }
                .buttonStyle(.plain)
            }
            .padding()

            Divider()

            // Search
            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundStyle(.secondary)
                TextField("Search running apps...", text: $searchQuery)
                    .textFieldStyle(.plain)
            }
            .padding(Metrics.spacingS)
            .background(Color.primary.opacity(0.05))
            .clipShape(RoundedRectangle(cornerRadius: Metrics.cornerRadiusS))
            .padding()

            Divider()

            // App List
            ScrollView {
                LazyVStack(spacing: 1) {
                    ForEach(filteredApps, id: \.processIdentifier) { app in
                        AddAppRow(
                            app: app,
                            isProtected: protectedBundleIds.contains(app.bundleIdentifier ?? ""),
                            onToggle: {
                                toggleProtection(for: app)
                            }
                        )
                    }
                }
                .padding(Metrics.spacingS)
            }

            Divider()

            // Footer
            HStack {
                Text("\(filteredApps.count) apps")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Spacer()
                Button("Done") {
                    dismiss()
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.small)
            }
            .padding()
        }
        .frame(width: 400, height: 500)
        .onAppear {
            loadRunningApps()
        }
    }

    private var filteredApps: [NSRunningApplication] {
        let apps = runningApps.filter { app in
            app.activationPolicy == .regular && app.bundleIdentifier != nil
        }

        if searchQuery.isEmpty {
            return apps
        }

        return apps.filter { app in
            let name = app.localizedName ?? ""
            let bundleId = app.bundleIdentifier ?? ""
            return name.localizedCaseInsensitiveContains(searchQuery)
                || bundleId.localizedCaseInsensitiveContains(searchQuery)
        }
    }

    private func loadRunningApps() {
        runningApps = NSWorkspace.shared.runningApplications.sorted { lhs, rhs in
            let lhsName = lhs.localizedName ?? ""
            let rhsName = rhs.localizedName ?? ""
            return lhsName.localizedCaseInsensitiveCompare(rhsName) == .orderedAscending
        }
    }

    private func toggleProtection(for app: NSRunningApplication) {
        guard let bundleId = app.bundleIdentifier else { return }

        if protectedBundleIds.contains(bundleId) {
            protectedBundleIds.remove(bundleId)
        } else {
            protectedBundleIds.insert(bundleId)
        }
        onSave()
    }
}

// MARK: - Add App Row

struct AddAppRow: View {
    let app: NSRunningApplication
    let isProtected: Bool
    let onToggle: () -> Void

    var body: some View {
        HStack(spacing: Metrics.spacingS) {
            // App Icon
            if let icon = app.icon {
                Image(nsImage: icon)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 28, height: 28)
            } else {
                Image(systemName: "app")
                    .frame(width: 28, height: 28)
            }

            // App Name
            VStack(alignment: .leading, spacing: 1) {
                Text(app.localizedName ?? "Unknown")
                    .font(.subheadline)
                    .lineLimit(1)

                Text(app.bundleIdentifier ?? "")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }

            Spacer()

            // Toggle
            Button {
                onToggle()
            } label: {
                Image(systemName: isProtected ? "checkmark.circle.fill" : "circle")
                    .foregroundStyle(isProtected ? .green : .secondary)
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, Metrics.spacingS)
        .padding(.vertical, Metrics.spacingXS)
        .background(Color.primary.opacity(0.02))
        .clipShape(RoundedRectangle(cornerRadius: Metrics.cornerRadiusS))
    }
}

// MARK: - UserDefaults Key

extension UserDefaultsKey {
    static let protectedApps = "protectedApps"
}

// MARK: - Preview

#Preview {
    ProtectedAppsTab()
        .frame(width: 480, height: 400)
}
