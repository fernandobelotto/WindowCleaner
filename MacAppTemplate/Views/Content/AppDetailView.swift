import SwiftUI

// MARK: - App Detail View

/// Detail view showing comprehensive information about a selected app.
struct AppDetailView: View {
    // MARK: - Properties

    let app: TrackedApp
    let onQuit: () -> Void
    let onToggleProtection: () -> Void

    // MARK: - Body

    var body: some View {
        ScrollView {
            VStack(spacing: Metrics.spacingL) {
                headerSection
                metricsGrid
                stalenessSection
                actionsSection
            }
            .padding(Metrics.spacingL)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(nsColor: .windowBackgroundColor))
    }

    // MARK: - Header

    private var headerSection: some View {
        VStack(spacing: Metrics.spacingM) {
            // App Icon
            ZStack(alignment: .bottomTrailing) {
                Image(nsImage: app.icon)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 80, height: 80)

                if app.isActive {
                    Circle()
                        .fill(.green)
                        .frame(width: 16, height: 16)
                        .overlay(
                            Circle()
                                .stroke(Color(nsColor: .windowBackgroundColor), lineWidth: 3)
                        )
                        .offset(x: 4, y: 4)
                }
            }

            // App Name
            VStack(spacing: Metrics.spacingXS) {
                HStack(spacing: Metrics.spacingS) {
                    Text(app.name)
                        .font(.title2)
                        .fontWeight(.semibold)

                    if app.isProtected {
                        Image(systemName: "lock.fill")
                            .foregroundStyle(.orange)
                    }

                    if app.isSystemApp {
                        Text("System")
                            .font(.caption)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(.secondary.opacity(0.2))
                            .clipShape(Capsule())
                    }
                }

                Text(app.bundleIdentifier)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .textSelection(.enabled)
            }

            // Status badge
            StalenessIndicator(level: app.stalenessLevel)
        }
    }

    // MARK: - Metrics Grid

    private var metricsGrid: some View {
        LazyVGrid(columns: [
            GridItem(.flexible()),
            GridItem(.flexible()),
        ], spacing: Metrics.spacingM) {
            MetricCard(
                title: "Memory",
                value: app.formattedMemory,
                icon: "memorychip",
                color: memoryColor
            )

            MetricCard(
                title: "CPU",
                value: app.formattedCPU,
                icon: "cpu",
                color: cpuColor
            )

            MetricCard(
                title: "Windows",
                value: "\(app.windowCount)",
                icon: "macwindow",
                color: .blue
            )

            MetricCard(
                title: "Uptime",
                value: app.formattedUptime,
                icon: "clock",
                color: .purple
            )
        }
    }

    private var memoryColor: Color {
        if app.memoryUsage > 1_000_000_000 { // > 1GB
            return .red
        } else if app.memoryUsage > 500_000_000 { // > 500MB
            return .orange
        } else {
            return .blue
        }
    }

    private var cpuColor: Color {
        if app.cpuUsage > 50 {
            return .red
        } else if app.cpuUsage > 20 {
            return .orange
        } else {
            return .green
        }
    }

    // MARK: - Staleness Section

    private var stalenessSection: some View {
        VStack(alignment: .leading, spacing: Metrics.spacingS) {
            Text("Staleness Score")
                .font(.headline)

            VStack(spacing: Metrics.spacingS) {
                HStack {
                    Text("Score")
                        .foregroundStyle(.secondary)
                    Spacer()
                    Text(String(format: "%.0f%%", app.stalenessScore * 100))
                        .fontWeight(.semibold)
                }

                StalenessBar(score: app.stalenessScore, height: 8)

                HStack {
                    Text("Last Active")
                        .foregroundStyle(.secondary)
                    Spacer()
                    Text(app.formattedTimeSinceActive)
                }
                .font(.subheadline)
            }
            .padding(Metrics.spacingM)
            .background(Color.primary.opacity(0.03))
            .clipShape(RoundedRectangle(cornerRadius: Metrics.cornerRadiusM))
        }
    }

    // MARK: - Actions Section

    private var actionsSection: some View {
        VStack(spacing: Metrics.spacingS) {
            // Primary action
            Button(role: .destructive) {
                onQuit()
            } label: {
                Label("Quit App", systemImage: "xmark.circle")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .tint(.red)
            .controlSize(.large)
            .disabled(app.isProtected || app.isSystemApp)

            // Secondary actions
            HStack(spacing: Metrics.spacingS) {
                Button {
                    app.activate()
                } label: {
                    Label("Bring to Front", systemImage: "arrow.up.forward.app")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)
                .controlSize(.regular)

                Button {
                    app.hide()
                } label: {
                    Label("Hide", systemImage: "eye.slash")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)
                .controlSize(.regular)
            }

            // Protection toggle
            Button {
                onToggleProtection()
            } label: {
                Label(
                    app.isProtected ? "Remove Protection" : "Protect App",
                    systemImage: app.isProtected ? "lock.open" : "lock"
                )
                .frame(maxWidth: .infinity)
            }
            .buttonStyle(.bordered)
            .controlSize(.regular)
            .disabled(app.isSystemApp)
        }
    }
}

// MARK: - Empty Detail View

/// Placeholder view when no app is selected.
struct EmptyDetailView: View {
    var body: some View {
        VStack(spacing: Metrics.spacingM) {
            Image(systemName: "app.dashed")
                .font(.system(size: 60))
                .foregroundStyle(.tertiary)

            Text("Select an App")
                .font(.title2)
                .foregroundStyle(.secondary)

            Text("Choose an app from the sidebar to view its details and manage it.")
                .font(.subheadline)
                .foregroundStyle(.tertiary)
                .multilineTextAlignment(.center)
                .frame(maxWidth: 250)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

// MARK: - Preview

#Preview("Empty State") {
    EmptyDetailView()
        .frame(width: 400, height: 500)
}
