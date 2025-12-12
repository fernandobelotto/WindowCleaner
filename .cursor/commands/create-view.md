# Create SwiftUI View

Generate a new SwiftUI view following project conventions.

## User Input
Describe the view you need (purpose, data requirements, interactions).

## View Templates

### Standard View
```swift
import SwiftUI

struct ViewName: View {
    // MARK: - Environment
    @Environment(\.modelContext) private var modelContext
    
    // MARK: - State
    @State private var isLoading = false
    
    // MARK: - Body
    var body: some View {
        // View content
    }
}

// MARK: - Subviews
private extension ViewName {
    var headerView: some View {
        // ...
    }
}

#Preview {
    ViewName()
        .modelContainer(for: Item.self, inMemory: true)
}
```

### View with SwiftData Query
```swift
import SwiftUI
import SwiftData

struct ListView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Item.timestamp, order: .reverse) private var items: [Item]
    
    var body: some View {
        List(items) { item in
            // Row content
        }
    }
}
```

### Detail View
```swift
import SwiftUI

struct DetailView: View {
    let item: Item
    
    var body: some View {
        Form {
            // Detail content
        }
        .navigationTitle("Details")
    }
}
```

## Instructions

1. **Determine View Type**
   - List/Collection view → Use `@Query`
   - Detail view → Accept model as parameter
   - Form/Editor → Use `@State` or `@Bindable`
   - Settings → Use `@AppStorage`

2. **Create the File**
   - Location: `WindowCleaner/Views/[ViewName].swift`
   - Or: `WindowCleaner/Views/Components/` for reusable components
   - Or: `WindowCleaner/Views/Screens/` for full-screen views

3. **Add Preview**
   - Include `#Preview` with mock data
   - Use `.modelContainer(for:inMemory:)` for SwiftData views

4. **Follow macOS Patterns**
   - Use `NavigationSplitView` for sidebar navigation
   - Use `Form` for settings/editors
   - Use `Table` for data grids
   - Support keyboard shortcuts where appropriate

## macOS-Specific Considerations
- Minimum window sizes with `.frame(minWidth:minHeight:)`
- Toolbar items with `.toolbar { }`
- Context menus with `.contextMenu { }`
- Drag and drop with `.draggable()` and `.dropDestination()`










