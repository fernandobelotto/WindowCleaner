# Fix Swift 6 Concurrency Issues

Diagnose and fix Swift 6 concurrency warnings and errors.

## Common Issues & Solutions

### 1. Main Actor Isolation
```swift
// ❌ Error: Call to main actor-isolated method from nonisolated context
class Service {
    func update() {
        modelContext.insert(item) // modelContext is @MainActor
    }
}

// ✅ Solution 1: Make method @MainActor
class Service {
    @MainActor
    func update() {
        modelContext.insert(item)
    }
}

// ✅ Solution 2: Use Task for async context
class Service {
    func update() async {
        await MainActor.run {
            modelContext.insert(item)
        }
    }
}
```

### 2. Sendable Conformance
```swift
// ❌ Error: Type 'MyClass' does not conform to 'Sendable'
class MyClass {
    var mutableState: String = ""
}

// ✅ Solution 1: Make it a struct (preferred)
struct MyStruct: Sendable {
    let state: String
}

// ✅ Solution 2: Use actor
actor MyActor {
    var mutableState: String = ""
}

// ✅ Solution 3: Mark as @unchecked Sendable (use carefully)
final class MyClass: @unchecked Sendable {
    private let lock = NSLock()
    private var _state: String = ""
}
```

### 3. Capturing Non-Sendable Types
```swift
// ❌ Error: Capture of non-sendable type in @Sendable closure
let context = modelContext
Task {
    context.insert(item) // context captured across actor boundary
}

// ✅ Solution: Stay on same actor
Task { @MainActor in
    modelContext.insert(item)
}
```

### 4. Property Access Across Actors
```swift
// ❌ Error: Property 'value' isolated to global actor 'MainActor'
@MainActor var value: Int = 0

nonisolated func readValue() -> Int {
    return value // Cannot access from nonisolated
}

// ✅ Solution: Make async
nonisolated func readValue() async -> Int {
    return await value
}
```

### 5. Async in View Body
```swift
// ❌ Bad: Body is not async
var body: some View {
    Button("Load") {
        await loadData() // Cannot await here
    }
}

// ✅ Good: Use Task
var body: some View {
    Button("Load") {
        Task {
            await loadData()
        }
    }
}
```

## Project Context

This project uses `SWIFT_DEFAULT_ACTOR_ISOLATION = MainActor`, which means:
- All code defaults to main actor unless explicitly `nonisolated`
- SwiftUI views and SwiftData operations are naturally on main actor
- Use `nonisolated` for CPU-heavy work that can run off main thread

## Diagnostic Steps

1. **Identify the Error**
   - Build the project
   - Read the exact error message
   - Note the file and line number

2. **Understand the Context**
   - What actor is the calling code on?
   - What actor does the called code require?
   - Is data being passed across actor boundaries?

3. **Choose the Right Fix**
   - Prefer keeping related code on same actor
   - Use `nonisolated` for pure computations
   - Use `Task { @MainActor in }` for UI updates from background

4. **Verify the Fix**
   - Rebuild and check for new errors
   - Ensure no runtime issues
   - Run tests










