# MacAppTemplate — Roadmap to Best-of-the-Best

This document tracks all planned upgrades to transform MacAppTemplate into a production-ready, reusable macOS app foundation.

**Legend:**
- ✅ Done
- 🔄 In Progress
- ⏳ Planned
- ❌ Blocked

---

## Current Status vs. The Goal

| Feature | Current State (What we have) | Best of the Best (What we need) |
|:--------|:-----------------------------|:--------------------------------|
| **Architecture** | Basic View-based logic (`ContentView` handles everything). | **Modular Architecture**: Clear separation of Features, Services, and UI Components. Logic moved out of Views. |
| **Data Layer** | Basic SwiftData `ModelContainer`. | **Robust Persistence**: A `DataService` that handles `SchemaMigrationPlan` (versioning), seeding, and error handling. |
| **Navigation** | Simple `NavigationSplitView`. | **State-Driven Navigation**: A `NavigationManager` or `Router` to handle deep linking, window management, and complex flows. |
| **Onboarding** | ✅ Carousel-style `WelcomeView` with first-launch detection. | **First-Run Experience**: A configurable `WelcomeView` that appears only on the first launch. |
| **Theming** | ✅ `AppTheme` with Colors, Fonts, Shadows, Animations. | **Design System**: A central `AppTheme` for Colors, Fonts, and Spacing tokens, making it easy to "skin" new apps. |
| **Testing** | Empty default test files. | **Test Suite**: Sample Unit Tests (Logic) and UI Tests (Flows) pre-configured. |
| **CI/CD** | `Makefile` for local use. | **CI/CD Pipeline**: GitHub Actions workflow (`.yml`) to run tests/linting automatically. |
| **Tooling** | SwiftLint/SwiftFormat (Great!). | **Scaffold Scripts**: Scripts to rename the project (bundle ID, app name) easily for new apps. |

---

## Phase 1: Architecture & Core Services (The Foundation)

| Status | Feature | Description | Notes |
|:------:|:--------|:------------|:------|
| ⏳ | **DataService** | Encapsulate SwiftData setup, migration plans, and error handling in a dedicated service | `Services/DataService.swift` |
| ✅ | **WindowManager** | Centralized management for auxiliary windows (Welcome, About, etc.) | `Services/WindowManager.swift` — Uses SwiftUI `openWindow`/`dismissWindow` |
| ⏳ | **Refactor ContentView** | Split into `SidebarView`, `DetailView`, and optional `ContentViewModel` | Keep `ContentView` as compositor |
| ✅ | **Navigation Router** | State-driven navigation for deep linking and complex flows | `Services/NavigationRouter.swift` — NavigationManager with NavigationPath |
| ⏳ | **Dependency Injection** | Environment-based DI for services (testability) | Use `EnvironmentKey` pattern |

---

## Phase 2: User Experience (The Polish)

| Status | Feature | Description | Notes |
|:------:|:--------|:------------|:------|
| ✅ | **WelcomeView** | First-run onboarding / "What's New" window | Carousel-style with 4 pages, `Views/Welcome/` |
| ✅ | **Design System** | Centralized tokens for Colors, Fonts, Spacing | `Utilities/DesignSystem.swift` with AppTheme |
| ✅ | **Empty States** | Consistent `ContentUnavailableView` patterns | `EmptyStateView` with presets |
| ✅ | **Error Handling UI** | Alert/sheet presentation for `AppError` | `ErrorState` + `.errorAlert()` modifier |
| ✅ | **Keyboard Shortcuts** | Comprehensive keyboard navigation | Documented in README |

---

## Phase 3: DevOps & Distributability (The Factory)

| Status | Feature | Description | Notes |
|:------:|:--------|:------------|:------|
| ✅ | **SwiftLint** | Code linting via Xcode Build Tool Plugin | `.swiftlint.yml` configured |
| ✅ | **SwiftFormat** | Code formatting via Homebrew CLI | `.swiftformat` configured |
| ✅ | **Makefile** | Local dev commands (`make format`, `make lint`, etc.) | `Makefile` |
| ✅ | **Git Hooks** | Pre-commit formatting/linting | `.githooks/pre-commit` |
| ✅ | **GitHub Actions CI** | Automated build + test on push/PR | `.github/workflows/ci.yml` |
| ✅ | **Project Renaming Script** | Script to rename app (bundle ID, targets, files) | `Scripts/rename-project.sh` |
| ✅ | **DMG Creation** | Professional DMG creation via `create-dmg` | `make dmg` — Uses [sindresorhus/create-dmg](https://github.com/sindresorhus/create-dmg) |

---

## Phase 4: Testing (The Safety Net)

| Status | Feature | Description | Notes |
|:------:|:--------|:------------|:------|
| ⏳ | **Unit Tests** | Sample tests for models and services | `MacAppTemplateTests/` |
| ⏳ | **UI Tests** | Sample tests for critical user flows | `MacAppTemplateUITests/` |
| ⏳ | **Preview Containers** | Rich preview data for all views | `ModelContainer.previewWithData` |
| ⏳ | **Test Utilities** | Mocks, fixtures, and test helpers | `MacAppTemplateTests/Utilities/` |

---

## Phase 5: Documentation & Polish (The Shine)

| Status | Feature | Description | Notes |
|:------:|:--------|:------------|:------|
| ✅ | **README** | Project overview and setup instructions | `README.md` |
| ✅ | **Cursor Rules** | AI-assisted development guidelines | `.cursor/rules/` |
| ⏳ | **Architecture Docs** | Detailed architecture decision records | `Docs/Architecture.md` |
| ✅ | **Contributing Guide** | How to contribute to the template | `CONTRIBUTING.md` |
| ✅ | **Changelog** | Version history and release notes | `CHANGELOG.md` |

---

## Optional Features (Pick What You Need)

> These features are **not required** for all apps. Enable them based on your distribution model and requirements.

| Status | Feature | Description | When to Use | Notes |
|:------:|:--------|:------------|:------------|:------|
| ⏳ | **Sparkle Updates** | Auto-update framework with first-launch permission dialog | Direct distribution (outside Mac App Store) | [sparkle-project.org](https://sparkle-project.org) — Requires appcast feed + EdDSA signing |
| ✅ | **In-App Purchases** | StoreKit 2 integration for purchases/subscriptions | Mac App Store distribution with paid features | `Services/StoreManager.swift`, `Views/Store/` |
| ⏳ | **CloudKit Sync** | iCloud sync for user data across devices | Apps needing cross-device sync | Requires iCloud entitlement |
| ⏳ | **Menu Bar Extra** | Status bar icon with menu/popover | Utility apps needing quick access | `MenuBarExtra` scene |

---

## Quick Stats

| Phase | Total | Done | In Progress | Planned |
|:------|:-----:|:----:|:-----------:|:-------:|
| Phase 1 | 5 | 2 | 0 | 3 |
| Phase 2 | 5 | 5 | 0 | 0 |
| Phase 3 | 7 | 7 | 0 | 0 |
| Phase 4 | 4 | 0 | 0 | 4 |
| Phase 5 | 5 | 4 | 0 | 1 |
| **Core Total** | **26** | **18** | **0** | **8** |
| *Optional* | *4* | *1* | *0* | *3* |

---

## How to Use This File

1. **Pick a feature** from any phase
2. **Update status** to 🔄 when starting work
3. **Update status** to ✅ when complete
4. **Add notes** about implementation decisions
5. **Update Quick Stats** periodically

---

*Last updated: November 29, 2025*

<!-- GitHub Actions CI added: Build, Test, SwiftLint, SwiftFormat check -->

