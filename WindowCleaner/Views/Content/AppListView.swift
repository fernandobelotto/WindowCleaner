import SwiftUI

// MARK: - App List View

/// Sidebar view showing the list of running applications.
struct AppListView: View {
    // MARK: - Properties

    @Bindable var viewModel: AppTrackingViewModel

    // MARK: - Body

    var body: some View {
        VStack(spacing: 0) {
            headerSection
            Divider()
            filterSection
            Divider()
            appList
            Divider()
            footerSection
        }
    }

    // MARK: - Header

    private var headerSection: some View {
        VStack(spacing: Metrics.spacingS) {
            // Search
            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundStyle(.secondary)
                TextField("Search apps...", text: $viewModel.searchQuery)
                    .textFieldStyle(.plain)

                if !viewModel.searchQuery.isEmpty {
                    Button {
                        viewModel.searchQuery = ""
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundStyle(.secondary)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(Metrics.spacingS)
            .background(Color.primary.opacity(0.05))
            .clipShape(RoundedRectangle(cornerRadius: Metrics.cornerRadiusS))
        }
        .padding(Metrics.spacingS)
    }

    // MARK: - Filter Section

    private var filterSection: some View {
        HStack(spacing: Metrics.spacingS) {
            // Filter picker
            Picker("Filter", selection: $viewModel.filterOption) {
                ForEach(TrackedApp.FilterOption.allCases) { option in
                    Label(option.rawValue, systemImage: option.systemImage)
                        .tag(option)
                }
            }
            .pickerStyle(.segmented)
            .labelsHidden()

            // Sort menu
            Menu {
                ForEach(TrackedApp.SortOption.allCases) { option in
                    Button {
                        if viewModel.sortOption == option {
                            viewModel.sortAscending.toggle()
                        } else {
                            viewModel.sortOption = option
                            viewModel.sortAscending = false
                        }
                    } label: {
                        HStack {
                            Label(option.rawValue, systemImage: option.systemImage)
                            if viewModel.sortOption == option {
                                Image(systemName: viewModel.sortAscending ? "chevron.up" : "chevron.down")
                            }
                        }
                    }
                }
            } label: {
                Image(systemName: "arrow.up.arrow.down")
            }
            .menuStyle(.borderlessButton)
            .frame(width: 30)
        }
        .padding(.horizontal, Metrics.spacingS)
        .padding(.vertical, Metrics.spacingXS)
    }

    // MARK: - App List

    private var appList: some View {
        Group {
            if viewModel.displayedApps.isEmpty {
                emptyState
            } else {
                ScrollView {
                    LazyVStack(spacing: 2) {
                        ForEach(viewModel.displayedApps) { app in
                            AppRowView(
                                app: app,
                                isSelected: viewModel.selectedApp?.id == app.id
                            )
                            .contentShape(Rectangle())
                            .onTapGesture {
                                viewModel.selectApp(app)
                            }
                            .contextMenu {
                                appContextMenu(for: app)
                            }
                        }
                    }
                    .padding(.horizontal, Metrics.spacingXS)
                    .padding(.vertical, Metrics.spacingXS)
                }
            }
        }
    }

    private var emptyState: some View {
        VStack(spacing: Metrics.spacingM) {
            Image(systemName: emptyStateIcon)
                .font(.system(size: 40))
                .foregroundStyle(.secondary)

            Text(emptyStateMessage)
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding()
    }

    private var emptyStateIcon: String {
        if !viewModel.searchQuery.isEmpty {
            return "magnifyingglass"
        } else if viewModel.filterOption == .stale {
            return "checkmark.circle"
        } else if viewModel.filterOption == .heavy {
            return "leaf"
        } else {
            return "app.dashed"
        }
    }

    private var emptyStateMessage: String {
        if !viewModel.searchQuery.isEmpty {
            return "No apps match '\(viewModel.searchQuery)'"
        } else if viewModel.filterOption == .stale {
            return "No stale apps found.\nAll your apps are being used!"
        } else if viewModel.filterOption == .heavy {
            return "No memory-heavy apps running"
        } else {
            return "No apps are running"
        }
    }

    // MARK: - Context Menu

    @ViewBuilder
    private func appContextMenu(for app: TrackedApp) -> some View {
        Button {
            app.activate()
        } label: {
            Label("Bring to Front", systemImage: "arrow.up.forward.app")
        }

        Button {
            app.hide()
        } label: {
            Label("Hide", systemImage: "eye.slash")
        }

        Divider()

        Button {
            viewModel.toggleProtection(for: app)
        } label: {
            if app.isProtected {
                Label("Remove Protection", systemImage: "lock.open")
            } else {
                Label("Protect App", systemImage: "lock")
            }
        }

        Divider()

        Button(role: .destructive) {
            viewModel.quitApp(app)
        } label: {
            Label("Quit", systemImage: "xmark.circle")
        }
        .disabled(app.isProtected || app.isSystemApp)
    }

    // MARK: - Footer

    private var footerSection: some View {
        HStack {
            // Stats
            VStack(alignment: .leading, spacing: 2) {
                Text("\(viewModel.displayedApps.count) apps")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Text(viewModel.formattedTotalMemory)
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
            }

            Spacer()

            // Quick actions
            if viewModel.staleAppCount > 0 {
                Button {
                    viewModel.prepareCleanup()
                } label: {
                    Label("Clean Up (\(viewModel.staleAppCount))", systemImage: "sparkles")
                }
                .buttonStyle(.bordered)
                .controlSize(.small)
                .tint(.orange)
            }

            Button {
                viewModel.refresh()
            } label: {
                Image(systemName: "arrow.clockwise")
            }
            .buttonStyle(.bordered)
            .controlSize(.small)
        }
        .padding(Metrics.spacingS)
    }
}

// MARK: - Preview

#Preview {
    AppListView(viewModel: AppTrackingViewModel())
        .frame(width: 280, height: 500)
}
