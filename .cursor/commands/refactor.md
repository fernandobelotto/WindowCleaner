# Refactor Code

Improve code quality, structure, and maintainability.

## User Input
Specify what you want to refactor (file, feature, pattern).

## Refactoring Checklist

### Code Organization
- [ ] One primary type per file
- [ ] Related code grouped with `// MARK: -`
- [ ] Extensions in separate files for large types
- [ ] Clear file naming matching type names

### SwiftUI View Refactoring
```swift
// ❌ Before: Monolithic view
struct ContentView: View {
    var body: some View {
        VStack {
            // 100+ lines of UI code
        }
    }
}

// ✅ After: Extracted subviews
struct ContentView: View {
    var body: some View {
        VStack {
            HeaderView()
            ContentSection()
            FooterView()
        }
    }
}

// In same file for small extractions
private extension ContentView {
    var headerView: some View { ... }
}

// Or separate files for reusable components
// Views/Components/HeaderView.swift
```

### Extract View Model
```swift
// ❌ Before: Logic in view
struct ItemListView: View {
    @Query var items: [Item]
    @State private var searchText = ""
    
    var filteredItems: [Item] {
        // Complex filtering logic
    }
    
    func deleteItem(_ item: Item) {
        // Deletion logic
    }
}

// ✅ After: Logic in view model
@Observable
class ItemListViewModel {
    var searchText = ""
    
    func filteredItems(from items: [Item]) -> [Item] {
        // Complex filtering logic
    }
    
    @MainActor
    func deleteItem(_ item: Item, context: ModelContext) {
        // Deletion logic
    }
}

struct ItemListView: View {
    @Query var items: [Item]
    @State private var viewModel = ItemListViewModel()
    
    var body: some View {
        List(viewModel.filteredItems(from: items)) { ... }
    }
}
```

### Extract Protocol
```swift
// ❌ Before: Concrete dependency
class DataService {
    func fetch() async throws -> [Item] { ... }
}

struct MyView: View {
    let service = DataService()
}

// ✅ After: Protocol for testing
protocol DataServiceProtocol {
    func fetch() async throws -> [Item]
}

class DataService: DataServiceProtocol {
    func fetch() async throws -> [Item] { ... }
}

class MockDataService: DataServiceProtocol {
    func fetch() async throws -> [Item] {
        return [Item(timestamp: Date())]
    }
}
```

### Consolidate Duplicated Code
```swift
// ❌ Before: Repeated patterns
ForEach(items) { item in
    HStack {
        Image(systemName: "doc")
        Text(item.name)
        Spacer()
        Text(item.date, style: .date)
    }
}

// ✅ After: Extracted row view
struct ItemRow: View {
    let item: Item
    
    var body: some View {
        HStack {
            Image(systemName: "doc")
            Text(item.name)
            Spacer()
            Text(item.date, style: .date)
        }
    }
}
```

## Refactoring Patterns

### Replace Magic Values
```swift
// ❌ Before
.frame(width: 200, height: 44)
.foregroundColor(Color(red: 0.2, green: 0.4, blue: 0.8))

// ✅ After
private enum Layout {
    static let buttonWidth: CGFloat = 200
    static let buttonHeight: CGFloat = 44
}

extension Color {
    static let appPrimary = Color(red: 0.2, green: 0.4, blue: 0.8)
}
```

### Improve Error Handling
```swift
// ❌ Before: Silent failure
try? riskyOperation()

// ✅ After: Proper handling
do {
    try riskyOperation()
} catch {
    logger.error("Operation failed: \(error.localizedDescription)")
    showError(error)
}
```

## Instructions

1. **Identify Refactoring Target**
   - Read the code thoroughly
   - Identify code smells (duplication, long methods, etc.)
   - Plan the refactoring steps

2. **Apply Refactoring**
   - Make small, incremental changes
   - Keep the code compiling between steps
   - Preserve existing behavior

3. **Verify**
   - Run tests to ensure nothing broke
   - Build to check for warnings
   - Manual testing if needed

4. **Document**
   - Update comments if behavior changed
   - Add comments for non-obvious code










