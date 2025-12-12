# Changelog

All notable changes to WindowCleaner will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

---

## [Unreleased]

### Added
- Project renaming script (`Scripts/rename-project.sh`) for easy template customization
- Contributing guidelines (`CONTRIBUTING.md`)
- This changelog file

### Changed
- Updated README with project renaming documentation

---

## [1.0.0] - 2024-11-29

### Added

#### Core Features
- SwiftUI application with `NavigationSplitView` pattern
- SwiftData persistence with `ModelContainer` configuration
- Swift 6 concurrency with `@MainActor` default isolation
- App Sandbox and Hardened Runtime security

#### Views & UI
- `ContentView` with sidebar/detail navigation
- `ItemRow` reusable component
- `SettingsView` with General and About tabs
- Empty state views using `ContentUnavailableView`
- Preview containers with sample data

#### Models
- `Item` SwiftData model with timestamp
- Sample data generation for previews

#### Utilities
- `AppError` enum with localized error handling
- `Log` namespace with categorized `os.Logger` instances
- `Config` for app version and environment detection
- `Metrics` for consistent spacing and sizing
- `UserDefaultsKey` for `@AppStorage` keys
- `Notification.Name` extensions for app events

#### Menu & Commands
- New Item command (`⌘N`)
- Delete command (`⌫`)
- Help menu with documentation links

#### Code Quality
- SwiftLint integration via Xcode Build Tool Plugin
- SwiftFormat configuration for consistent formatting
- Pre-commit git hooks for automated formatting
- Makefile with common development commands

#### Documentation
- Comprehensive README
- Cursor Rules for AI-assisted development:
  - Architecture guidelines
  - SwiftUI view patterns
  - SwiftData model conventions
  - Testing conventions
  - Code snippets

#### Testing
- Swift Testing framework setup (`WindowCleanerTests`)
- XCUITest setup (`WindowCleanerUITests`)
- Launch performance test

---

## Version History

| Version | Date | Highlights |
|:--------|:-----|:-----------|
| 1.0.0 | 2024-11-29 | Initial release with SwiftUI, SwiftData, Swift 6 |

---

## Upgrade Guide

### From 0.x to 1.0.0

This is the initial release. No migration needed.

### Future Upgrades

When upgrading between versions:

1. Review the changelog for breaking changes
2. Back up your customizations
3. Pull the latest template changes
4. Resolve any conflicts
5. Run `make test` to verify everything works

---

## Release Process

For maintainers:

1. Update version in Xcode project settings
2. Update this CHANGELOG with release notes
3. Commit: `git commit -m "chore: release vX.Y.Z"`
4. Tag: `git tag -a vX.Y.Z -m "Release vX.Y.Z"`
5. Push: `git push origin main --tags`

---

## Links

- [GitHub Repository](https://github.com.fernandobelotto.WindowCleaner)
- [Issues](https://github.com.fernandobelotto.WindowCleaner/issues)
- [Pull Requests](https://github.com.fernandobelotto.WindowCleaner/pulls)









