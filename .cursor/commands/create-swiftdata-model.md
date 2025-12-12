# Create SwiftData Model

Generate a new SwiftData model with proper configuration and relationships.

## User Input
Describe the model you need (name, properties, relationships).

## Template

```swift
import Foundation
import SwiftData

@Model
final class ModelName {
    // MARK: - Properties
    var id: UUID = UUID()
    var createdAt: Date = Date()
    var updatedAt: Date = Date()
    
    // Add your properties here
    var name: String
    
    // MARK: - Relationships
    // @Relationship(deleteRule: .cascade, inverse: \OtherModel.parent)
    // var children: [OtherModel]
    
    // MARK: - Initialization
    init(name: String) {
        self.name = name
    }
}
```

## Instructions

1. **Create the Model File**
   - Location: `WindowCleaner/Models/[ModelName].swift`
   - Use `@Model` macro
   - Make class `final`

2. **Add Properties**
   - Use appropriate types (String, Int, Date, Data, etc.)
   - Provide default values where sensible
   - Consider optionality carefully

3. **Configure Relationships**
   - Use `@Relationship` for to-many relationships
   - Specify `deleteRule`: `.cascade`, `.nullify`, `.deny`, `.noAction`
   - Set `inverse` for bidirectional relationships

4. **Update Schema**
   - Add model to `WindowCleanerApp.swift` schema:
   ```swift
   let schema = Schema([
       Item.self,
       NewModel.self,  // Add here
   ])
   ```

5. **Create Query Extension** (optional)
   ```swift
   extension ModelName {
       static var sortedByDate: FetchDescriptor<ModelName> {
           var descriptor = FetchDescriptor<ModelName>(sortBy: [SortDescriptor(\.createdAt, order: .reverse)])
           return descriptor
       }
   }
   ```

## SwiftData Best Practices
- Use value types for simple properties
- Avoid computed properties in @Model (use extensions instead)
- Use `@Attribute(.unique)` for unique constraints
- Use `@Attribute(.externalStorage)` for large data (images, files)










