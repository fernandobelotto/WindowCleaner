import SwiftUI

// MARK: - Cleanup Selection View

/// Sheet view for selecting which stale apps to quit during cleanup.
/// Shows all stale apps with checkboxes, memory info, and quick actions.
struct CleanupSelectionView: View {
    // MARK: - Properties

    @Bindable var viewModel: AppTrackingViewModel

    // MARK: - Body

    var body: some View {
        VStack(spacing: 0) {
            headerSection
            Divider()
            appListSection
            Divider()
            footerSection
        }
        .frame(width: 480, height: 520)
        .background(Color(nsColor: .windowBackgroundColor))
    }

    // MARK: - Header Section

    private var headerSection: some View {
        VStack(spacing: Metrics.spacingS) {
            // Title
            HStack {
                Image(systemName: "sparkles")
                    .font(.title2)
                    .foregroundStyle(.orange)

                VStack(alignment: .leading, spacing: 2) {
                    Text("Clean Up Apps")
                        .font(.headline)
                    Text("\(viewModel.pendingCleanupApps.count) stale apps found")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Spacer()
            }

            // Quick actions
            HStack(spacing: Metrics.spacingS) {
                Button("Select All") {
                    viewModel.selectAllForCleanup()
                }
                .buttonStyle(.bordered)
                .controlSize(.small)
                .disabled(viewModel.allCleanupAppsSelected)

                Button("Select None") {
                    viewModel.selectNoneForCleanup()
                }
                .buttonStyle(.bordered)
                .controlSize(.small)
                .disabled(viewModel.selectedCleanupApps.isEmpty)

                Spacer()

                // Memory summary
                HStack(spacing: 4) {
                    Image(systemName: "memorychip")
                        .font(.caption)
                    Text(viewModel.formattedSelectedCleanupMemory)
                        .font(.caption)
                        .fontWeight(.medium)
                    Text("to free")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .padding(.horizontal, Metrics.spacingS)
                .padding(.vertical, Metrics.spacingXS)
                .background(Color.orange.opacity(0.1))
                .clipShape(Capsule())
            }
        }
        .padding(Metrics.spacingM)
    }

    // MARK: - App List Section

    private var appListSection: some View {
        ScrollView {
            LazyVStack(spacing: 0) {
                ForEach(viewModel.pendingCleanupApps) { app in
                    CleanupAppRow(
                        app: app,
                        isSelected: viewModel.isSelectedForCleanup(app),
                        onToggle: {
                            viewModel.toggleCleanupSelection(for: app)
                        }
                    )

                    if app.id != viewModel.pendingCleanupApps.last?.id {
                        Divider()
                            .padding(.horizontal, Metrics.spacingM)
                    }
                }
            }
            .padding(.vertical, Metrics.spacingXS)
        }
    }

    // MARK: - Footer Section

    private var footerSection: some View {
        HStack {
            // Selection count
            Text("\(viewModel.selectedCleanupCount) of \(viewModel.pendingCleanupApps.count) selected")
                .font(.caption)
                .foregroundStyle(.secondary)

            Spacer()

            // Action buttons
            Button("Cancel") {
                viewModel.cancelCleanup()
            }
            .buttonStyle(.bordered)
            .controlSize(.regular)
            .keyboardShortcut(.cancelAction)

            Button("Quit Selected Apps") {
                viewModel.executeCleanup()
            }
            .buttonStyle(.borderedProminent)
            .tint(.orange)
            .controlSize(.regular)
            .disabled(viewModel.selectedCleanupApps.isEmpty)
            .keyboardShortcut(.defaultAction)
        }
        .padding(Metrics.spacingM)
    }
}

// MARK: - Cleanup App Row

/// A row in the cleanup selection list with checkbox and app details.
struct CleanupAppRow: View {
    // MARK: - Properties

    let app: TrackedApp
    let isSelected: Bool
    let onToggle: () -> Void

    // MARK: - State

    @State private var isHovered: Bool = false

    // MARK: - Body

    var body: some View {
        HStack(spacing: Metrics.spacingM) {
            // Checkbox
            Button {
                onToggle()
            } label: {
                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .font(.title3)
                    .foregroundStyle(isSelected ? .orange : .secondary)
            }
            .buttonStyle(.plain)

            // App icon
            Image(nsImage: app.icon)
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: 36, height: 36)

            // App info
            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: Metrics.spacingXS) {
                    Text(app.name)
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .lineLimit(1)

                    StalenessIndicator(level: app.stalenessLevel, compact: true)
                }

                HStack(spacing: Metrics.spacingS) {
                    // Memory
                    Label(app.formattedMemory, systemImage: "memorychip")

                    Text("•")
                        .foregroundStyle(.tertiary)

                    // Last active
                    Label(app.formattedTimeSinceActive, systemImage: "clock")
                }
                .font(.caption)
                .foregroundStyle(.secondary)
            }

            Spacer()

            // Staleness score
            VStack(alignment: .trailing, spacing: 2) {
                Text(String(format: "%.0f%%", app.stalenessScore * 100))
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundStyle(stalenessColor)

                Text("stale")
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
            }
        }
        .padding(.horizontal, Metrics.spacingM)
        .padding(.vertical, Metrics.spacingS)
        .background(isHovered ? Color.primary.opacity(0.03) : Color.clear)
        .contentShape(Rectangle())
        .onTapGesture {
            onToggle()
        }
        .onHover { hovering in
            isHovered = hovering
        }
    }

    // MARK: - Helpers

    private var stalenessColor: Color {
        switch app.stalenessLevel {
        case .active, .recent: .green
        case .idle: .yellow
        case .stale: .orange
        case .veryStale: .red
        }
    }
}

// MARK: - Preview

#Preview("Cleanup Selection") {
    CleanupSelectionView(viewModel: AppTrackingViewModel())
}
