# MacAppTemplate Makefile
# Common development tasks for the macOS app

.PHONY: all format lint test test-unit test-ui test-ui-fast test-perf build clean help setup package dmg dmg-only archive clean-all docs docs-open docs-preview docs-clean

# Build directory for distribution artifacts
BUILD_DIR = build
DERIVED_DATA = $(BUILD_DIR)/DerivedData
APP_NAME = MacAppTemplate

# Default target
all: format lint build

# Format all Swift files using SwiftFormat
format:
	@echo "📝 Formatting Swift files..."
	@swiftformat .
	@echo "✅ Formatting complete"

# Run SwiftLint
lint:
	@echo "🔍 Running SwiftLint..."
	@swiftlint
	@echo "✅ Linting complete"

# Run SwiftLint in strict mode (treats warnings as errors)
lint-strict:
	@echo "🔍 Running SwiftLint (strict mode)..."
	@swiftlint --strict

# Auto-fix correctable SwiftLint violations
lint-fix:
	@echo "🔧 Auto-fixing SwiftLint violations..."
	@swiftlint --fix
	@echo "✅ Auto-fix complete"

# Run all tests
test:
	@echo "🧪 Running tests..."
	@xcodebuild test \
		-project $(APP_NAME).xcodeproj \
		-scheme $(APP_NAME) \
		-destination "platform=macOS" \
		-quiet
	@echo "✅ Tests complete"

# Run tests with verbose output
test-verbose:
	@echo "🧪 Running tests (verbose)..."
	@xcodebuild test \
		-project $(APP_NAME).xcodeproj \
		-scheme $(APP_NAME) \
		-destination "platform=macOS"

# Run unit tests only
test-unit:
	@echo "🧪 Running unit tests..."
	@xcodebuild test \
		-project $(APP_NAME).xcodeproj \
		-scheme $(APP_NAME) \
		-destination "platform=macOS" \
		-only-testing:$(APP_NAME)Tests \
		-quiet
	@echo "✅ Unit tests complete"

# Run UI tests only
test-ui:
	@echo "🧪 Running UI tests..."
	@xcodebuild test \
		-project $(APP_NAME).xcodeproj \
		-scheme $(APP_NAME) \
		-destination "platform=macOS" \
		-only-testing:$(APP_NAME)UITests \
		-quiet
	@echo "✅ UI tests complete"

# Run UI tests fast (skip performance tests)
test-ui-fast:
	@echo "🧪 Running UI tests (fast - skipping performance tests)..."
	@xcodebuild test \
		-project $(APP_NAME).xcodeproj \
		-scheme $(APP_NAME) \
		-destination "platform=macOS" \
		-only-testing:$(APP_NAME)UITests \
		-skip-testing:$(APP_NAME)UITests/LaunchPerformanceTests \
		-quiet
	@echo "✅ Fast UI tests complete"

# Run performance tests only
test-perf:
	@echo "🧪 Running performance tests..."
	@xcodebuild test \
		-project $(APP_NAME).xcodeproj \
		-scheme $(APP_NAME) \
		-destination "platform=macOS" \
		-only-testing:$(APP_NAME)UITests/LaunchPerformanceTests \
		-quiet
	@echo "✅ Performance tests complete"

# Build the app (Debug)
build:
	@echo "🔨 Building (Debug)..."
	@xcodebuild build \
		-project $(APP_NAME).xcodeproj \
		-scheme $(APP_NAME) \
		-destination "platform=macOS" \
		-configuration Debug \
		-quiet
	@echo "✅ Build complete"

# Build the app (Release)
build-release:
	@echo "🔨 Building (Release)..."
	@xcodebuild build \
		-project $(APP_NAME).xcodeproj \
		-scheme $(APP_NAME) \
		-destination "platform=macOS" \
		-configuration Release \
		-quiet
	@echo "✅ Release build complete"

# Package the app for distribution (no code signing required)
# This builds in Release mode and copies the .app to build/
package:
	@echo "📦 Packaging (Release)..."
	@mkdir -p $(BUILD_DIR)
	@xcodebuild build \
		-project $(APP_NAME).xcodeproj \
		-scheme $(APP_NAME) \
		-destination "platform=macOS" \
		-configuration Release \
		-derivedDataPath $(DERIVED_DATA) \
		-quiet
	@rm -rf "$(BUILD_DIR)/$(APP_NAME).app"
	@cp -R "$(DERIVED_DATA)/Build/Products/Release/$(APP_NAME).app" "$(BUILD_DIR)/"
	@echo "✅ Package complete: $(BUILD_DIR)/$(APP_NAME).app"

# Create DMG for distribution
# Uses sindresorhus/create-dmg: https://github.com/sindresorhus/create-dmg
dmg: package
	@echo "💿 Creating DMG..."
	@create-dmg --overwrite --no-code-sign "$(BUILD_DIR)/$(APP_NAME).app" $(BUILD_DIR)
	@echo "✅ DMG created in $(BUILD_DIR)/"
	@ls -lh $(BUILD_DIR)/*.dmg 2>/dev/null || true

# Create DMG only (if app already exists in build/)
dmg-only:
	@echo "💿 Creating DMG..."
	@if [ ! -d "$(BUILD_DIR)/$(APP_NAME).app" ]; then \
		echo "❌ Error: $(BUILD_DIR)/$(APP_NAME).app not found"; \
		echo "Run 'make package' first to create the app bundle"; \
		exit 1; \
	fi
	@create-dmg --overwrite --no-code-sign "$(BUILD_DIR)/$(APP_NAME).app" $(BUILD_DIR)
	@echo "✅ DMG created in $(BUILD_DIR)/"
	@ls -lh $(BUILD_DIR)/*.dmg 2>/dev/null || true

# Archive and export with Developer ID signing (requires Apple Developer Program)
# Use this for production distribution outside the Mac App Store
archive:
	@echo "📦 Archiving with Developer ID signing..."
	@echo "⚠️  This requires an Apple Developer Program membership (\$$99/year)"
	@mkdir -p $(BUILD_DIR)
	@xcodebuild archive \
		-project $(APP_NAME).xcodeproj \
		-scheme $(APP_NAME) \
		-destination "platform=macOS" \
		-configuration Release \
		-archivePath $(BUILD_DIR)/$(APP_NAME).xcarchive \
		-quiet
	@xcodebuild -exportArchive \
		-archivePath $(BUILD_DIR)/$(APP_NAME).xcarchive \
		-exportPath $(BUILD_DIR) \
		-exportOptionsPlist Scripts/ExportOptions.plist \
		-quiet
	@echo "✅ Archive complete: $(BUILD_DIR)/$(APP_NAME).app"

# Create signed DMG (requires Developer ID certificate)
dmg-signed: archive
	@echo "💿 Creating signed DMG..."
	@create-dmg --overwrite "$(BUILD_DIR)/$(APP_NAME).app" $(BUILD_DIR)
	@echo "✅ Signed DMG created in $(BUILD_DIR)/"
	@ls -lh $(BUILD_DIR)/*.dmg 2>/dev/null || true

# Clean build artifacts
clean:
	@echo "🧹 Cleaning..."
	@xcodebuild clean \
		-project $(APP_NAME).xcodeproj \
		-scheme $(APP_NAME) \
		-quiet
	@rm -rf ~/Library/Developer/Xcode/DerivedData/$(APP_NAME)-*
	@echo "✅ Clean complete"

# Clean all including distribution artifacts
clean-all: clean
	@rm -rf $(BUILD_DIR)/
	@echo "✅ All build artifacts cleaned (including $(BUILD_DIR)/)"

# Documentation targets

# Generate DocC documentation
docs:
	@echo "📚 Generating documentation..."
	@xcodebuild docbuild \
		-scheme $(APP_NAME) \
		-destination 'platform=macOS' \
		-derivedDataPath $(DERIVED_DATA)
	@echo "✅ Documentation generated at:"
	@echo "   $(DERIVED_DATA)/Build/Products/Debug/$(APP_NAME).doccarchive"

# Open documentation in Xcode
docs-open: docs
	@echo "📖 Opening documentation in Xcode..."
	@open $(DERIVED_DATA)/Build/Products/Debug/$(APP_NAME).doccarchive

# Preview documentation in web browser
docs-preview: docs
	@echo "🌐 Starting documentation preview server..."
	@echo "Open http://localhost:8080 in your browser"
	@echo "Press Ctrl+C to stop the server"
	@xcrun docc preview \
		--allow-arbitrary-catalog-directories \
		$(DERIVED_DATA)/Build/Products/Debug/$(APP_NAME).doccarchive

# Clean documentation build artifacts
docs-clean:
	@echo "🧹 Cleaning documentation..."
	@rm -rf $(DERIVED_DATA)/Build/Products/Debug/*.doccarchive
	@echo "✅ Documentation cleaned"

# Setup development environment
setup:
	@echo "⚙️  Setting up development environment..."
	@echo ""
	@echo "Installing SwiftFormat..."
	@brew install swiftformat || brew upgrade swiftformat
	@echo ""
	@echo "Installing SwiftLint..."
	@brew install swiftlint || brew upgrade swiftlint
	@echo ""
	@echo "Installing create-dmg dependencies..."
	@echo "  → GraphicsMagick & ImageMagick (for DMG icon generation)"
	@brew install graphicsmagick imagemagick || true
	@echo "  → create-dmg (via npm)"
	@npm install --global create-dmg || true
	@echo ""
	@echo "Setting up git hooks..."
	@git config core.hooksPath .githooks
	@chmod +x .githooks/* 2>/dev/null || true
	@echo ""
	@echo "✅ Setup complete"

# Open project in Xcode
open:
	@open $(APP_NAME).xcodeproj

# Show help
help:
	@echo "MacAppTemplate - Available Commands"
	@echo "===================================="
	@echo ""
	@echo "Development:"
	@echo "  make format        - Format all Swift files"
	@echo "  make lint          - Run SwiftLint"
	@echo "  make lint-strict   - Run SwiftLint (strict mode)"
	@echo "  make lint-fix      - Auto-fix SwiftLint violations"
	@echo "  make test          - Run all tests"
	@echo "  make test-unit     - Run unit tests only"
	@echo "  make test-ui       - Run UI tests only"
	@echo "  make test-ui-fast  - Run UI tests (skip performance tests)"
	@echo "  make test-perf     - Run performance tests only"
	@echo "  make test-verbose  - Run tests with verbose output"
	@echo "  make build         - Build (Debug)"
	@echo "  make build-release - Build (Release)"
	@echo ""
	@echo "Distribution:"
	@echo "  make package       - Build release .app (no signing required)"
	@echo "  make dmg           - Create DMG (no signing required)"
	@echo "  make dmg-only      - Create DMG from existing .app"
	@echo "  make archive       - Archive with Developer ID (requires Apple Developer Program)"
	@echo "  make dmg-signed    - Create signed DMG (requires Apple Developer Program)"
	@echo ""
	@echo "Documentation:"
	@echo "  make docs          - Generate DocC documentation"
	@echo "  make docs-open     - Generate and open in Xcode"
	@echo "  make docs-preview  - Generate and preview in browser"
	@echo "  make docs-clean    - Clean documentation artifacts"
	@echo ""
	@echo "Maintenance:"
	@echo "  make clean         - Clean Xcode build artifacts"
	@echo "  make clean-all     - Clean all (including build/ directory)"
	@echo "  make setup         - Setup development environment"
	@echo "  make open          - Open project in Xcode"
	@echo "  make help          - Show this help"
	@echo ""
