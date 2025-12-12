import SwiftUI

// MARK: - Scoring Settings Tab

/// Settings for configuring the staleness scoring algorithm.
struct ScoringSettingsTab: View {
    // MARK: - App Storage

    @AppStorage(UserDefaultsKey.stalenessInactivityWeight)
    private var inactivityWeight: Double = 0.50

    @AppStorage(UserDefaultsKey.stalenessMemoryWeight)
    private var memoryWeight: Double = 0.40

    @AppStorage(UserDefaultsKey.stalenessCPUWeight)
    private var cpuWeight: Double = 0.10

    @AppStorage(UserDefaultsKey.stalenessThreshold)
    private var stalenessThreshold: Double = 0.60

    @AppStorage(UserDefaultsKey.maxInactivityMinutes)
    private var maxInactivityMinutes: Double = 60.0

    // MARK: - State

    @State private var showResetConfirmation = false

    // MARK: - Body

    var body: some View {
        Form {
            weightsSection
            thresholdSection
            previewSection
            resetSection
        }
        .formStyle(.grouped)
        .padding()
        .alert("Reset to Defaults?", isPresented: $showResetConfirmation) {
            Button("Cancel", role: .cancel) {}
            Button("Reset", role: .destructive) {
                resetToDefaults()
            }
        } message: {
            Text("This will reset all scoring settings to their default values.")
        }
    }

    // MARK: - Weights Section

    private var weightsSection: some View {
        Section {
            inactivityWeightRow
            memoryWeightRow
            cpuWeightRow
            totalRow
        } header: {
            Text("Scoring Weights")
        } footer: {
            Text("Adjust how each factor contributes to the staleness score. Weights should total 100%.")
                .font(.caption)
                .foregroundStyle(.tertiary)
        }
    }

    private var inactivityWeightRow: some View {
        VStack(alignment: .leading, spacing: Metrics.spacingS) {
            HStack {
                Label("Inactivity", systemImage: "clock")
                Spacer()
                Text("\(Int(inactivityWeight * 100))%")
                    .monospacedDigit()
                    .foregroundStyle(.secondary)
            }
            Slider(value: $inactivityWeight, in: 0...1, step: 0.05)
                .onChange(of: inactivityWeight) { _, _ in normalizeWeights(changed: .inactivity) }
            Text("How much inactive time contributes to staleness")
                .font(.caption)
                .foregroundStyle(.tertiary)
        }
    }

    private var memoryWeightRow: some View {
        VStack(alignment: .leading, spacing: Metrics.spacingS) {
            HStack {
                Label("Memory Usage", systemImage: "memorychip")
                Spacer()
                Text("\(Int(memoryWeight * 100))%")
                    .monospacedDigit()
                    .foregroundStyle(.secondary)
            }
            Slider(value: $memoryWeight, in: 0...1, step: 0.05)
                .onChange(of: memoryWeight) { _, _ in normalizeWeights(changed: .memory) }
            Text("How much memory usage contributes to staleness")
                .font(.caption)
                .foregroundStyle(.tertiary)
        }
    }

    private var cpuWeightRow: some View {
        VStack(alignment: .leading, spacing: Metrics.spacingS) {
            HStack {
                Label("CPU Usage (inverse)", systemImage: "cpu")
                Spacer()
                Text("\(Int(cpuWeight * 100))%")
                    .monospacedDigit()
                    .foregroundStyle(.secondary)
            }
            Slider(value: $cpuWeight, in: 0...1, step: 0.05)
                .onChange(of: cpuWeight) { _, _ in normalizeWeights(changed: .cpu) }
            Text("Low CPU usage increases staleness (app is idle)")
                .font(.caption)
                .foregroundStyle(.tertiary)
        }
    }

    private var totalRow: some View {
        HStack {
            Text("Total")
                .fontWeight(.medium)
            Spacer()
            Text(totalPercentText)
                .monospacedDigit()
                .foregroundColor(totalIsValid ? .secondary : .red)
        }
    }

    private var totalPercentText: String {
        let total = inactivityWeight + memoryWeight + cpuWeight
        return "\(Int(total * 100))%"
    }

    // MARK: - Threshold Section

    private var thresholdSection: some View {
        Section {
            thresholdRow
            maxInactivityRow
        } header: {
            Text("Staleness Threshold")
        } footer: {
            Text("Apps scoring above the threshold will be marked as 'stale' and suggested for cleanup.")
                .font(.caption)
                .foregroundStyle(.tertiary)
        }
    }

    private var thresholdRow: some View {
        VStack(alignment: .leading, spacing: Metrics.spacingS) {
            HStack {
                Text("Stale Threshold")
                Spacer()
                Text("\(Int(stalenessThreshold * 100))%")
                    .monospacedDigit()
                    .foregroundStyle(.secondary)
            }
            Slider(value: $stalenessThreshold, in: 0.3...0.9, step: 0.05)
            thresholdHints
        }
    }

    private var thresholdHints: some View {
        HStack(spacing: Metrics.spacingL) {
            Label("More apps flagged", systemImage: "exclamationmark.triangle")
                .font(.caption)
                .foregroundStyle(.orange)
            Spacer()
            Label("Fewer apps flagged", systemImage: "checkmark.circle")
                .font(.caption)
                .foregroundStyle(.green)
        }
    }

    private var maxInactivityRow: some View {
        VStack(alignment: .leading, spacing: Metrics.spacingS) {
            HStack {
                Text("Max Inactivity Time")
                Spacer()
                Text("\(Int(maxInactivityMinutes)) min")
                    .monospacedDigit()
                    .foregroundStyle(.secondary)
            }
            Slider(value: $maxInactivityMinutes, in: 15...180, step: 15)
            Text("Apps inactive longer than this get maximum inactivity score")
                .font(.caption)
                .foregroundStyle(.tertiary)
        }
    }

    // MARK: - Preview Section

    private var previewSection: some View {
        Section {
            previewContent
        } header: {
            Text("Preview")
        }
    }

    private var previewContent: some View {
        VStack(alignment: .leading, spacing: Metrics.spacingS) {
            Text("With current settings:")
                .font(.subheadline)
                .foregroundStyle(.secondary)

            previewExamples
        }
    }

    private var previewExamples: some View {
        HStack(spacing: Metrics.spacingM) {
            previewExample(
                title: "Idle 30min, 500MB",
                score: calculateExampleScore(inactiveMinutes: 30, memoryMB: 500, cpuPercent: 0)
            )
            previewExample(
                title: "Idle 5min, 1GB",
                score: calculateExampleScore(inactiveMinutes: 5, memoryMB: 1000, cpuPercent: 5)
            )
            previewExample(
                title: "Active, 200MB",
                score: calculateExampleScore(inactiveMinutes: 0, memoryMB: 200, cpuPercent: 20)
            )
        }
    }

    private func previewExample(title: String, score: Double) -> some View {
        VStack(spacing: 4) {
            Text(title)
                .font(.caption2)
                .foregroundStyle(.secondary)
                .lineLimit(1)

            ZStack {
                Circle()
                    .stroke(Color.secondary.opacity(0.2), lineWidth: 4)
                Circle()
                    .trim(from: 0, to: score)
                    .stroke(scoreColor(score), lineWidth: 4)
                    .rotationEffect(.degrees(-90))
                Text("\(Int(score * 100))")
                    .font(.caption)
                    .fontWeight(.medium)
            }
            .frame(width: 44, height: 44)

            Text(score >= stalenessThreshold ? "Stale" : "OK")
                .font(.caption2)
                .foregroundStyle(score >= stalenessThreshold ? .orange : .green)
        }
        .frame(maxWidth: .infinity)
    }

    private func scoreColor(_ score: Double) -> Color {
        if score >= stalenessThreshold {
            return .orange
        } else if score >= stalenessThreshold * 0.7 {
            return .yellow
        } else {
            return .green
        }
    }

    // MARK: - Reset Section

    private var resetSection: some View {
        Section {
            Button("Reset to Defaults") {
                showResetConfirmation = true
            }
        }
    }

    // MARK: - Helpers

    private var totalIsValid: Bool {
        let total = inactivityWeight + memoryWeight + cpuWeight
        return abs(total - 1.0) < 0.01
    }

    private enum WeightType {
        case inactivity, memory, cpu
    }

    private func normalizeWeights(changed: WeightType) {
        let total = inactivityWeight + memoryWeight + cpuWeight

        guard total > 0 else { return }

        // Only normalize if total is significantly off
        guard abs(total - 1.0) > 0.05 else { return }

        // Adjust the other weights proportionally
        let adjustment = (1.0 - total)

        switch changed {
        case .inactivity:
            let otherTotal = memoryWeight + cpuWeight
            if otherTotal > 0 {
                memoryWeight += adjustment * (memoryWeight / otherTotal)
                cpuWeight += adjustment * (cpuWeight / otherTotal)
            }
        case .memory:
            let otherTotal = inactivityWeight + cpuWeight
            if otherTotal > 0 {
                inactivityWeight += adjustment * (inactivityWeight / otherTotal)
                cpuWeight += adjustment * (cpuWeight / otherTotal)
            }
        case .cpu:
            let otherTotal = inactivityWeight + memoryWeight
            if otherTotal > 0 {
                inactivityWeight += adjustment * (inactivityWeight / otherTotal)
                memoryWeight += adjustment * (memoryWeight / otherTotal)
            }
        }

        // Clamp values
        inactivityWeight = max(0, min(1, inactivityWeight))
        memoryWeight = max(0, min(1, memoryWeight))
        cpuWeight = max(0, min(1, cpuWeight))
    }

    private func calculateExampleScore(inactiveMinutes: Double, memoryMB: Double, cpuPercent: Double) -> Double {
        let inactivityScore = min(inactiveMinutes / maxInactivityMinutes, 1.0)
        let memoryScore = min(memoryMB / 4000.0, 1.0) // 4GB max
        let cpuScore = 1.0 - min(cpuPercent / 100.0, 1.0) // Inverse

        return (inactivityWeight * inactivityScore)
            + (memoryWeight * memoryScore)
            + (cpuWeight * cpuScore)
    }

    private func resetToDefaults() {
        inactivityWeight = 0.50
        memoryWeight = 0.40
        cpuWeight = 0.10
        stalenessThreshold = 0.60
        maxInactivityMinutes = 60.0
    }
}

// MARK: - UserDefaults Keys Extension

extension UserDefaultsKey {
    static let maxInactivityMinutes = "maxInactivityMinutes"
}

// MARK: - Preview

#Preview {
    ScoringSettingsTab()
        .frame(width: 480, height: 600)
}
