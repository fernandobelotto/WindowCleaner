import AppKit
import SwiftUI

// MARK: - Top Apps View

/// Displays the most used apps in a ranked list.
struct TopAppsView: View {
    let records: [AppUsageRecord]

    @State private var sortBy: TopAppsSortOption = .activeTime

    var body: some View {
        VStack(spacing: 0) {
            sortPicker
            Divider()
            appsList
        }
    }

    // MARK: - Sort Picker

    private var sortPicker: some View {
        HStack {
            Text("Sort by")
                .font(.caption)
                .foregroundStyle(.secondary)

            Picker("Sort by", selection: $sortBy) {
                ForEach(TopAppsSortOption.allCases) { option in
                    Text(option.label).tag(option)
                }
            }
            .pickerStyle(.segmented)
            .labelsHidden()
            .frame(maxWidth: 300)

            Spacer()
        }
        .padding(.bottom, Metrics.spacingS)
    }

    // MARK: - Apps List

    private var appsList: some View {
        Group {
            if sortedApps.isEmpty {
                emptyState
            } else {
                LazyVStack(spacing: 2) {
                    ForEach(Array(sortedApps.prefix(10).enumerated()), id: \.element.bundleIdentifier) { index, appData in
                        TopAppRow(rank: index + 1, data: appData, sortOption: sortBy)
                    }
                }
            }
        }
    }

    // MARK: - Empty State

    private var emptyState: some View {
        VStack(spacing: Metrics.spacingM) {
            Image(systemName: "app.badge.checkmark")
                .font(.system(size: 28))
                .foregroundStyle(.tertiary)

            Text("No apps tracked yet")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding()
    }

    // MARK: - Sorted Apps

    private var sortedApps: [AggregatedAppData] {
        let grouped = Dictionary(grouping: records) { $0.bundleIdentifier }

        let aggregated = grouped.map { bundleId, appRecords -> AggregatedAppData in
            let totalActiveTime = appRecords.reduce(0) { $0 + $1.totalActiveTime }
            let totalActivations = appRecords.reduce(0) { $0 + $1.activationCount }
            let peakMemory = appRecords.map(\.peakMemoryUsage).max() ?? 0
            let appName = appRecords.first?.appName ?? bundleId

            return AggregatedAppData(
                bundleIdentifier: bundleId,
                appName: appName,
                totalActiveTime: totalActiveTime,
                totalActivations: totalActivations,
                peakMemory: peakMemory
            )
        }

        switch sortBy {
        case .activeTime:
            return aggregated.sorted { $0.totalActiveTime > $1.totalActiveTime }
        case .activations:
            return aggregated.sorted { $0.totalActivations > $1.totalActivations }
        case .memory:
            return aggregated.sorted { $0.peakMemory > $1.peakMemory }
        }
    }
}

// MARK: - Top Apps Sort Option

enum TopAppsSortOption: String, CaseIterable, Identifiable {
    case activeTime = "Active Time"
    case activations = "Activations"
    case memory = "Memory"

    var id: String { rawValue }
    var label: String { rawValue }
}

// MARK: - Aggregated App Data

struct AggregatedAppData {
    let bundleIdentifier: String
    let appName: String
    let totalActiveTime: TimeInterval
    let totalActivations: Int
    let peakMemory: UInt64

    var formattedActiveTime: String {
        let formatter = DateComponentsFormatter()
        formatter.allowedUnits = [.hour, .minute]
        formatter.unitsStyle = .abbreviated
        formatter.maximumUnitCount = 2
        return formatter.string(from: totalActiveTime) ?? "0m"
    }

    var formattedPeakMemory: String {
        ByteCountFormatter.string(fromByteCount: Int64(peakMemory), countStyle: .memory)
    }
}

// MARK: - Top App Row

struct TopAppRow: View {
    let rank: Int
    let data: AggregatedAppData
    let sortOption: TopAppsSortOption

    @State private var isHovered = false

    var body: some View {
        HStack(spacing: Metrics.spacingS) {
            // Rank badge
            rankBadge

            // App icon
            appIcon
                .frame(width: 28, height: 28)

            // App name
            VStack(alignment: .leading, spacing: 1) {
                Text(data.appName)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .lineLimit(1)

                Text(data.bundleIdentifier)
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
                    .lineLimit(1)
            }

            Spacer()

            // Metric value
            metricValue
        }
        .padding(.horizontal, Metrics.spacingS)
        .padding(.vertical, Metrics.spacingXS)
        .background(isHovered ? Color.primary.opacity(0.05) : Color.clear)
        .clipShape(RoundedRectangle(cornerRadius: Metrics.cornerRadiusS))
        .onHover { hovering in
            isHovered = hovering
        }
    }

    // MARK: - Rank Badge

    private var rankBadge: some View {
        ZStack {
            Circle()
                .fill(rankColor.opacity(0.15))
                .frame(width: 24, height: 24)

            Text("\(rank)")
                .font(.caption)
                .fontWeight(.bold)
                .foregroundStyle(rankColor)
        }
    }

    private var rankColor: Color {
        switch rank {
        case 1: .yellow
        case 2: .gray
        case 3: .orange
        default: .secondary
        }
    }

    // MARK: - App Icon

    @ViewBuilder
    private var appIcon: some View {
        if let url = NSWorkspace.shared.urlForApplication(withBundleIdentifier: data.bundleIdentifier) {
            Image(nsImage: NSWorkspace.shared.icon(forFile: url.path))
                .resizable()
                .aspectRatio(contentMode: .fit)
        } else {
            Image(systemName: "app")
                .font(.title2)
                .foregroundStyle(.secondary)
        }
    }

    // MARK: - Metric Value

    @ViewBuilder
    private var metricValue: some View {
        switch sortOption {
        case .activeTime:
            HStack(spacing: 4) {
                Image(systemName: "clock")
                    .foregroundStyle(.blue)
                Text(data.formattedActiveTime)
                    .monospacedDigit()
            }
            .font(.caption)
            .foregroundStyle(.secondary)

        case .activations:
            HStack(spacing: 4) {
                Image(systemName: "arrow.triangle.swap")
                    .foregroundStyle(.purple)
                Text("\(data.totalActivations)")
                    .monospacedDigit()
            }
            .font(.caption)
            .foregroundStyle(.secondary)

        case .memory:
            HStack(spacing: 4) {
                Image(systemName: "memorychip")
                    .foregroundStyle(.orange)
                Text(data.formattedPeakMemory)
                    .monospacedDigit()
            }
            .font(.caption)
            .foregroundStyle(.secondary)
        }
    }
}

// MARK: - Preview

#Preview {
    TopAppsView(records: AppUsageRecord.sampleRecords())
        .frame(width: 500, height: 400)
        .padding()
}
