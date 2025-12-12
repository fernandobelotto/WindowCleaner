import os
import SwiftData
import SwiftUI

// MARK: - ContentView

/// Main content view for WindowCleaner showing running applications.
struct ContentView: View {
    // MARK: - Environment

    @Environment(\.modelContext)
    private var modelContext

    // MARK: - State

    @State private var viewModel = AppTrackingViewModel()
    @State private var columnVisibility: NavigationSplitViewVisibility = .all

    // MARK: - Body

    var body: some View {
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
        .navigationTitle("Window Cleaner")
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
        .alert("Clean Up Apps?", isPresented: $viewModel.showCleanupConfirmation) {
            Button("Cancel", role: .cancel) {
                viewModel.cancelCleanup()
            }
            Button("Quit Apps", role: .destructive) {
                viewModel.executeCleanup()
            }
        } message: {
            Text("This will quit \(viewModel.pendingCleanupApps.count) stale apps, freeing approximately \(viewModel.potentialSavings) of memory.")
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
        }

        ToolbarItem(placement: .primaryAction) {
            if viewModel.staleAppCount > 0 {
                Button {
                    viewModel.prepareCleanup()
                } label: {
                    Label("Clean Up", systemImage: "sparkles")
                }
                .help("Quit \(viewModel.staleAppCount) stale apps")
            }
        }
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
