# Add Settings View

Create a Settings window (Preferences) for the macOS app.

## Template

### SettingsView.swift
```swift
import SwiftUI

struct SettingsView: View {
    private enum Tabs: Hashable {
        case general, appearance, advanced
    }
    
    var body: some View {
        TabView {
            GeneralSettingsView()
                .tabItem {
                    Label("General", systemImage: "gear")
                }
                .tag(Tabs.general)
            
            AppearanceSettingsView()
                .tabItem {
                    Label("Appearance", systemImage: "paintbrush")
                }
                .tag(Tabs.appearance)
            
            AdvancedSettingsView()
                .tabItem {
                    Label("Advanced", systemImage: "gearshape.2")
                }
                .tag(Tabs.advanced)
        }
        .frame(width: 450, height: 250)
    }
}
```

### GeneralSettingsView.swift
```swift
import SwiftUI

struct GeneralSettingsView: View {
    @AppStorage("autoSave") private var autoSave = true
    @AppStorage("defaultCategory") private var defaultCategory = "None"
    
    var body: some View {
        Form {
            Toggle("Auto-save documents", isOn: $autoSave)
            
            Picker("Default Category", selection: $defaultCategory) {
                Text("None").tag("None")
                Text("Work").tag("Work")
                Text("Personal").tag("Personal")
            }
        }
        .padding()
    }
}
```

### Register in App
```swift
@main
struct WindowCleanerApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .modelContainer(sharedModelContainer)
        
        Settings {
            SettingsView()
        }
    }
}
```

## Instructions

1. **Create Settings Views**
   - Location: `WindowCleaner/Views/Settings/`
   - Create `SettingsView.swift` as the main container
   - Create separate views for each tab

2. **Use @AppStorage for Preferences**
   ```swift
   @AppStorage("keyName") private var value = defaultValue
   ```
   - Automatically persists to UserDefaults
   - Syncs across views

3. **Add to App Scene**
   - Add `Settings { SettingsView() }` scene
   - Opens with ⌘, (standard macOS shortcut)

4. **Common Settings Types**
   - `Toggle` for boolean preferences
   - `Picker` for selection from options
   - `TextField` for string input
   - `Slider` for numeric ranges
   - `ColorPicker` for colors

## @AppStorage Supported Types
- Bool, Int, Double, String
- URL, Data
- RawRepresentable (enums with raw value)

## Custom Storage Key Example
```swift
enum Theme: String, CaseIterable {
    case system, light, dark
}

@AppStorage("theme") private var theme: Theme = .system
```










