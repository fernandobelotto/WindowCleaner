# WindowCleaner - Implementation Plan

A macOS app that tracks application usage, monitors resource consumption, and helps users identify and close stale/resource-heavy apps using a smart scoring system.

## Features Summary

- **Full metrics tracking**: Memory, CPU, last active time, window count, app icon
- **Smart staleness scoring**: Combines inactivity time + memory usage + CPU into a "waste" score
- **Graceful quit only**: Safe app termination (like ⌘Q)
- **Persistent history**: Track daily/weekly usage patterns with insights over time
- **Dual interface**: Both window-based UI and menu bar access

---

## Phase 1: Core Infrastructure & Data Models

**Goal**: Build the foundation for app tracking and resource monitoring.

### 1.1 Data Models (SwiftData)

```
Models/
├── TrackedApp.swift        # Running app snapshot with metrics
├── AppUsageRecord.swift    # Historical usage record (persisted)
└── AppMetrics.swift        # Point-in-time metrics snapshot
```

**TrackedApp** (runtime, not persisted):
- `bundleIdentifier: String`
- `name: String`
- `icon: NSImage`
- `pid: pid_t`
- `memoryUsage: UInt64` (bytes)
- `cpuUsage: Double` (percentage)
- `windowCount: Int`
- `lastActiveDate: Date`
- `launchDate: Date`
- `stalenessScore: Double` (computed)

**AppUsageRecord** (persisted via SwiftData):
- `bundleIdentifier: String`
- `appName: String`
- `date: Date`
- `totalActiveTime: TimeInterval`
- `totalMemoryUsed: UInt64` (peak)
- `activationCount: Int`

### 1.2 Core Services

```
Services/
├── AppTrackingService.swift    # NSWorkspace observer for app events
├── ProcessMonitor.swift        # Memory/CPU monitoring via proc APIs
├── StalenessCalculator.swift   # Smart scoring algorithm
└── PermissionsManager.swift    # Accessibility permissions
```

**AppTrackingService**:
- Subscribe to `NSWorkspace.didActivateApplicationNotification`
- Subscribe to `NSWorkspace.didLaunchApplicationNotification`
- Subscribe to `NSWorkspace.didTerminateApplicationNotification`
- Maintain list of running apps
- Track `lastActiveDate` per app

**ProcessMonitor**:
- Poll every N seconds (configurable, default 5s)
- Use `proc_pidinfo` or `host_statistics` for memory/CPU
- Aggregate window count per app

### 1.3 Schema Migration

- Update `DataService.swift` with new schemas
- Create migration plan from V1 → V2

---

## Phase 2: Menu Bar Integration

**Goal**: Add a menu bar presence with quick access to running apps.

### 2.1 Menu Bar Setup

```
Services/
└── MenuBarManager.swift    # NSStatusItem management

Views/
└── MenuBar/
    ├── MenuBarPopover.swift      # Main popover content
    ├── MenuBarAppRow.swift       # Compact app row for menu
    └── MenuBarQuickActions.swift # Quick cleanup buttons
```

**MenuBarManager**:
- Create `NSStatusItem` with custom icon
- Toggle popover on click
- Show badge/indicator when high-memory apps detected

**MenuBarPopover** content:
- Top 5-10 stalest apps (sorted by score)
- Quick "Clean Up" button (close all stale)
- "Open Main Window" link
- Total memory reclaimable indicator

### 2.2 App Entry Point Updates

- Add `MenuBarExtra` scene to app
- Configure to run as both dock app and menu bar
- Handle "Hide Dock Icon" preference option

---

## Phase 3: Main Window UI

**Goal**: Rich window-based interface for detailed app management.

### 3.1 View Structure

```
Views/
├── Content/
│   ├── AppListView.swift         # Sidebar with running apps
│   ├── AppDetailView.swift       # Selected app details
│   └── DashboardView.swift       # Overview/stats dashboard
├── Components/
│   ├── AppRowView.swift          # Full app row with metrics
│   ├── MetricBadge.swift         # Memory/CPU indicator
│   ├── StalenessIndicator.swift  # Visual score indicator
│   ├── MemoryGauge.swift         # Memory usage gauge
│   └── CPUSparkline.swift        # Mini CPU history chart
```

### 3.2 Sidebar (AppListView)

- Segmented control: "All Apps" | "Stale" | "Heavy"
- Search/filter by app name
- Sort options: Staleness, Memory, CPU, Last Active
- List of `AppRowView` items
- Footer: Total apps, total memory used

### 3.3 Detail View (AppDetailView)

- Large app icon + name
- Real-time metrics cards (Memory, CPU, Windows, Uptime)
- Activity timeline (when was it active today)
- "Quit App" button (prominent)
- Historical usage chart (if history available)

### 3.4 Dashboard (Optional Tab/View)

- System overview: Total memory, available memory
- Top memory consumers (bar chart)
- Weekly usage trends
- "Suggested Cleanup" card with one-click action

---

## Phase 4: Smart Scoring & Recommendations

**Goal**: Implement the staleness algorithm and cleanup suggestions.

### 4.1 Staleness Calculator

```swift
// Scoring formula (weights configurable in settings)
stalenessScore = (inactivityWeight * inactivityScore)
               + (memoryWeight * memoryScore)
               + (cpuWeight * cpuScore)

// Where:
// - inactivityScore: minutes since last active, normalized
// - memoryScore: memory MB / total system memory
// - cpuScore: inverse (low CPU = higher staleness)
```

**Default weights**:
- Inactivity: 50%
- Memory: 40%
- CPU: 10%

### 4.2 Recommendations Engine

- Threshold for "stale" (configurable, default score > 0.6)
- Exclude system apps and user-protected apps
- Calculate "reclaimable memory" estimate
- Batch close functionality with confirmation

### 4.3 Protected Apps

- Maintain list of apps user never wants to close
- Auto-exclude: Finder, SystemUIServer, WindowCleaner itself
- User can add apps to protected list via context menu

---

## Phase 5: History & Insights

**Goal**: Persist usage data and provide analytics.

### 5.1 Data Persistence

- Save `AppUsageRecord` daily per app
- Aggregate: total active time, peak memory, activation count
- Cleanup old records (configurable retention, default 30 days)

### 5.2 Insights Views

```
Views/
└── Insights/
    ├── InsightsView.swift        # Main insights container
    ├── UsageChartView.swift      # Daily/weekly usage chart
    ├── TopAppsView.swift         # Most used apps ranking
    └── MemoryTrendsView.swift    # Memory usage over time
```

**Charts to include**:
- Daily app usage (bar chart)
- Memory consumption trends (line chart)
- Most frequently used apps (leaderboard)
- "Apps you rarely use but always open" insight

### 5.3 Export/Reports (Optional)

- Export usage data as CSV/JSON
- Weekly summary notification

---

## Phase 6: Permissions & Polish

**Goal**: Handle macOS permissions and refine UX.

### 6.1 Permissions Manager

- Check Accessibility API access (required for window count)
- Prompt user to grant access in System Settings
- Graceful degradation if not granted (skip window count)

### 6.2 Settings Updates

```
Views/Settings/
├── GeneralSettingsTab.swift      # Update with new options
├── TrackingSettingsTab.swift     # NEW: Polling interval, retention
├── ScoringSettingsTab.swift      # NEW: Weight adjustments
└── ProtectedAppsTab.swift        # NEW: Manage protected apps
```

**New Settings**:
- Polling interval (1s, 5s, 10s, 30s)
- Staleness threshold
- History retention period
- Show in Dock (yes/no)
- Launch at login
- Protected apps list

### 6.3 Onboarding Updates

- Update WelcomeView with new app purpose
- Permissions request step
- Quick tour of features

### 6.4 Final Polish

- App icon design (broom/window theme)
- Keyboard shortcuts (⌘K to quick-clean, etc.)
- Accessibility labels
- Localization strings

---

## Implementation Order

| Phase | Effort | Dependencies |
|-------|--------|--------------|
| **Phase 1**: Core Infrastructure | Foundation | None |
| **Phase 2**: Menu Bar | Medium | Phase 1 |
| **Phase 3**: Main Window UI | Large | Phase 1 |
| **Phase 4**: Smart Scoring | Medium | Phase 1 |
| **Phase 5**: History & Insights | Medium | Phase 1, 3 |
| **Phase 6**: Polish | Medium | All above |

**Recommended parallel tracks**:
- Phase 2 + Phase 3 can progress in parallel after Phase 1
- Phase 4 can start once Phase 1 is done
- Phase 5 needs Phase 3 UI but data layer can start with Phase 1

---

## Technical Considerations

### Permissions Required

1. **Accessibility Access** - For window enumeration (CGWindowListCopyWindowInfo)
2. **Automation** (optional) - For more reliable app termination

### macOS APIs

| Need | API |
|------|-----|
| Running apps | `NSWorkspace.shared.runningApplications` |
| App activation | `NSWorkspace` notifications |
| Process memory | `proc_pidinfo()` / `mach_task_info` |
| CPU usage | `host_processor_info()` |
| Window list | `CGWindowListCopyWindowInfo()` |
| Terminate app | `NSRunningApplication.terminate()` |
| Menu bar | `NSStatusItem` / `MenuBarExtra` |

### Performance

- Polling every 5s is reasonable balance
- Use background queue for process monitoring
- Debounce UI updates
- Lazy load app icons

---

## File Structure (Final)

```
WindowCleaner/
├── WindowCleanerApp.swift
├── ContentView.swift
├── Models/
│   ├── TrackedApp.swift
│   ├── AppUsageRecord.swift
│   ├── AppMetrics.swift
│   └── StoreProduct.swift
├── Views/
│   ├── Content/
│   │   ├── AppListView.swift
│   │   ├── AppDetailView.swift
│   │   └── DashboardView.swift
│   ├── Components/
│   │   ├── AppRowView.swift
│   │   ├── MetricBadge.swift
│   │   ├── StalenessIndicator.swift
│   │   └── ...
│   ├── MenuBar/
│   │   ├── MenuBarPopover.swift
│   │   └── MenuBarAppRow.swift
│   ├── Insights/
│   │   ├── InsightsView.swift
│   │   └── UsageChartView.swift
│   ├── Settings/
│   │   └── ...
│   └── Welcome/
│       └── ...
├── ViewModels/
│   ├── ContentViewModel.swift
│   └── AppTrackingViewModel.swift
├── Services/
│   ├── AppTrackingService.swift
│   ├── ProcessMonitor.swift
│   ├── StalenessCalculator.swift
│   ├── PermissionsManager.swift
│   ├── MenuBarManager.swift
│   └── ...
├── Utilities/
│   └── ...
├── Resources/
│   └── ...
└── docs/
    └── IMPLEMENTATION_PLAN.md
```
