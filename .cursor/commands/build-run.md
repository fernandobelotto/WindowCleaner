# Build & Run

Build and launch the macOS app in the simulator or directly on the Mac.

## Context
- Project: `MacAppTemplate.xcodeproj`
- Scheme: `MacAppTemplate`
- Target: macOS 15.6+
- Swift 6 with @MainActor default isolation

## Instructions

1. Use XcodeBuildMCP to build the project:
   - Use `build_run_macos` tool with:
     - `projectPath`: `MacAppTemplate.xcodeproj`
     - `scheme`: `MacAppTemplate`
     - `configuration`: `Debug` (default)

2. If there are build errors:
   - Parse the error output carefully
   - Focus on Swift 6 concurrency issues (actor isolation, sendability)
   - Check SwiftData model conformance
   - Look for missing imports

3. Report:
   - Build success/failure
   - Any warnings (especially concurrency warnings)
   - App launch status

## Common Issues
- Actor isolation errors → Add `nonisolated` or `@MainActor` explicitly
- SwiftData model errors → Ensure `@Model` classes have proper initializers
- Preview crashes → Check ModelContainer configuration in #Preview










