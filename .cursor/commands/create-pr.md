# Create Pull Request

Create a well-documented pull request for the current changes.

## Instructions

1. **Check Git Status**
   - Review staged and unstaged changes
   - Identify what's being committed

2. **Analyze Changes**
   - Read the diff to understand what changed
   - Categorize: feature, bugfix, refactor, docs, etc.

3. **Create PR Using GitHub CLI**
   ```bash
   gh pr create \
     --title "type: Brief description" \
     --body "$(cat <<EOF
   ## Summary
   Brief description of what this PR does.

   ## Changes
   - Change 1
   - Change 2
   - Change 3

   ## Type of Change
   - [ ] Bug fix (non-breaking change fixing an issue)
   - [ ] New feature (non-breaking change adding functionality)
   - [ ] Breaking change (fix or feature causing existing functionality to change)
   - [ ] Refactor (code change that neither fixes a bug nor adds a feature)
   - [ ] Documentation update

   ## Testing
   - [ ] Unit tests pass
   - [ ] UI tests pass
   - [ ] Manual testing completed

   ## Screenshots (if applicable)
   <!-- Add screenshots for UI changes -->

   ## Checklist
   - [ ] Code follows project style guidelines
   - [ ] Self-review completed
   - [ ] Comments added for complex code
   - [ ] Documentation updated (if needed)
   - [ ] No new warnings introduced
   EOF
   )"
   ```

4. **PR Title Convention**
   - `feat:` New feature
   - `fix:` Bug fix
   - `refactor:` Code refactoring
   - `docs:` Documentation
   - `test:` Tests
   - `chore:` Maintenance

## Pre-PR Checklist

### Code Quality
- [ ] Build succeeds without warnings
- [ ] All tests pass
- [ ] No SwiftLint violations (if configured)
- [ ] Code reviewed with `/code-review`

### Swift 6 Specific
- [ ] No concurrency warnings
- [ ] Actor isolation is correct
- [ ] Sendable conformance where needed

### SwiftData Specific
- [ ] Model changes are backward compatible (or migration added)
- [ ] Relationships properly configured
- [ ] No orphaned data possible

### macOS Specific
- [ ] Keyboard shortcuts don't conflict
- [ ] Menu commands work correctly
- [ ] Window behavior is appropriate

## Commit Message Format
```
type(scope): subject

body

footer
```

Example:
```
feat(models): add Project model with Task relationship

- Created Project @Model with name, description, dates
- Added one-to-many relationship with Task
- Included cascade delete rule
- Added to schema in WindowCleanerApp

Closes #123
```










