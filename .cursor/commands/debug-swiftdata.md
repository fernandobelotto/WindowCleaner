# Debug SwiftData Issues

Diagnose and fix common SwiftData problems.

## Common Issues & Solutions

### 1. Model Not Persisting
```swift
// ❌ Problem: Changes not saved
modelContext.insert(item)
// Missing save!

// ✅ Solution: Explicit save (or rely on auto-save)
modelContext.insert(item)
try? modelContext.save()

// Or configure auto-save (default behavior)
```

### 2. Query Not Updating
```swift
// ❌ Problem: @Query not reflecting changes
@Query var items: [Item]

// ✅ Solution: Ensure using same ModelContext
// Check that insert/delete uses @Environment(\.modelContext)
@Environment(\.modelContext) private var modelContext
```

### 3. Relationship Issues
```swift
// ❌ Problem: Relationship not loading
@Model class Parent {
    var children: [Child] // Missing @Relationship
}

// ✅ Solution: Explicit relationship
@Model class Parent {
    @Relationship(deleteRule: .cascade)
    var children: [Child] = []
}
```

### 4. Preview Crashes
```swift
// ❌ Problem: Preview crashes with SwiftData
#Preview {
    ContentView() // No ModelContainer
}

// ✅ Solution: Provide in-memory container
#Preview {
    ContentView()
        .modelContainer(for: Item.self, inMemory: true)
}

// Or with sample data
#Preview {
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(for: Item.self, configurations: config)
    
    let sample = Item(timestamp: Date())
    container.mainContext.insert(sample)
    
    return ContentView()
        .modelContainer(container)
}
```

### 5. Migration Errors
```swift
// ❌ Problem: Schema changed, app crashes on launch

// ✅ Solution: Use versioned schemas
enum SchemaV1: VersionedSchema {
    static var versionIdentifier = Schema.Version(1, 0, 0)
    static var models: [any PersistentModel.Type] {
        [ItemV1.self]
    }
    
    @Model class ItemV1 {
        var timestamp: Date
    }
}

// Then create migration plan
enum MigrationPlan: SchemaMigrationPlan {
    static var schemas: [any VersionedSchema.Type] {
        [SchemaV1.self, SchemaV2.self]
    }
    
    static var stages: [MigrationStage] {
        [migrateV1toV2]
    }
    
    static let migrateV1toV2 = MigrationStage.lightweight(
        fromVersion: SchemaV1.self,
        toVersion: SchemaV2.self
    )
}
```

### 6. Actor Isolation with ModelContext
```swift
// ❌ Problem: ModelContext used off main actor
Task.detached {
    modelContext.insert(item) // Wrong actor
}

// ✅ Solution: Use MainActor
Task { @MainActor in
    modelContext.insert(item)
}
```

## Debugging Tools

### Enable SwiftData Logging
```swift
// In scheme arguments:
-com.apple.CoreData.SQLDebug 1
-com.apple.CoreData.Logging.stderr 1
```

### Print Fetch Results
```swift
let descriptor = FetchDescriptor<Item>()
do {
    let items = try modelContext.fetch(descriptor)
    print("Fetched \(items.count) items")
    items.forEach { print("  - \($0)") }
} catch {
    print("Fetch failed: \(error)")
}
```

### Check Model Registration
```swift
// In WindowCleanerApp.swift
let schema = Schema([
    Item.self,
    // All models must be listed here
])
print("Schema models: \(schema.entities.map { $0.name })")
```

## Diagnostic Steps

1. **Check Console for Errors**
   - Look for CoreData/SwiftData errors
   - Check for actor isolation warnings

2. **Verify Model Configuration**
   - All models in schema
   - Relationships have delete rules
   - Initializers provide all required values

3. **Check Context Usage**
   - Same context for related operations
   - Context operations on main actor
   - Save called when needed

4. **Test in Isolation**
   - Write unit test with in-memory container
   - Reproduce the issue in controlled environment










