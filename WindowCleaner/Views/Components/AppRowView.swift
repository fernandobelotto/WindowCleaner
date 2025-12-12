import SwiftUI

// MARK: - App Row View

/// A row displaying an app with its metrics for the sidebar list.
struct AppRowView: View {
    // MARK: - Properties

    let app: TrackedApp
    var isSelected: Bool = false
    var showDetailedMetrics: Bool = true

    // MARK: - State

    @State private var isHovered: Bool = false

    // MARK: - Body

    var body: some View {
        HStack(spacing: Metrics.spacingS) {
            appIcon
            appInfo
            Spacer()
            metricsSection
        }
        .padding(.horizontal, Metrics.spacingS)
        .padding(.vertical, Metrics.spacingS)
        .background(backgroundColor)
        .clipShape(RoundedRectangle(cornerRadius: Metrics.cornerRadiusM))
        .onHover { hovering in
            withAnimation(.easeInOut(duration: 0.15)) {
                isHovered = hovering
            }
        }
    }

    // MARK: - App Icon

    private var appIcon: some View {
        ZStack(alignment: .bottomTrailing) {
            Image(nsImage: app.icon)
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: 36, height: 36)

            // Active indicator
            if app.isActive {
                Circle()
                    .fill(.green)
                    .frame(width: 10, height: 10)
                    .overlay(
                        Circle()
                            .stroke(.background, lineWidth: 2)
                    )
                    .offset(x: 2, y: 2)
            }
        }
    }

    // MARK: - App Info

    private var appInfo: some View {
        VStack(alignment: .leading, spacing: 2) {
            HStack(spacing: Metrics.spacingXS) {
                Text(app.name)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .lineLimit(1)

                if app.isProtected {
                    Image(systemName: "lock.fill")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
            }

            if showDetailedMetrics {
                HStack(spacing: Metrics.spacingS) {
                    Label(app.formattedMemory, systemImage: "memorychip")
                    Label(app.formattedTimeSinceActive, systemImage: "clock")
                }
                .font(.caption)
                .foregroundStyle(.secondary)
            }
        }
    }

    // MARK: - Metrics Section

    private var metricsSection: some View {
        VStack(alignment: .trailing, spacing: 4) {
            StalenessIndicator(level: app.stalenessLevel, compact: true)

            if showDetailedMetrics && app.windowCount > 0 {
                Label("\(app.windowCount)", systemImage: "macwindow")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
        }
    }

    // MARK: - Background

    private var backgroundColor: Color {
        if isSelected {
            return Color.accentColor.opacity(0.15)
        } else if isHovered {
            return Color.primary.opacity(0.05)
        } else {
            return Color.clear
        }
    }
}

// MARK: - App Row Compact

/// A more compact version of AppRowView for space-constrained contexts.
struct AppRowCompact: View {
    let app: TrackedApp
    var isSelected: Bool = false

    var body: some View {
        HStack(spacing: Metrics.spacingS) {
            Image(nsImage: app.icon)
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: 24, height: 24)

            Text(app.name)
                .font(.subheadline)
                .lineLimit(1)

            Spacer()

            Text(app.formattedMemory)
                .font(.caption)
                .foregroundStyle(.secondary)

            StalenessIndicator(level: app.stalenessLevel, compact: true)
        }
        .padding(.horizontal, Metrics.spacingS)
        .padding(.vertical, Metrics.spacingXS)
        .background(isSelected ? Color.accentColor.opacity(0.15) : Color.clear)
        .clipShape(RoundedRectangle(cornerRadius: Metrics.cornerRadiusS))
    }
}

// MARK: - Preview

#Preview("App Row") {
    VStack(spacing: 8) {
        Text("Standard Row")
            .font(.caption)
            .foregroundStyle(.secondary)

        // We can't create real TrackedApp in preview, so this is just for structure
        RoundedRectangle(cornerRadius: 8)
            .fill(Color.gray.opacity(0.1))
            .frame(height: 60)
            .overlay {
                Text("TrackedApp would appear here")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
    }
    .padding()
    .frame(width: 300)
}
