import AppKit
import Darwin
import Foundation
import os

// MARK: - Process Monitor

/// Service responsible for monitoring process metrics (memory, CPU, window count).
/// Polls at a configurable interval and updates TrackedApp instances via AppTrackingService.
@MainActor
@Observable
final class ProcessMonitor {
    // MARK: - Singleton

    static let shared = ProcessMonitor()

    // MARK: - Configuration

    /// Polling interval in seconds
    var pollingInterval: TimeInterval = 5.0 {
        didSet {
            if isMonitoring {
                stopMonitoring()
                startMonitoring()
            }
        }
    }

    // MARK: - State

    /// Whether monitoring is active
    private(set) var isMonitoring: Bool = false

    /// System-wide memory info
    private(set) var systemMemory: SystemMemoryInfo = .init()

    /// Last update time
    private(set) var lastUpdateTime: Date?

    // MARK: - Private Properties

    private var monitoringTask: Task<Void, Never>?
    private weak var trackingService: AppTrackingService?

    // MARK: - Initialization

    private init() {
        Log.tracking.info("ProcessMonitor initialized")
    }

    // MARK: - Public Methods

    /// Starts monitoring process metrics
    /// - Parameter trackingService: The tracking service to update with metrics
    func startMonitoring(trackingService: AppTrackingService? = nil) {
        let resolvedService = trackingService ?? AppTrackingService.shared
        guard !isMonitoring else {
            Log.tracking.warning("ProcessMonitor already running")
            return
        }

        self.trackingService = resolvedService
        isMonitoring = true

        // Initial update
        updateAllMetrics()

        // Start polling loop
        monitoringTask = Task { [weak self] in
            while !Task.isCancelled {
                try? await Task.sleep(for: .seconds(self?.pollingInterval ?? 5.0))

                guard !Task.isCancelled else { break }

                await MainActor.run {
                    self?.updateAllMetrics()
                }
            }
        }

        Log.tracking.info("Started monitoring with \(self.pollingInterval)s interval")
    }

    /// Stops monitoring process metrics
    func stopMonitoring() {
        monitoringTask?.cancel()
        monitoringTask = nil
        isMonitoring = false
        Log.tracking.info("Stopped monitoring")
    }

    /// Forces an immediate update of all metrics
    func updateAllMetrics() {
        guard let service = trackingService else { return }

        // Update system memory info
        updateSystemMemory()

        // Update each app's metrics
        for app in service.runningApps {
            let memory = getMemoryUsage(for: app.pid)
            let cpu = getCPUUsage(for: app.pid)
            let windowCount = getWindowCount(for: app)

            service.updateMetrics(
                for: app.id,
                memory: memory,
                cpu: cpu,
                windowCount: windowCount
            )
        }

        lastUpdateTime = Date()
    }

    // MARK: - Memory Metrics

    /// Gets the memory usage for a process
    /// - Parameter pid: Process ID
    /// - Returns: Memory usage in bytes
    private func getMemoryUsage(for pid: pid_t) -> UInt64 {
        var info = mach_task_basic_info()
        var count = mach_msg_type_number_t(MemoryLayout<mach_task_basic_info>.size) / 4

        var taskPort: mach_port_t = 0
        let result = task_for_pid(mach_task_self_, pid, &taskPort)

        guard result == KERN_SUCCESS else {
            // Fallback: Use proc_pidinfo
            return getMemoryUsageViaProcInfo(for: pid)
        }

        defer {
            if taskPort != 0 {
                mach_port_deallocate(mach_task_self_, taskPort)
            }
        }

        let status = withUnsafeMutablePointer(to: &info) { infoPtr in
            infoPtr.withMemoryRebound(to: integer_t.self, capacity: Int(count)) { intPtr in
                task_info(taskPort, task_flavor_t(MACH_TASK_BASIC_INFO), intPtr, &count)
            }
        }

        if status == KERN_SUCCESS {
            return UInt64(info.resident_size)
        }

        return getMemoryUsageViaProcInfo(for: pid)
    }

    /// Gets memory usage using proc_pidinfo (fallback method)
    private func getMemoryUsageViaProcInfo(for pid: pid_t) -> UInt64 {
        var taskInfo = proc_taskinfo()
        let size = MemoryLayout<proc_taskinfo>.size

        let result = proc_pidinfo(
            pid,
            PROC_PIDTASKINFO,
            0,
            &taskInfo,
            Int32(size)
        )

        if result == size {
            return taskInfo.pti_resident_size
        }

        return 0
    }

    // MARK: - CPU Metrics

    /// Gets the CPU usage for a process
    /// - Parameter pid: Process ID
    /// - Returns: CPU usage as percentage (0-100)
    private func getCPUUsage(for pid: pid_t) -> Double {
        var taskInfo = proc_taskinfo()
        let size = MemoryLayout<proc_taskinfo>.size

        let result = proc_pidinfo(
            pid,
            PROC_PIDTASKINFO,
            0,
            &taskInfo,
            Int32(size)
        )

        guard result == size else { return 0 }

        // Calculate CPU percentage from user + system time
        // This is a simplified calculation; for accurate results,
        // we'd need to track delta over time
        let totalTime = Double(taskInfo.pti_total_user + taskInfo.pti_total_system)
        let uptime = ProcessInfo.processInfo.systemUptime

        // Normalize to percentage (rough approximation)
        let cpuPercent = (totalTime / 1_000_000_000) / uptime * 100

        return min(cpuPercent, 100.0)
    }

    // MARK: - Window Count

    /// Gets the number of windows for an app
    /// - Parameter app: The tracked app
    /// - Returns: Number of windows
    private func getWindowCount(for app: TrackedApp) -> Int {
        // Use CGWindowListCopyWindowInfo to get windows
        // This requires no special permissions for basic window enumeration
        let options: CGWindowListOption = [.optionOnScreenOnly, .excludeDesktopElements]
        guard let windowList = CGWindowListCopyWindowInfo(options, kCGNullWindowID) as? [[String: Any]] else {
            return 0
        }

        let count = windowList.filter { windowInfo in
            guard let ownerPID = windowInfo[kCGWindowOwnerPID as String] as? pid_t else {
                return false
            }
            return ownerPID == app.pid
        }.count

        return count
    }

    // MARK: - System Memory

    /// Updates system-wide memory information
    private func updateSystemMemory() {
        var stats = vm_statistics64()
        var count = mach_msg_type_number_t(MemoryLayout<vm_statistics64>.size / MemoryLayout<integer_t>.size)

        let result = withUnsafeMutablePointer(to: &stats) { statsPtr in
            statsPtr.withMemoryRebound(to: integer_t.self, capacity: Int(count)) { intPtr in
                host_statistics64(mach_host_self(), HOST_VM_INFO64, intPtr, &count)
            }
        }

        guard result == KERN_SUCCESS else { return }

        let pageSize = UInt64(vm_kernel_page_size)

        systemMemory = SystemMemoryInfo(
            total: ProcessInfo.processInfo.physicalMemory,
            free: UInt64(stats.free_count) * pageSize,
            active: UInt64(stats.active_count) * pageSize,
            inactive: UInt64(stats.inactive_count) * pageSize,
            wired: UInt64(stats.wire_count) * pageSize,
            compressed: UInt64(stats.compressor_page_count) * pageSize
        )
    }
}

// MARK: - System Memory Info

/// System-wide memory statistics
struct SystemMemoryInfo {
    var total: UInt64 = 0
    var free: UInt64 = 0
    var active: UInt64 = 0
    var inactive: UInt64 = 0
    var wired: UInt64 = 0
    var compressed: UInt64 = 0

    /// Memory currently in use
    var used: UInt64 {
        active + wired + compressed
    }

    /// Memory available (free + inactive)
    var available: UInt64 {
        free + inactive
    }

    /// Usage percentage (0-100)
    var usagePercent: Double {
        guard total > 0 else { return 0 }
        return Double(used) / Double(total) * 100
    }

    /// Formatted total memory
    var formattedTotal: String {
        ByteCountFormatter.string(fromByteCount: Int64(total), countStyle: .memory)
    }

    /// Formatted used memory
    var formattedUsed: String {
        ByteCountFormatter.string(fromByteCount: Int64(used), countStyle: .memory)
    }

    /// Formatted available memory
    var formattedAvailable: String {
        ByteCountFormatter.string(fromByteCount: Int64(available), countStyle: .memory)
    }
}

// MARK: - Polling Interval Presets

extension ProcessMonitor {
    enum PollingPreset: Double, CaseIterable, Identifiable {
        case fast = 1.0
        case normal = 5.0
        case slow = 10.0
        case verySlow = 30.0

        var id: Double { rawValue }

        var label: String {
            switch self {
            case .fast: "1 second"
            case .normal: "5 seconds"
            case .slow: "10 seconds"
            case .verySlow: "30 seconds"
            }
        }

        var description: String {
            switch self {
            case .fast: "More responsive, higher CPU usage"
            case .normal: "Balanced (recommended)"
            case .slow: "Lower CPU usage"
            case .verySlow: "Minimal CPU usage"
            }
        }
    }
}
