# Code Review - SwiftUI/SwiftData

Perform a comprehensive code review focused on SwiftUI, SwiftData, and Swift 6 best practices.

## Review Checklist

### Swift 6 Concurrency
- [ ] Correct actor isolation (`@MainActor`, `nonisolated`)
- [ ] Proper async/await usage
- [ ] No data races (Sendable conformance)
- [ ] Task cancellation handling
- [ ] No blocking operations on main actor

### SwiftUI Best Practices
- [ ] Views are lightweight (heavy logic in view models/services)
- [ ] Proper use of `@State`, `@Binding`, `@Environment`
- [ ] No expensive computations in view body
- [ ] Correct use of `@Observable` vs `@ObservableObject`
- [ ] Previews provided and working
- [ ] Accessibility labels where needed
- [ ] Animations are smooth and intentional

### SwiftData
- [ ] `@Model` classes are `final`
- [ ] Relationships properly configured with delete rules
- [ ] Appropriate use of `@Query` with sort descriptors
- [ ] ModelContext operations in correct actor context
- [ ] No retain cycles with relationships

### macOS Specifics
- [ ] Proper window management
- [ ] Keyboard shortcuts follow HIG
- [ ] Menu commands implemented correctly
- [ ] Touch Bar support (if applicable)
- [ ] Drag and drop where expected

### Code Quality
- [ ] Single responsibility per file
- [ ] Clear naming conventions
- [ ] Error handling is user-friendly
- [ ] Logging uses os.Logger appropriately
- [ ] No force unwraps without justification
- [ ] No magic numbers/strings

## Instructions

1. **Read the Changed Files**
   - Focus on the files mentioned or recently modified
   - Understand the context and purpose

2. **Check Against Checklist**
   - Go through each applicable item
   - Note any violations or concerns

3. **Provide Feedback**
   - Group by severity: Critical, Warning, Suggestion
   - Include code examples for fixes
   - Explain the "why" behind each point

4. **Suggest Improvements**
   - Performance optimizations
   - Code organization
   - Better patterns

## Common Issues to Watch For

```swift
// ❌ Bad: Heavy computation in body
var body: some View {
    let processed = items.map { expensiveOperation($0) } // Runs on every render
    List(processed) { ... }
}

// ✅ Good: Use computed property or cache
var processedItems: [ProcessedItem] {
    items.map { expensiveOperation($0) }
}

// ❌ Bad: Missing actor isolation
func updateData() async {
    modelContext.insert(newItem) // May not be on main actor
}

// ✅ Good: Explicit main actor
@MainActor
func updateData() async {
    modelContext.insert(newItem)
}
```










