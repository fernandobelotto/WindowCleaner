import os
import SwiftData
import SwiftUI

// MARK: - View Mode

enum ContentViewMode: String, CaseIterable, Identifiable {
    case apps = "Apps"
    case insights = "Insights"

    var id: String { rawValue }

    var icon: String {
        switch self {
        case .apps: "macwindow.on.rectangle"
        case .insights: "chart.bar.xaxis"
        }
    }
}

// MARK: - ContentView

/// Main content view for WindowCleaner showing running applications.
struct ContentView: View {
    // MARK: - Environment

    @Environment(\.modelContext)
    private var modelContext

    // MARK: - State

    @State private var viewModel = AppTrackingViewModel()
    @State private var columnVisibility: NavigationSplitViewVisibility = .all
    @State private var viewMode: ContentViewMode = .apps

    // MARK: - Body

    var body: some View {
        Group {
            switch viewMode {
            case .apps:
                appsView
            case .insights:
                InsightsView()
            }
        }
        .navigationTitle(viewMode == .apps ? "Window Cleaner" : "Usage Insights")
        .toolbar {
            toolbarContent
        }
        .task {
            startTracking()
        }
        .onDisappear {
            viewModel.stopTracking()
        }
        .alert("Error", isPresented: .init(
            get: { viewModel.errorMessage != nil },
            set: { if !$0 { viewModel.clearError() } }
        )) {
            Button("OK") {
                viewModel.clearError()
            }
        } message: {
            if let error = viewModel.errorMessage {
                Text(error)
            }
        }
        .sheet(isPresented: $viewModel.showCleanupSelectionSheet) {
            CleanupSelectionView(viewModel: viewModel)
        }
        // Handle menu commands
        .onReceive(NotificationCenter.default.publisher(for: .refreshContent)) { _ in
            viewModel.refresh()
        }
        .onReceive(NotificationCenter.default.publisher(for: .cleanUpStaleApps)) { _ in
            if viewModel.staleAppCount > 0 {
                viewModel.prepareCleanup()
            }
        }
    }

    // MARK: - Apps View

    private var appsView: some View {
        NavigationSplitView(columnVisibility: $columnVisibility) {
            AppListView(viewModel: viewModel)
                .navigationSplitViewColumnWidth(
                    min: 280,
                    ideal: 320,
                    max: 400
                )
        } detail: {
            detailContent
        }
    }

    // MARK: - Detail Content

    @ViewBuilder
    private var detailContent: some View {
        if let app = viewModel.selectedApp {
            AppDetailView(
                app: app,
                onQuit: {
                    viewModel.quitApp(app)
                    viewModel.selectApp(nil)
                },
                onToggleProtection: {
                    viewModel.toggleProtection(for: app)
                }
            )
        } else {
            EmptyDetailView()
        }
    }

    // MARK: - Toolbar

    @ToolbarContentBuilder
    private var toolbarContent: some ToolbarContent {
        ToolbarItem(placement: .navigation) {
            viewModePicker
        }

        ToolbarItem(placement: .primaryAction) {
            systemMemoryIndicator
        }

        ToolbarItem(placement: .primaryAction) {
            Button {
                viewModel.refresh()
            } label: {
                Image(systemName: "arrow.clockwise")
            }
            .help("Refresh app list")
            .disabled(viewMode == .insights)
        }

        ToolbarItem(placement: .primaryAction) {
            if viewModel.staleAppCount > 0 && viewMode == .apps {
                Button {
                    viewModel.prepareCleanup()
                } label: {
                    Label("Clean Up", systemImage: "sparkles")
                }
                .help("Quit \(viewModel.staleAppCount) stale apps")
            }
        }
    }

    private var viewModePicker: some View {
        Picker("View", selection: $viewMode) {
            ForEach(ContentViewMode.allCases) { mode in
                Label(mode.rawValue, systemImage: mode.icon)
                    .tag(mode)
            }
        }
        .pickerStyle(.segmented)
        .frame(width: 180)
    }

    private var systemMemoryIndicator: some View {
        HStack(spacing: 4) {
            Circle()
                .fill(memoryStatusColor)
                .frame(width: 8, height: 8)

            Text("\(viewModel.systemMemory.formattedUsed) / \(viewModel.systemMemory.formattedTotal)")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .help("System memory usage")
    }

    private var memoryStatusColor: Color {
        let usage = viewModel.systemMemory.usagePercent
        if usage > 80 {
            return .red
        } else if usage > 60 {
            return .orange
        } else {
            return .green
        }
    }

    // MARK: - Tracking

    private func startTracking() {
        viewModel.startTracking(modelContext: modelContext)
    }
}

// MARK: - Previews

#Preview("Main Window") {
    ContentView()
        .modelContainer(.preview)
        .frame(width: 800, height: 600)
}

#Preview("Dark Mode") {
    ContentView()
        .modelContainer(.preview)
        .preferredColorScheme(.dark)
        .frame(width: 800, height: 600)
}
