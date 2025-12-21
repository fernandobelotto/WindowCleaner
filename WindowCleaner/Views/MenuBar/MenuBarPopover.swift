import SwiftUI

// MARK: - Menu Bar Popover

/// The content view displayed in the menu bar popover.
/// Shows a quick overview of stale apps with actions.
struct MenuBarPopover: View {
    // MARK: - Environment

    @Environment(\.openWindow) private var openWindow

    // MARK: - State

    @State private var viewModel = AppTrackingViewModel()
    @State private var isHovering: Bool = false

    // MARK: - Body

    var body: some View {
        VStack(spacing: 0) {
            headerSection
            Divider()
            appListSection
            Divider()
            footerSection
        }
        .frame(width: 320)
        .background(.background)
        .sheet(isPresented: $viewModel.showCleanupSelectionSheet) {
            CleanupSelectionView(viewModel: viewModel)
        }
    }

    // MARK: - Header

    private var headerSection: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text("Window Cleaner")
                    .font(.headline)
                Text("\(viewModel.allApps.count) apps running")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            if viewModel.staleAppCount > 0 {
                staleBadge
            }
        }
        .padding(.horizontal, Metrics.spacingM)
        .padding(.vertical, Metrics.spacingS)
    }

    private var staleBadge: some View {
        HStack(spacing: 4) {
            Image(systemName: "exclamationmark.circle.fill")
                .foregroundStyle(.orange)
            Text("\(viewModel.staleAppCount) stale")
                .font(.caption)
                .fontWeight(.medium)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(.orange.opacity(0.15))
        .clipShape(Capsule())
    }

    // MARK: - App List

    private var appListSection: some View {
        ScrollView {
            LazyVStack(spacing: 0) {
                if viewModel.displayedApps.isEmpty {
                    emptyState
                } else {
                    ForEach(viewModel.displayedApps.prefix(8)) { app in
                        MenuBarAppRow(app: app) {
                            viewModel.quitApp(app)
                        }
                        .padding(.horizontal, Metrics.spacingS)
                        .padding(.vertical, Metrics.spacingXS)

                        if app.id != viewModel.displayedApps.prefix(8).last?.id {
                            Divider()
                                .padding(.horizontal, Metrics.spacingS)
                        }
                    }
                }
            }
            .padding(.vertical, Metrics.spacingXS)
        }
        .frame(maxHeight: 320)
    }

    private var emptyState: some View {
        VStack(spacing: Metrics.spacingS) {
            Image(systemName: "checkmark.circle")
                .font(.largeTitle)
                .foregroundStyle(.green)
            Text("All apps are active")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, Metrics.spacingL)
    }

    // MARK: - Footer

    private var footerSection: some View {
        HStack {
            if viewModel.staleAppCount > 0 {
                Button {
                    viewModel.prepareCleanup()
                } label: {
                    Label("Clean Up", systemImage: "sparkles")
                }
                .buttonStyle(.borderedProminent)
                .tint(.orange)
                .controlSize(.small)
            }

            Spacer()

            Button {
                openMainWindow()
            } label: {
                Label("Open Window", systemImage: "macwindow")
            }
            .buttonStyle(.bordered)
            .controlSize(.small)
        }
        .padding(.horizontal, Metrics.spacingM)
        .padding(.vertical, Metrics.spacingS)
    }

    // MARK: - Actions

    private func openMainWindow() {
        NSApp.activate(ignoringOtherApps: true)
        // Open the main window group
        if let window = NSApp.windows.first(where: { $0.identifier?.rawValue == "main" }) {
            window.makeKeyAndOrderFront(nil)
        } else {
            // Fallback: activate the app
            NSApp.activate(ignoringOtherApps: true)
        }
    }
}

// MARK: - Menu Bar App Row

/// A compact row for displaying an app in the menu bar popover.
struct MenuBarAppRow: View {
    // MARK: - Properties

    let app: TrackedApp
    let onQuit: () -> Void

    // MARK: - State

    @State private var isHovered: Bool = false

    // MARK: - Body

    var body: some View {
        HStack(spacing: Metrics.spacingS) {
            // App Icon
            Image(nsImage: app.icon)
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: 24, height: 24)

            // App Info
            VStack(alignment: .leading, spacing: 2) {
                Text(app.name)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .lineLimit(1)

                HStack(spacing: Metrics.spacingXS) {
                    Text(app.formattedMemory)
                        .font(.caption)
                        .foregroundStyle(.secondary)

                    Text("•")
                        .font(.caption)
                        .foregroundStyle(.tertiary)

                    Text(app.formattedTimeSinceActive)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }

            Spacer()

            // Staleness indicator
            StalenessIndicator(level: app.stalenessLevel, compact: true)

            // Quit button (shown on hover)
            if isHovered && !app.isProtected && !app.isSystemApp {
                Button {
                    onQuit()
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundStyle(.secondary)
                }
                .buttonStyle(.plain)
                .help("Quit \(app.name)")
            }
        }
        .padding(.horizontal, Metrics.spacingXS)
        .padding(.vertical, Metrics.spacingXS)
        .background(isHovered ? Color.primary.opacity(0.05) : Color.clear)
        .clipShape(RoundedRectangle(cornerRadius: Metrics.cornerRadiusS))
        .onHover { hovering in
            isHovered = hovering
        }
    }
}

// MARK: - Preview

#Preview {
    MenuBarPopover()
        .frame(height: 400)
}
