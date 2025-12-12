# Run Tests & Fix Failures

Run all unit tests and UI tests, then fix any failures.

## Context
- Unit Tests: Swift Testing framework (@Test macro)
- UI Tests: XCUITest
- Project: `WindowCleaner.xcodeproj`
- Scheme: `WindowCleaner`

## Instructions

1. **Run Unit Tests**
   - Use `test_macos` tool with:
     - `projectPath`: `WindowCleaner.xcodeproj`
     - `scheme`: `WindowCleaner`

2. **Analyze Results**
   - Check for failed tests
   - Parse test output for assertion failures
   - Identify flaky tests vs. real failures

3. **Fix Failures**
   - For each failing test:
     - Read the test file to understand what's being tested
     - Identify the root cause (implementation bug vs. test bug)
     - Fix the appropriate code
     - Re-run to verify

4. **Common Swift Testing Patterns**
   ```swift
   @Test func exampleTest() async throws {
       #expect(result == expected)
       #expect(throws: SomeError.self) { try riskyOperation() }
   }
   ```

## Test Categories
- **Unit Tests**: `WindowCleanerTests/` - Test models, view models, business logic
- **UI Tests**: `WindowCleanerUITests/` - Test user interactions, navigation

## SwiftData Testing Tips
- Use in-memory ModelContainer for tests: `ModelContainer(for: Item.self, configurations: ModelConfiguration(isStoredInMemoryOnly: true))`
- Reset state between tests
- Test model relationships and queries










