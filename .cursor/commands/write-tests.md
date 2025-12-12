# Write Tests

Generate comprehensive tests for existing code using Swift Testing framework.

## User Input
Specify what code you want to test (file, function, feature).

## Swift Testing Framework Patterns

### Basic Test
```swift
import Testing
@testable import WindowCleaner

struct ItemTests {
    @Test func itemInitialization() {
        let date = Date()
        let item = Item(timestamp: date)
        
        #expect(item.timestamp == date)
    }
}
```

### Async Tests
```swift
@Test func asyncOperation() async throws {
    let result = try await service.fetchData()
    #expect(result.count > 0)
}
```

### Parameterized Tests
```swift
@Test(arguments: ["valid", "also-valid", "still-valid"])
func validInputs(input: String) {
    #expect(validator.isValid(input))
}
```

### Expected Errors
```swift
@Test func throwsOnInvalidInput() {
    #expect(throws: ValidationError.self) {
        try validator.validate("")
    }
}
```

### Test with Setup
```swift
struct ServiceTests {
    let service: MyService
    
    init() {
        service = MyService()
    }
    
    @Test func serviceWorks() async throws {
        let result = try await service.doWork()
        #expect(result.isSuccess)
    }
}
```

## SwiftData Testing Pattern

```swift
import Testing
import SwiftData
@testable import WindowCleaner

struct ItemModelTests {
    @Test func itemCRUD() throws {
        // Setup in-memory container
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        let container = try ModelContainer(for: Item.self, configurations: config)
        let context = container.mainContext
        
        // Create
        let item = Item(timestamp: Date())
        context.insert(item)
        try context.save()
        
        // Read
        let descriptor = FetchDescriptor<Item>()
        let items = try context.fetch(descriptor)
        #expect(items.count == 1)
        
        // Update
        items[0].timestamp = Date().addingTimeInterval(3600)
        try context.save()
        
        // Delete
        context.delete(items[0])
        try context.save()
        
        let remaining = try context.fetch(descriptor)
        #expect(remaining.isEmpty)
    }
}
```

## Instructions

1. **Identify Test Targets**
   - Read the code to understand what needs testing
   - Focus on business logic, models, and services
   - Identify edge cases and error conditions

2. **Create Test File**
   - Location: `WindowCleanerTests/`
   - Name: `[ClassName]Tests.swift`

3. **Write Tests**
   - Start with happy path
   - Add edge cases
   - Add error conditions
   - Use descriptive test names

4. **Run Tests**
   - Use `/run-tests` command
   - Verify all tests pass

## Test Naming Convention
```swift
@Test func methodName_condition_expectedResult() {
    // e.g., @Test func save_withValidData_succeedsAndPersists()
}
```

## Coverage Goals
- All public methods
- All error paths
- Edge cases (empty, nil, max values)
- SwiftData CRUD operations










