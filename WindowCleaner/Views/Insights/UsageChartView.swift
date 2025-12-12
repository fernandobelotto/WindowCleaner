import Charts
import SwiftUI

// MARK: - Usage Chart View

/// Displays daily app usage as a bar chart.
struct UsageChartView: View {
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
                BarMark(
                    x: .value("Date", dataPoint.date, unit: .day),
                    y: .value("Hours", dataPoint.hours)
                )
                .foregroundStyle(
                    LinearGradient(
                        colors: [.blue.opacity(0.8), .blue.opacity(0.4)],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .cornerRadius(4)
            }
        }
        .chartXAxis {
            AxisMarks(values: .stride(by: .day)) { value in
                AxisGridLine()
                AxisValueLabel(format: .dateTime.weekday(.abbreviated))
            }
        }
        .chartYAxis {
            AxisMarks { value in
                AxisGridLine()
                AxisValueLabel {
                    if let hours = value.as(Double.self) {
                        Text(String(format: "%.1fh", hours))
                    }
                }
            }
        }
        .chartYAxisLabel("Active Time (hours)")
    }

    // MARK: - Empty State

    private var emptyState: some View {
        VStack(spacing: Metrics.spacingM) {
            Image(systemName: "chart.bar")
                .font(.system(size: 32))
                .foregroundStyle(.tertiary)

            Text("No Usage Data")
                .font(.subheadline)
                .foregroundStyle(.secondary)

            Text("Start using apps to see your usage patterns here.")
                .font(.caption)
                .foregroundStyle(.tertiary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    // MARK: - Chart Data

    private var chartData: [DailyUsageData] {
        // Group records by date
        let grouped = Dictionary(grouping: records) { record in
            Calendar.current.startOfDay(for: record.date)
        }

        // Create data points for each day in the period
        var data: [DailyUsageData] = []
        let calendar = Calendar.current

        for dayOffset in 0 ..< period.days {
            if let date = calendar.date(byAdding: .day, value: -dayOffset, to: Date()) {
                let startOfDay = calendar.startOfDay(for: date)
                let recordsForDay = grouped[startOfDay] ?? []
                let totalSeconds = recordsForDay.reduce(0) { $0 + $1.totalActiveTime }
                let hours = totalSeconds / 3600

                data.append(DailyUsageData(date: startOfDay, hours: hours))
            }
        }

        return data.sorted { $0.date < $1.date }
    }
}

// MARK: - Daily Usage Data

struct DailyUsageData: Identifiable {
    let id = UUID()
    let date: Date
    let hours: Double
}

// MARK: - Per-App Usage Chart

/// Shows usage breakdown by app for a selected period.
struct AppUsageBreakdownChart: View {
    let records: [AppUsageRecord]

    var body: some View {
        if chartData.isEmpty {
            Text("No data available")
                .foregroundStyle(.secondary)
        } else {
            Chart {
                ForEach(chartData.prefix(10)) { dataPoint in
                    BarMark(
                        x: .value("Time", dataPoint.hours),
                        y: .value("App", dataPoint.appName)
                    )
                    .foregroundStyle(by: .value("App", dataPoint.appName))
                    .cornerRadius(4)
                }
            }
            .chartLegend(.hidden)
            .chartXAxisLabel("Hours")
        }
    }

    private var chartData: [AppUsageData] {
        // Group by bundle identifier and sum active time
        let grouped = Dictionary(grouping: records) { $0.bundleIdentifier }

        return grouped.map { bundleId, appRecords in
            let totalSeconds = appRecords.reduce(0) { $0 + $1.totalActiveTime }
            let appName = appRecords.first?.appName ?? bundleId
            return AppUsageData(
                bundleIdentifier: bundleId,
                appName: appName,
                hours: totalSeconds / 3600
            )
        }
        .sorted { $0.hours > $1.hours }
    }
}

// MARK: - App Usage Data

struct AppUsageData: Identifiable {
    var id: String { bundleIdentifier }
    let bundleIdentifier: String
    let appName: String
    let hours: Double
}

// MARK: - Preview

#Preview("Usage Chart") {
    UsageChartView(
        records: AppUsageRecord.sampleRecords(),
        period: .week
    )
    .frame(width: 500, height: 250)
    .padding()
}

#Preview("App Breakdown") {
    AppUsageBreakdownChart(records: AppUsageRecord.sampleRecords())
        .frame(width: 500, height: 300)
        .padding()
}
