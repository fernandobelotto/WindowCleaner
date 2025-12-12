# Add New Window

Create a new window type for the macOS app (utility window, document window, or panel).

## User Input
Describe the window you need (purpose, size, behavior).

## Window Types

### Utility Window (Fixed Size)
```swift
// In MacAppTemplateApp.swift
@main
struct MacAppTemplateApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .modelContainer(sharedModelContainer)
        
        // Utility window with fixed identifier
        Window("Inspector", id: "inspector") {
            InspectorView()
        }
        .windowStyle(.hiddenTitleBar)
        .windowResizability(.contentSize)
        .defaultPosition(.topTrailing)
    }
}
```

### Document-Based Window
```swift
// For apps that work with files
DocumentGroup(newDocument: MyDocument()) { file in
    DocumentView(document: file.$document)
}
```

### Auxiliary Window (Openable Programmatically)
```swift
// Define the window
WindowGroup("Details", id: "details", for: Item.ID.self) { $itemId in
    if let itemId {
        DetailView(itemId: itemId)
    }
}

// Open from another view
@Environment(\.openWindow) private var openWindow

Button("Open Details") {
    openWindow(id: "details", value: item.id)
}
```

### Menu Bar Extra
```swift
// Adds icon to menu bar
MenuBarExtra("Status", systemImage: "star.fill") {
    StatusMenuView()
}
.menuBarExtraStyle(.window) // or .menu for simple dropdown
```

## Window Modifiers

### Size & Position
```swift
Window("Utility", id: "utility") {
    UtilityView()
}
.defaultSize(width: 400, height: 300)
.defaultPosition(.center)
.windowResizability(.contentMinSize) // .automatic, .contentSize, .contentMinSize
```

### Style
```swift
.windowStyle(.hiddenTitleBar) // Hides title bar
.windowStyle(.automatic)       // Default
.windowStyle(.plain)          // Minimal chrome
```

### Toolbar
```swift
.windowToolbarStyle(.unified)           // Standard
.windowToolbarStyle(.unifiedCompact)    // Smaller
.windowToolbarStyle(.expanded)          // Large
```

## Instructions

1. **Choose Window Type**
   - `WindowGroup` for multiple instances
   - `Window` for single instance
   - `DocumentGroup` for file-based
   - `MenuBarExtra` for menu bar

2. **Add to App Scene**
   ```swift
   var body: some Scene {
       WindowGroup { ... }
       
       // Add new window here
       Window("Name", id: "identifier") {
           NewWindowView()
       }
   }
   ```

3. **Create the View**
   - Location: `MacAppTemplate/Views/Screens/`
   - Design for the window's purpose

4. **Add Open/Close Triggers**
   ```swift
   @Environment(\.openWindow) private var openWindow
   @Environment(\.dismissWindow) private var dismissWindow
   
   // Open
   openWindow(id: "identifier")
   
   // Close
   dismissWindow(id: "identifier")
   ```

5. **Add Menu Command** (optional)
   ```swift
   .commands {
       CommandGroup(after: .windowList) {
           Button("Show Inspector") {
               openWindow(id: "inspector")
           }
           .keyboardShortcut("I", modifiers: [.command, .option])
       }
   }
   ```

## Common Patterns

### Singleton Window (one instance)
```swift
Window("Preferences", id: "preferences") {
    SettingsView()
}
```

### Data-Driven Window
```swift
WindowGroup("Item Details", id: "item-details", for: Item.ID.self) { $itemId in
    if let itemId {
        ItemDetailView(itemId: itemId)
            .modelContainer(sharedModelContainer)
    }
}
```










