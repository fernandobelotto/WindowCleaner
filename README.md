# MacAppTemplate

A modern macOS application template built with **SwiftUI**, **SwiftData**, and **Swift 6** concurrency.

![macOS](https://img.shields.io/badge/macOS-15.6+-blue)
![Swift](https://img.shields.io/badge/Swift-6-orange)
![Xcode](https://img.shields.io/badge/Xcode-26+-purple)
![License](https://img.shields.io/badge/License-MIT-green)

## Features

- 🎨 **SwiftUI** with NavigationSplitView for native macOS experience
- 💾 **SwiftData** for modern, type-safe persistence
- ⚡ **Swift 6** concurrency with `@MainActor` default isolation
- 🔒 **App Sandbox** + **Hardened Runtime** enabled
- 🧪 **Swift Testing** framework + **XCUITest** for comprehensive testing
- 📏 **SwiftLint** (Build Tool Plugin) + **SwiftFormat** for code quality
- 🌍 **Localization** ready with String Catalogs
- ⌨️ **Keyboard shortcuts** and menu commands
- ⚙️ **Settings window** with `@AppStorage`

## Requirements

- macOS 15.6+
- Xcode 26+
- Swift 6

## Quick Start

1. **Clone this repository**
   ```bash
   git clone https://github.com/yourusername/MacAppTemplate.git
   cd MacAppTemplate
   ```

2. **Open the project**
   ```bash
   open MacAppTemplate.xcodeproj
   ```

3. **Build and run**
   Press `⌘R` in Xcode

## Project Structure

```
MacAppTemplate/
├── App/
│   └── MacAppTemplateApp.swift    # App entry point, scene configuration
├── Models/
│   └── Item.swift                 # SwiftData models
├── Views/
│   ├── ContentView.swift          # Main NavigationSplitView
│   ├── Components/
│   │   └── ItemRow.swift          # Reusable view components
│   └── Settings/
│       └── SettingsView.swift     # Preferences window (⌘,)
├── Utilities/
│   ├── AppError.swift             # App-specific error types
│   ├── Constants.swift            # Config & Metrics
│   └── Logger.swift               # os.Logger wrapper
└── Resources/
    ├── Assets.xcassets            # App icons, colors, images
    └── Localizable.xcstrings      # Localized strings
```

## Architecture

This template follows a **lightweight MVVM** pattern optimized for SwiftUI + SwiftData:

- **Views**: SwiftUI views using `@Query`, `@State`, `@Environment`
- **ViewModels** (optional): `@Observable` classes for complex business logic
- **Models**: SwiftData `@Model` classes
- **Services**: Networking, file operations, external integrations

See [.cursor/rules/architecture.mdc](.cursor/rules/architecture.mdc) for detailed guidelines.

## Development

### Code Formatting

```bash
# Format all Swift files
swiftformat .

# Check formatting without modifying
swiftformat --lint .
```

### Linting

SwiftLint runs automatically on every build. To run manually:

```bash
swiftlint
swiftlint --fix  # Auto-fix correctable issues
```

### Testing

```bash
# Run all tests
make test

# Or using xcodebuild
xcodebuild test -project MacAppTemplate.xcodeproj -scheme MacAppTemplate -destination "platform=macOS"
```

### Building

```bash
make build
```

### Documentation

Generate and view API documentation using DocC:

```bash
# Generate documentation
make docs

# Generate and open in Xcode
make docs-open

# Generate and preview in browser (http://localhost:8080)
make docs-preview

# Clean documentation artifacts
make docs-clean
```

All public types, methods, and properties are documented with DocC-style comments. See [.cursor/rules/docc-documentation.mdc](.cursor/rules/docc-documentation.mdc) for the complete documentation guide.

## Keyboard Shortcuts

### Application

| Shortcut | Action | Menu |
|----------|--------|------|
| `⌘,` | Open Settings | App Menu |
| `⌘H` | Hide Application | App Menu |
| `⌘Q` | Quit Application | App Menu |

### File Menu

| Shortcut | Action |
|----------|--------|
| `⌘N` | New Item |
| `⌘W` | Close Window |

### Edit Menu

| Shortcut | Action |
|----------|--------|
| `⌫` (Delete) | Delete Selected Item |
| `⌘Z` | Undo |
| `⇧⌘Z` | Redo |
| `⌘X` | Cut |
| `⌘C` | Copy |
| `⌘V` | Paste |
| `⌘A` | Select All |

### Window Menu

| Shortcut | Action |
|----------|--------|
| `⌘M` | Minimize |
| `⌃⌘F` | Toggle Full Screen |

### Help Menu

| Shortcut | Action |
|----------|--------|
| — | Show Welcome |
| — | MacAppTemplate Documentation |
| — | Report an Issue |

> **Note**: Standard macOS shortcuts (`⌘Z`, `⌘C`, `⌘V`, etc.) are provided automatically by the system.

## Configuration

### Entitlements

The app uses App Sandbox with the following capabilities:
- User-selected file read/write access

Modify `MacAppTemplate.entitlements` to add capabilities like:
- Network access
- Camera/microphone
- Location services

### Settings

User preferences are stored using `@AppStorage` and automatically sync via UserDefaults.

## Customization

### Renaming the Project

Use the included renaming script to quickly rebrand the template for your new app:

```bash
# Basic usage (keeps original organization identifier)
./Scripts/rename-project.sh "MyNewApp"

# With custom organization identifier
./Scripts/rename-project.sh "TaskMaster" "com.mycompany"
```

The script will:
- ✅ Rename all directories (`MacAppTemplate/` → `MyNewApp/`)
- ✅ Rename all files (`MacAppTemplateApp.swift` → `MyNewAppApp.swift`)
- ✅ Update bundle identifiers (`com.fernandobelotto.MacAppTemplate` → `com.mycompany.MyNewApp`)
- ✅ Update all code references
- ✅ Clean Xcode DerivedData and caches

After running the script:
1. Open the renamed `.xcodeproj` in Xcode
2. Clean build folder (`⌘⇧K`)
3. Build and run to verify everything works

### Adding New Models

1. Create a new file in `Models/`
2. Define your `@Model` class
3. Add to the schema in `MacAppTemplateApp.swift`
4. See [.cursor/rules/swiftdata-models.mdc](.cursor/rules/swiftdata-models.mdc) for patterns

### Adding New Views

1. Create a new file in `Views/` or `Views/Components/`
2. Follow the structure in [.cursor/rules/swiftui-views.mdc](.cursor/rules/swiftui-views.mdc)
3. Include `#Preview` for Xcode canvas

## Documentation

### Development Guides

Detailed documentation is available in the `.cursor/rules/` directory:

- [Architecture Guidelines](/.cursor/rules/architecture.mdc)
- [SwiftUI Views](/.cursor/rules/swiftui-views.mdc)
- [SwiftData Models](/.cursor/rules/swiftdata-models.mdc)
- [Testing](/.cursor/rules/testing.mdc)
- [DocC Documentation](/.cursor/rules/docc-documentation.mdc) - Writing and generating API docs
- [Code Snippets](/.cursor/rules/code-snippets.mdc)
- [SwiftLint](/.cursor/rules/swiftlint.mdc)
- [SwiftFormat](/.cursor/rules/swiftformat.mdc)

### API Documentation

Browse the generated DocC documentation:

```bash
make docs-preview  # Opens at http://localhost:8080
```

## Contributing

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/amazing-feature`)
3. Run `swiftformat .` before committing
4. Ensure all tests pass
5. Commit your changes (`git commit -m 'Add amazing feature'`)
6. Push to the branch (`git push origin feature/amazing-feature`)
7. Open a Pull Request

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## Acknowledgments

- Apple's SwiftUI and SwiftData frameworks
- [SwiftLint](https://github.com/realm/SwiftLint) for code quality
- [SwiftFormat](https://github.com/nicklockwood/SwiftFormat) for formatting
