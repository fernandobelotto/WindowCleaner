import Charts
import os
import SwiftData
import SwiftUI

// MARK: - Insights View

/// Main container view for usage insights and analytics.
struct InsightsView: View {
    // MARK: - Environment

    @Environment(\.modelContext) private var modelContext

    // MARK: - State

    @State private var selectedPeriod: InsightsPeriod = .week
    @State private var records: [AppUsageRecord] = []

    // MARK: - Body

    var body: some View {
        ScrollView {
            VStack(spacing: Metrics.spacingL) {
                periodPicker
                summaryCards
                usageChartSection
                topAppsSection
                memoryTrendsSection
            }
            .padding()
        }
        .background(Color(nsColor: .windowBackgroundColor))
        .task {
            await loadRecords()
        }
        .onChange(of: selectedPeriod) { _, _ in
            Task {
                await loadRecords()
            }
        }
    }

    // MARK: - Period Picker

    private var periodPicker: some View {
        Picker("Period", selection: $selectedPeriod) {
            ForEach(InsightsPeriod.allCases) { period in
                Text(period.label).tag(period)
            }
        }
        .pickerStyle(.segmented)
        .frame(maxWidth: 300)
    }

    // MARK: - Summary Cards

    private var summaryCards: some View {
        HStack(spacing: Metrics.spacingM) {
            SummaryCard(
                title: "Total Apps Used",
                value: "\(uniqueAppsCount)",
                icon: "app.badge",
                color: .blue
            )

            SummaryCard(
                title: "Total Active Time",
                value: formattedTotalActiveTime,
                icon: "clock",
                color: .green
            )

            SummaryCard(
                title: "Peak Memory",
                value: formattedPeakMemory,
                icon: "memorychip",
                color: .orange
            )

            SummaryCard(
                title: "App Switches",
                value: "\(totalActivations)",
                icon: "arrow.triangle.swap",
                color: .purple
            )
        }
    }

    // MARK: - Usage Chart Section

    private var usageChartSection: some View {
        VStack(alignment: .leading, spacing: Metrics.spacingS) {
            sectionHeader(title: "Daily Usage", icon: "chart.bar.fill")

            UsageChartView(records: records, period: selectedPeriod)
                .frame(height: 220)
                .padding()
                .background(Color(nsColor: .controlBackgroundColor))
                .clipShape(RoundedRectangle(cornerRadius: Metrics.cornerRadiusM))
        }
    }

    // MARK: - Top Apps Section

    private var topAppsSection: some View {
        VStack(alignment: .leading, spacing: Metrics.spacingS) {
            sectionHeader(title: "Most Used Apps", icon: "star.fill")

            TopAppsView(records: records)
                .padding()
                .background(Color(nsColor: .controlBackgroundColor))
                .clipShape(RoundedRectangle(cornerRadius: Metrics.cornerRadiusM))
        }
    }

    // MARK: - Memory Trends Section

    private var memoryTrendsSection: some View {
        VStack(alignment: .leading, spacing: Metrics.spacingS) {
            sectionHeader(title: "Memory Trends", icon: "chart.line.uptrend.xyaxis")

            MemoryTrendsView(records: records, period: selectedPeriod)
                .frame(height: 180)
                .padding()
                .background(Color(nsColor: .controlBackgroundColor))
                .clipShape(RoundedRectangle(cornerRadius: Metrics.cornerRadiusM))
        }
    }

    // MARK: - Section Header

    private func sectionHeader(title: String, icon: String) -> some View {
        Label(title, systemImage: icon)
            .font(.headline)
            .foregroundStyle(.primary)
    }

    // MARK: - Computed Properties

    private var uniqueAppsCount: Int {
        Set(records.map(\.bundleIdentifier)).count
    }

    private var totalActiveTime: TimeInterval {
        records.reduce(0) { $0 + $1.totalActiveTime }
    }

    private var formattedTotalActiveTime: String {
        let formatter = DateComponentsFormatter()
        formatter.allowedUnits = [.hour, .minute]
        formatter.unitsStyle = .abbreviated
        formatter.maximumUnitCount = 2
        return formatter.string(from: totalActiveTime) ?? "0m"
    }

    private var formattedPeakMemory: String {
        let peak = records.map(\.peakMemoryUsage).max() ?? 0
        return ByteCountFormatter.string(fromByteCount: Int64(peak), countStyle: .memory)
    }

    private var totalActivations: Int {
        records.reduce(0) { $0 + $1.activationCount }
    }

    // MARK: - Data Loading

    private func loadRecords() async {
        let descriptor = AppUsageRecord.lastDays(selectedPeriod.days)
        do {
            records = try modelContext.fetch(descriptor)
        } catch {
            Log.tracking.error("Failed to fetch usage records: \(error)")
            records = []
        }
    }
}

// MARK: - Insights Period

enum InsightsPeriod: String, CaseIterable, Identifiable {
    case day = "Today"
    case week = "Week"
    case month = "Month"

    var id: String { rawValue }

    var label: String { rawValue }

    var days: Int {
        switch self {
        case .day: 1
        case .week: 7
        case .month: 30
        }
    }
}

// MARK: - Summary Card

struct SummaryCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color

    var body: some View {
        VStack(alignment: .leading, spacing: Metrics.spacingXS) {
            HStack {
                Image(systemName: icon)
                    .font(.caption)
                    .foregroundStyle(color)
                Text(title)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Text(value)
                .font(.title2)
                .fontWeight(.semibold)
                .foregroundStyle(.primary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(Color(nsColor: .controlBackgroundColor))
        .clipShape(RoundedRectangle(cornerRadius: Metrics.cornerRadiusM))
    }
}

// MARK: - Preview

#Preview {
    InsightsView()
        .frame(width: 700, height: 800)
        .modelContainer(for: AppUsageRecord.self, inMemory: true)
}
