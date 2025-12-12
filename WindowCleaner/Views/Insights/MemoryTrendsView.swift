import Charts
import SwiftUI

// MARK: - Memory Trends View

/// Displays memory usage trends over time as a line chart.
struct MemoryTrendsView: View {
    let records: [AppUsageRecord]
    let period: InsightsPeriod

    var body: some View {
        if chartData.isEmpty {
            emptyState
        } else {
            chart
        }
    }

    // MARK: - Chart

    private var chart: some View {
        Chart {
            ForEach(chartData) { dataPoint in
                // Peak memory line
                LineMark(
                    x: .value("Date", dataPoint.date, unit: .day),
                    y: .value("Peak", dataPoint.peakGB),
                    series: .value("Type", "Peak")
                )
                .foregroundStyle(.orange)
                .lineStyle(StrokeStyle(lineWidth: 2))

                PointMark(
                    x: .value("Date", dataPoint.date, unit: .day),
                    y: .value("Peak", dataPoint.peakGB)
                )
                .foregroundStyle(.orange)
                .symbolSize(40)

                // Average memory area
                AreaMark(
                    x: .value("Date", dataPoint.date, unit: .day),
                    y: .value("Average", dataPoint.averageGB)
                )
                .foregroundStyle(
                    LinearGradient(
                        colors: [.blue.opacity(0.3), .blue.opacity(0.1)],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )

                LineMark(
                    x: .value("Date", dataPoint.date, unit: .day),
                    y: .value("Average", dataPoint.averageGB),
                    series: .value("Type", "Average")
                )
                .foregroundStyle(.blue)
                .lineStyle(StrokeStyle(lineWidth: 2, dash: [5, 3]))
            }
        }
        .chartXAxis {
            AxisMarks(values: .stride(by: .day)) { _ in
                AxisGridLine()
                AxisValueLabel(format: .dateTime.weekday(.abbreviated))
            }
        }
        .chartYAxis {
            AxisMarks { value in
                AxisGridLine()
                AxisValueLabel {
                    if let gb = value.as(Double.self) {
                        Text(String(format: "%.1f GB", gb))
                    }
                }
            }
        }
        .chartLegend(position: .top, alignment: .trailing) {
            HStack(spacing: Metrics.spacingM) {
                LegendItem(color: .orange, label: "Peak Memory")
                LegendItem(color: .blue, label: "Average Memory")
            }
        }
    }

    // MARK: - Empty State

    private var emptyState: some View {
        VStack(spacing: Metrics.spacingM) {
            Image(systemName: "chart.line.uptrend.xyaxis")
                .font(.system(size: 32))
                .foregroundStyle(.tertiary)

            Text("No Memory Data")
                .font(.subheadline)
                .foregroundStyle(.secondary)

            Text("Memory trends will appear as you use apps.")
                .font(.caption)
                .foregroundStyle(.tertiary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    // MARK: - Chart Data

    private var chartData: [MemoryTrendData] {
        // Group records by date
        let grouped = Dictionary(grouping: records) { record in
            Calendar.current.startOfDay(for: record.date)
        }

        // Create data points for each day in the period
        var data: [MemoryTrendData] = []
        let calendar = Calendar.current

        for dayOffset in 0 ..< period.days {
            if let date = calendar.date(byAdding: .day, value: -dayOffset, to: Date()) {
                let startOfDay = calendar.startOfDay(for: date)
                let recordsForDay = grouped[startOfDay] ?? []

                if !recordsForDay.isEmpty {
                    let peakMemory = recordsForDay.map(\.peakMemoryUsage).max() ?? 0
                    let totalAverage = recordsForDay.reduce(0) { $0 + $1.averageMemoryUsage }
                    let averageMemory = totalAverage / UInt64(recordsForDay.count)

                    data.append(MemoryTrendData(
                        date: startOfDay,
                        peakGB: Double(peakMemory) / 1_073_741_824,
                        averageGB: Double(averageMemory) / 1_073_741_824
                    ))
                }
            }
        }

        return data.sorted { $0.date < $1.date }
    }
}

// MARK: - Memory Trend Data

struct MemoryTrendData: Identifiable {
    let id = UUID()
    let date: Date
    let peakGB: Double
    let averageGB: Double
}

// MARK: - Legend Item

struct LegendItem: View {
    let color: Color
    let label: String

    var body: some View {
        HStack(spacing: 4) {
            Circle()
                .fill(color)
                .frame(width: 8, height: 8)
            Text(label)
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
    }
}

// MARK: - Memory By App Chart

/// Shows memory breakdown by app as a horizontal bar chart.
struct MemoryByAppChart: View {
    let records: [AppUsageRecord]

    var body: some View {
        if chartData.isEmpty {
            Text("No data available")
                .foregroundStyle(.secondary)
        } else {
            Chart {
                ForEach(chartData.prefix(8)) { dataPoint in
                    BarMark(
                        x: .value("Memory", dataPoint.memoryGB),
                        y: .value("App", dataPoint.appName)
                    )
                    .foregroundStyle(
                        LinearGradient(
                            colors: [.orange, .red],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .cornerRadius(4)
                }
            }
            .chartXAxisLabel("Peak Memory (GB)")
        }
    }

    private var chartData: [AppMemoryData] {
        // Group by bundle identifier and get peak memory
        let grouped = Dictionary(grouping: records) { $0.bundleIdentifier }

        return grouped.map { bundleId, appRecords in
            let peakMemory = appRecords.map(\.peakMemoryUsage).max() ?? 0
            let appName = appRecords.first?.appName ?? bundleId
            return AppMemoryData(
                bundleIdentifier: bundleId,
                appName: appName,
                memoryGB: Double(peakMemory) / 1_073_741_824
            )
        }
        .sorted { $0.memoryGB > $1.memoryGB }
    }
}

// MARK: - App Memory Data

struct AppMemoryData: Identifiable {
    var id: String { bundleIdentifier }
    let bundleIdentifier: String
    let appName: String
    let memoryGB: Double
}

// MARK: - Preview

#Preview("Memory Trends") {
    MemoryTrendsView(
        records: AppUsageRecord.sampleRecords(),
        period: .week
    )
    .frame(width: 500, height: 200)
    .padding()
}

#Preview("Memory By App") {
    MemoryByAppChart(records: AppUsageRecord.sampleRecords())
        .frame(width: 500, height: 300)
        .padding()
}
