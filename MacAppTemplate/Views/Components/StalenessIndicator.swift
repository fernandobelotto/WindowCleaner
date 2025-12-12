import SwiftUI

// MARK: - Staleness Indicator

/// Visual indicator showing an app's staleness level.
struct StalenessIndicator: View {
    // MARK: - Properties

    let level: StalenessLevel
    var compact: Bool = false
    var showLabel: Bool = true

    // MARK: - Body

    var body: some View {
        if compact {
            compactView
        } else {
            fullView
        }
    }

    // MARK: - Compact View

    private var compactView: some View {
        Circle()
            .fill(levelColor)
            .frame(width: 8, height: 8)
            .help(level.description)
    }

    // MARK: - Full View

    private var fullView: some View {
        HStack(spacing: 4) {
            Image(systemName: level.systemImage)
                .foregroundStyle(levelColor)
                .font(.caption)

            if showLabel {
                Text(level.rawValue)
                    .font(.caption)
                    .foregroundStyle(levelColor)
            }
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(levelColor.opacity(0.1))
        .clipShape(Capsule())
    }

    // MARK: - Helper

    private var levelColor: Color {
        switch level {
        case .active: .green
        case .recent: .blue
        case .idle: .yellow
        case .stale: .orange
        case .veryStale: .red
        }
    }
}

// MARK: - Staleness Bar

/// A horizontal bar showing staleness score as a filled gradient.
struct StalenessBar: View {
    let score: Double
    var height: CGFloat = 6

    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .leading) {
                // Background
                RoundedRectangle(cornerRadius: height / 2)
                    .fill(Color.primary.opacity(0.1))

                // Fill
                RoundedRectangle(cornerRadius: height / 2)
                    .fill(gradient)
                    .frame(width: geometry.size.width * CGFloat(score))
            }
        }
        .frame(height: height)
    }

    private var gradient: LinearGradient {
        LinearGradient(
            colors: [.green, .yellow, .orange, .red],
            startPoint: .leading,
            endPoint: .trailing
        )
    }
}

// MARK: - Memory Badge

/// Badge showing memory usage with appropriate coloring.
struct MemoryBadge: View {
    let bytes: UInt64
    var threshold: UInt64 = 500_000_000 // 500MB warning threshold

    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: "memorychip")
                .font(.caption2)
            Text(formattedMemory)
                .font(.caption)
                .fontWeight(.medium)
        }
        .foregroundStyle(memoryColor)
        .padding(.horizontal, 6)
        .padding(.vertical, 3)
        .background(memoryColor.opacity(0.1))
        .clipShape(Capsule())
    }

    private var formattedMemory: String {
        ByteCountFormatter.string(fromByteCount: Int64(bytes), countStyle: .memory)
    }

    private var memoryColor: Color {
        if bytes > threshold * 2 {
            return .red
        } else if bytes > threshold {
            return .orange
        } else {
            return .secondary
        }
    }
}

// MARK: - CPU Badge

/// Badge showing CPU usage with appropriate coloring.
struct CPUBadge: View {
    let percentage: Double
    var warningThreshold: Double = 20.0
    var criticalThreshold: Double = 50.0

    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: "cpu")
                .font(.caption2)
            Text(String(format: "%.1f%%", percentage))
                .font(.caption)
                .fontWeight(.medium)
        }
        .foregroundStyle(cpuColor)
        .padding(.horizontal, 6)
        .padding(.vertical, 3)
        .background(cpuColor.opacity(0.1))
        .clipShape(Capsule())
    }

    private var cpuColor: Color {
        if percentage > criticalThreshold {
            return .red
        } else if percentage > warningThreshold {
            return .orange
        } else {
            return .secondary
        }
    }
}

// MARK: - Time Badge

/// Badge showing time since last active.
struct TimeBadge: View {
    let date: Date
    var staleThreshold: TimeInterval = 1800 // 30 minutes

    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: "clock")
                .font(.caption2)
            Text(formattedTime)
                .font(.caption)
                .fontWeight(.medium)
        }
        .foregroundStyle(timeColor)
        .padding(.horizontal, 6)
        .padding(.vertical, 3)
        .background(timeColor.opacity(0.1))
        .clipShape(Capsule())
    }

    private var formattedTime: String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: date, relativeTo: Date())
    }

    private var timeColor: Color {
        let elapsed = Date().timeIntervalSince(date)
        if elapsed > staleThreshold * 2 {
            return .red
        } else if elapsed > staleThreshold {
            return .orange
        } else {
            return .secondary
        }
    }
}

// MARK: - Metric Card

/// A card displaying a single metric with icon and value.
struct MetricCard: View {
    let title: String
    let value: String
    let icon: String
    var color: Color = .primary

    var body: some View {
        VStack(spacing: Metrics.spacingXS) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundStyle(color)

            Text(value)
                .font(.title3)
                .fontWeight(.semibold)

            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(Metrics.spacingM)
        .background(Color.primary.opacity(0.03))
        .clipShape(RoundedRectangle(cornerRadius: Metrics.cornerRadiusM))
    }
}

// MARK: - Previews

#Preview("Staleness Indicators") {
    VStack(spacing: 20) {
        ForEach(StalenessLevel.allCases) { level in
            HStack {
                StalenessIndicator(level: level, compact: true)
                StalenessIndicator(level: level)
                Spacer()
            }
        }
    }
    .padding()
}

#Preview("Staleness Bar") {
    VStack(spacing: 20) {
        StalenessBar(score: 0.2)
        StalenessBar(score: 0.5)
        StalenessBar(score: 0.8)
        StalenessBar(score: 1.0)
    }
    .padding()
}

#Preview("Badges") {
    HStack(spacing: 10) {
        MemoryBadge(bytes: 250_000_000)
        MemoryBadge(bytes: 750_000_000)
        MemoryBadge(bytes: 1_500_000_000)
    }
    .padding()
}
