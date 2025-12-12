# Add New Feature

Complete workflow for implementing a new feature in the macOS app.

## User Input
Describe the feature you want to add.

## Feature Implementation Workflow

### Phase 1: Planning
1. **Understand Requirements**
   - What does the feature do?
   - What data does it need?
   - How does user interact with it?
   - What existing code does it affect?

2. **Design Data Model**
   - New SwiftData models needed?
   - Changes to existing models?
   - Relationships required?

3. **Design UI**
   - What views are needed?
   - Where does it fit in navigation?
   - What user actions are required?

### Phase 2: Implementation

1. **Create/Update Models**
   - Location: `WindowCleaner/Models/`
   - Add to schema in `WindowCleanerApp.swift`
   - Consider migration if modifying existing models

2. **Create Views**
   - Location: `WindowCleaner/Views/`
   - Follow existing patterns (NavigationSplitView, etc.)
   - Include previews

3. **Add Navigation/Integration**
   - Update `ContentView.swift` if needed
   - Add menu commands if applicable
   - Add toolbar items if needed

4. **Handle Errors**
   - User-friendly error messages
   - Logging with os.Logger
   - Graceful fallbacks

### Phase 3: Testing

1. **Write Unit Tests**
   - Location: `WindowCleanerTests/`
   - Test model logic
   - Test business rules

2. **Write UI Tests** (if applicable)
   - Location: `WindowCleanerUITests/`
   - Test user workflows

3. **Manual Testing**
   - Build and run the app
   - Test all user paths
   - Check edge cases

### Phase 4: Polish

1. **Review Code Quality**
   - Run `/code-review`
   - Fix any issues

2. **Documentation**
   - Add code comments for complex logic
   - Update README if needed

## File Structure Template
```
WindowCleaner/
├── Models/
│   └── NewFeatureModel.swift
├── Views/
│   ├── Screens/
│   │   └── NewFeatureView.swift
│   └── Components/
│       └── NewFeatureRow.swift
├── Services/
│   └── NewFeatureService.swift
└── Utilities/
    └── NewFeatureHelpers.swift
```

## Checklist
- [ ] Models created and added to schema
- [ ] Views created with previews
- [ ] Navigation integrated
- [ ] Error handling implemented
- [ ] Unit tests written
- [ ] UI tests written (if applicable)
- [ ] Code reviewed
- [ ] All tests passing










