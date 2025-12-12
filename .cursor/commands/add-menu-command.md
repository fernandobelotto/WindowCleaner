# Add Menu Command

Add a new menu bar command with keyboard shortcut following macOS conventions.

## User Input
Describe the menu command (name, action, keyboard shortcut, menu location).

## Template

```swift
// In WindowCleanerApp.swift
@main
struct WindowCleanerApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .modelContainer(sharedModelContainer)
        .commands {
            // File Menu additions
            CommandGroup(after: .newItem) {
                Button("New from Template...") {
                    // Action
                }
                .keyboardShortcut("N", modifiers: [.command, .shift])
                
                Divider()
            }
            
            // Custom Menu
            CommandMenu("Custom") {
                Button("Action Name") {
                    // Action
                }
                .keyboardShortcut("A", modifiers: [.command])
            }
        }
    }
}
```

## Standard Menu Locations
- `.newItem` - File > New
- `.saveItem` - File > Save
- `.importExport` - File > Import/Export
- `.printItem` - File > Print
- `.undoRedo` - Edit > Undo/Redo
- `.pasteboard` - Edit > Copy/Paste
- `.textEditing` - Edit > Text operations
- `.textFormatting` - Format menu
- `.toolbar` - View > Toolbar
- `.sidebar` - View > Sidebar
- `.windowSize` - Window menu
- `.help` - Help menu

## Keyboard Shortcut Modifiers
- `.command` - ⌘
- `.shift` - ⇧
- `.option` - ⌥
- `.control` - ⌃

## Instructions

1. **Choose Menu Location**
   - Use `CommandGroup(before/after/replacing:)` for standard menus
   - Use `CommandMenu("Name")` for custom menus

2. **Add Keyboard Shortcut**
   - Follow macOS HIG for standard shortcuts
   - Avoid conflicts with system shortcuts
   - Use `.keyboardShortcut(.delete)` for special keys

3. **Handle State**
   - For state-dependent commands, use `@FocusedValue` or `@FocusedBinding`
   - Disable unavailable commands with `.disabled(condition)`

## FocusedValue Pattern
```swift
// Define focused value key
struct FocusedItemKey: FocusedValueKey {
    typealias Value = Item
}

extension FocusedValues {
    var selectedItem: Item? {
        get { self[FocusedItemKey.self] }
        set { self[FocusedItemKey.self] = newValue }
    }
}

// In view
.focusedValue(\.selectedItem, selectedItem)

// In command
@FocusedValue(\.selectedItem) var selectedItem

Button("Delete") {
    // Use selectedItem
}
.disabled(selectedItem == nil)
```










