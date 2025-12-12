# Lint & Format Check

Check and fix all linting and formatting issues in the codebase.

## Context
- **Formatter**: SwiftFormat (via Homebrew CLI)
- **Linter**: SwiftLint (via Homebrew CLI)
- **Makefile Targets**: `format`, `lint`, `lint-fix`

## Instructions

1. **Check Lint Issues**
   - Run `make lint` to identify SwiftLint violations
   - Review any warnings or errors

2. **Auto-fix Lint Violations**
   - Run `make lint-fix` to auto-correct fixable violations
   - Re-run `make lint` to verify remaining issues

3. **Fix Remaining Issues Manually**
   - For issues that can't be auto-fixed, read the affected files
   - Apply manual fixes following SwiftLint rules
   - Common issues:
     - Line length violations (max 140 chars)
     - Force unwrapping
     - Missing documentation
     - Unused variables/parameters

4. **Format Code**
   - Run `make format` to apply SwiftFormat to all Swift files
   - This auto-fixes formatting issues (indentation, spacing, etc.)

5. **Final Verification**
   - Run `make lint` to confirm all issues are resolved
   - If new issues appear, repeat steps 3-5

## Quick Commands

```bash
# Check for lint issues
make lint

# Auto-fix lint violations
make lint-fix

# Format all Swift files
make format

# Full workflow (lint-fix → format → final lint check)
make lint-fix && make format && make lint

# After manual fixes, format and verify:
make format && make lint
```

## Common SwiftLint Rules

| Rule | Fix |
|------|-----|
| `line_length` | Break long lines, extract variables |
| `force_unwrapping` | Use `if let`, `guard let`, or `??` |
| `trailing_whitespace` | Remove trailing spaces (auto-fixed) |
| `vertical_whitespace` | Keep max 1 blank line (auto-fixed) |
| `opening_brace` | Brace on same line as declaration |
| `colon` | No space before, one space after |

## SwiftFormat vs SwiftLint

- **SwiftLint**: Code quality & style enforcement (naming, patterns, safety)
- **SwiftFormat**: Code formatting (whitespace, braces, imports)

Lint first to catch code quality issues, then format to clean up styling. Always format after manual fixes to ensure consistent code style.

