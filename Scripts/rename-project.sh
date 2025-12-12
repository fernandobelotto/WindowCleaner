#!/bin/bash

# ============================================================================
# MacAppTemplate — Project Renaming Script
# ============================================================================
#
# This script renames the MacAppTemplate project to a new name, updating:
#   - Directory names
#   - File names
#   - Bundle identifiers
#   - All code references
#   - Xcode project configuration
#
# Usage:
#   ./Scripts/rename-project.sh "MyNewApp" "com.mycompany"
#
# Arguments:
#   $1 - New app name (e.g., "MyNewApp", "TaskManager", "NotePad")
#   $2 - New organization identifier (e.g., "com.mycompany", "io.github.user")
#
# Example:
#   ./Scripts/rename-project.sh "TaskMaster" "com.acme"
#
# This will rename:
#   - MacAppTemplate → TaskMaster
#   - com.fernandobelotto.MacAppTemplate → com.acme.TaskMaster
#
# ============================================================================

set -e  # Exit on any error

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Current values (template defaults)
OLD_NAME="MacAppTemplate"
OLD_ORG="com.fernandobelotto"

# ============================================================================
# Helper Functions
# ============================================================================

print_header() {
    echo ""
    echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${BLUE}  $1${NC}"
    echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
}

print_step() {
    echo -e "${GREEN}▶${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}⚠${NC} $1"
}

print_error() {
    echo -e "${RED}✖${NC} $1"
}

print_success() {
    echo -e "${GREEN}✔${NC} $1"
}

# ============================================================================
# Validation
# ============================================================================

validate_inputs() {
    # Check if arguments provided
    if [ -z "$1" ]; then
        print_error "Missing required argument: new app name"
        echo ""
        echo "Usage: $0 <NewAppName> [organization.identifier]"
        echo ""
        echo "Examples:"
        echo "  $0 \"TaskMaster\""
        echo "  $0 \"TaskMaster\" \"com.acme\""
        exit 1
    fi

    # Validate app name (alphanumeric, no spaces)
    if [[ ! "$1" =~ ^[a-zA-Z][a-zA-Z0-9]*$ ]]; then
        print_error "Invalid app name: '$1'"
        echo "App name must start with a letter and contain only alphanumeric characters."
        echo "No spaces, hyphens, or special characters allowed."
        exit 1
    fi

    # Validate organization identifier if provided
    if [ -n "$2" ]; then
        if [[ ! "$2" =~ ^[a-z][a-z0-9]*(\.[a-z][a-z0-9]*)+$ ]]; then
            print_error "Invalid organization identifier: '$2'"
            echo "Organization identifier must be in reverse domain format."
            echo "Example: com.mycompany, io.github.username"
            exit 1
        fi
    fi
}

# ============================================================================
# Pre-flight Checks
# ============================================================================

preflight_checks() {
    print_header "Pre-flight Checks"

    # Check we're in the right directory
    if [ ! -f "MacAppTemplate.xcodeproj/project.pbxproj" ]; then
        print_error "Must run from project root directory (where MacAppTemplate.xcodeproj is located)"
        exit 1
    fi
    print_success "Running from correct directory"

    # Check for uncommitted changes
    if [ -d ".git" ]; then
        if ! git diff-index --quiet HEAD -- 2>/dev/null; then
            print_warning "You have uncommitted changes. Consider committing before renaming."
            read -p "Continue anyway? (y/N) " -n 1 -r
            echo
            if [[ ! $REPLY =~ ^[Yy]$ ]]; then
                exit 1
            fi
        else
            print_success "Git working directory is clean"
        fi
    fi

    # Check required tools
    if ! command -v sed &> /dev/null; then
        print_error "sed is required but not installed"
        exit 1
    fi
    print_success "Required tools available"
}

# ============================================================================
# Renaming Functions
# ============================================================================

rename_in_files() {
    local old_text="$1"
    local new_text="$2"
    local description="$3"

    print_step "Replacing '$old_text' → '$new_text' ($description)"

    # Find and replace in all relevant files
    # Using -print0 and xargs -0 for safety with special characters
    find . \( \
        -name "*.swift" -o \
        -name "*.pbxproj" -o \
        -name "*.plist" -o \
        -name "*.xcscheme" -o \
        -name "*.xcworkspacedata" -o \
        -name "*.entitlements" -o \
        -name "*.md" -o \
        -name "*.yml" -o \
        -name "*.yaml" -o \
        -name "*.json" -o \
        -name "*.xcstrings" -o \
        -name "Makefile" -o \
        -name ".swiftlint.yml" -o \
        -name ".swiftformat" \
    \) \
        -not -path "./.git/*" \
        -not -path "./Scripts/*" \
        -not -name "rename-project.sh" \
        -type f \
        -print0 2>/dev/null | xargs -0 sed -i '' "s/${old_text}/${new_text}/g" 2>/dev/null || true
}

rename_directories() {
    local old_name="$1"
    local new_name="$2"

    print_step "Renaming directories..."

    # Rename in reverse depth order to avoid path issues
    # UITests
    if [ -d "${old_name}UITests" ]; then
        mv "${old_name}UITests" "${new_name}UITests"
        print_success "  ${old_name}UITests → ${new_name}UITests"
    fi

    # Tests
    if [ -d "${old_name}Tests" ]; then
        mv "${old_name}Tests" "${new_name}Tests"
        print_success "  ${old_name}Tests → ${new_name}Tests"
    fi

    # Main app directory
    if [ -d "${old_name}" ]; then
        mv "${old_name}" "${new_name}"
        print_success "  ${old_name} → ${new_name}"
    fi

    # Xcode project
    if [ -d "${old_name}.xcodeproj" ]; then
        mv "${old_name}.xcodeproj" "${new_name}.xcodeproj"
        print_success "  ${old_name}.xcodeproj → ${new_name}.xcodeproj"
    fi
}

rename_files() {
    local old_name="$1"
    local new_name="$2"

    print_step "Renaming files..."

    # Find and rename files containing the old name
    find . -name "*${old_name}*" \
        -not -path "./.git/*" \
        -not -path "./Scripts/*" \
        -type f 2>/dev/null | while read -r file; do
        local dir=$(dirname "$file")
        local base=$(basename "$file")
        local newbase="${base//${old_name}/${new_name}}"
        if [ "$base" != "$newbase" ]; then
            mv "$file" "$dir/$newbase"
            print_success "  $base → $newbase"
        fi
    done
}

# ============================================================================
# Main Script
# ============================================================================

main() {
    local NEW_NAME="$1"
    local NEW_ORG="${2:-$OLD_ORG}"  # Default to old org if not provided

    print_header "MacAppTemplate → $NEW_NAME"
    echo ""
    echo "  Old Name:   $OLD_NAME"
    echo "  New Name:   $NEW_NAME"
    echo "  Old Bundle: $OLD_ORG.$OLD_NAME"
    echo "  New Bundle: $NEW_ORG.$NEW_NAME"
    echo ""

    # Validate inputs
    validate_inputs "$NEW_NAME" "$NEW_ORG"

    # Run pre-flight checks
    preflight_checks

    # Confirm before proceeding
    print_header "Ready to Rename"
    echo ""
    echo "This will rename all occurrences of:"
    echo "  • $OLD_NAME → $NEW_NAME"
    echo "  • $OLD_ORG.$OLD_NAME → $NEW_ORG.$NEW_NAME"
    echo ""
    read -p "Proceed with renaming? (y/N) " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        echo "Aborted."
        exit 0
    fi

    # ========================================================================
    # Step 1: Replace text in files
    # ========================================================================
    print_header "Step 1: Updating File Contents"

    # Replace bundle identifier (most specific first)
    rename_in_files "$OLD_ORG.$OLD_NAME" "$NEW_ORG.$NEW_NAME" "bundle identifier"

    # Replace organization identifier
    if [ "$NEW_ORG" != "$OLD_ORG" ]; then
        rename_in_files "$OLD_ORG" "$NEW_ORG" "organization identifier"
    fi

    # Replace app name
    rename_in_files "$OLD_NAME" "$NEW_NAME" "app name"

    # ========================================================================
    # Step 2: Rename files
    # ========================================================================
    print_header "Step 2: Renaming Files"
    rename_files "$OLD_NAME" "$NEW_NAME"

    # ========================================================================
    # Step 3: Rename directories
    # ========================================================================
    print_header "Step 3: Renaming Directories"
    rename_directories "$OLD_NAME" "$NEW_NAME"

    # ========================================================================
    # Step 4: Clean up Xcode artifacts
    # ========================================================================
    print_header "Step 4: Cleaning Up"

    print_step "Removing DerivedData..."
    rm -rf ~/Library/Developer/Xcode/DerivedData/${OLD_NAME}-* 2>/dev/null || true
    rm -rf ~/Library/Developer/Xcode/DerivedData/${NEW_NAME}-* 2>/dev/null || true
    print_success "DerivedData cleaned"

    print_step "Removing xcuserdata..."
    find . -name "xcuserdata" -type d -exec rm -rf {} + 2>/dev/null || true
    print_success "xcuserdata cleaned"

    # ========================================================================
    # Done!
    # ========================================================================
    print_header "✅ Renaming Complete!"
    echo ""
    echo "Your project has been renamed to: $NEW_NAME"
    echo ""
    echo "Next steps:"
    echo "  1. Open ${NEW_NAME}.xcodeproj in Xcode"
    echo "  2. Clean build folder (⌘⇧K)"
    echo "  3. Build and run to verify everything works"
    echo "  4. Update the README.md with your project details"
    echo "  5. Commit the changes: git add -A && git commit -m 'Rename to $NEW_NAME'"
    echo ""
    print_warning "If you see any issues, check the Xcode project settings manually."
    echo ""
}

# Run main with all arguments
main "$@"









