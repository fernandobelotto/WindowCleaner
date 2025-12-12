# Contributing to MacAppTemplate

First off, thank you for considering contributing to MacAppTemplate! 🎉

This document provides guidelines and steps for contributing. Following these guidelines helps communicate that you respect the time of the developers managing and developing this open source project.

## Table of Contents

- [Code of Conduct](#code-of-conduct)
- [Getting Started](#getting-started)
- [How Can I Contribute?](#how-can-i-contribute)
- [Development Workflow](#development-workflow)
- [Style Guidelines](#style-guidelines)
- [Commit Messages](#commit-messages)
- [Pull Request Process](#pull-request-process)

---

## Code of Conduct

This project and everyone participating in it is governed by our commitment to providing a welcoming and inclusive environment. By participating, you are expected to:

- Use welcoming and inclusive language
- Be respectful of differing viewpoints and experiences
- Gracefully accept constructive criticism
- Focus on what is best for the community
- Show empathy towards other community members

---

## Getting Started

### Prerequisites

- macOS 15.6+
- Xcode 26+
- [Homebrew](https://brew.sh) (for SwiftFormat and SwiftLint CLI)

### Setup Development Environment

1. **Fork the repository** on GitHub

2. **Clone your fork**
   ```bash
   git clone https://github.com/YOUR_USERNAME/MacAppTemplate.git
   cd MacAppTemplate
   ```

3. **Run the setup script**
   ```bash
   make setup
   ```
   This installs SwiftFormat, SwiftLint, and configures git hooks.

4. **Open in Xcode**
   ```bash
   make open
   # or
   open MacAppTemplate.xcodeproj
   ```

5. **Build and run** to verify everything works (`⌘R`)

---

## How Can I Contribute?

### 🐛 Reporting Bugs

Before creating bug reports, please check existing issues to avoid duplicates.

When creating a bug report, include:

- **Clear title** describing the issue
- **Steps to reproduce** the behavior
- **Expected behavior** vs **actual behavior**
- **Screenshots** if applicable
- **Environment details**: macOS version, Xcode version, Swift version

Use this template:

```markdown
**Describe the bug**
A clear description of what the bug is.

**To Reproduce**
1. Go to '...'
2. Click on '...'
3. See error

**Expected behavior**
What you expected to happen.

**Screenshots**
If applicable, add screenshots.

**Environment**
- macOS: [e.g., 15.6]
- Xcode: [e.g., 26.0]
- Swift: [e.g., 6.0]
```

### 💡 Suggesting Enhancements

Enhancement suggestions are welcome! Please include:

- **Clear title** describing the enhancement
- **Detailed description** of the proposed functionality
- **Use case** explaining why this would be useful
- **Possible implementation** if you have ideas

### 🔧 Pull Requests

We love pull requests! Here's how to submit one:

1. Fork the repo and create your branch from `main`
2. Make your changes
3. Ensure code passes linting and formatting
4. Write or update tests if applicable
5. Update documentation if needed
6. Submit the pull request

---

## Development Workflow

### 1. Create a Branch

```bash
# For features
git checkout -b feature/your-feature-name

# For bug fixes
git checkout -b fix/issue-description

# For documentation
git checkout -b docs/what-you-documented
```

### 2. Make Your Changes

- Write clean, readable code
- Follow the [Style Guidelines](#style-guidelines)
- Add comments for complex logic
- Update documentation as needed

### 3. Format and Lint

```bash
# Format code
make format

# Run linter
make lint

# Or run both
make all
```

### 4. Test Your Changes

```bash
# Run all tests
make test

# Build to check for compile errors
make build
```

### 5. Commit Your Changes

Follow the [Commit Message Guidelines](#commit-messages).

```bash
git add .
git commit -m "feat: add new feature description"
```

### 6. Push and Create PR

```bash
git push origin your-branch-name
```

Then open a Pull Request on GitHub.

---

## Style Guidelines

### Swift Code Style

This project uses **SwiftLint** and **SwiftFormat** to enforce consistent code style.

#### Key Conventions

- **Indentation**: 4 spaces (no tabs)
- **Line length**: 120 characters max (warning), 200 (error)
- **Imports**: Sorted alphabetically
- **Self**: Omit `self.` when not required
- **Trailing commas**: Always include in multi-line collections

#### Code Organization

Use `// MARK: -` comments to organize code:

```swift
struct MyView: View {
    // MARK: - Environment
    @Environment(\.modelContext) private var modelContext
    
    // MARK: - State
    @State private var isLoading = false
    
    // MARK: - Body
    var body: some View {
        // ...
    }
    
    // MARK: - Actions
    private func performAction() {
        // ...
    }
}
```

#### Naming Conventions

- **Types**: `PascalCase` (e.g., `ItemDetailView`, `DataService`)
- **Functions/Variables**: `camelCase` (e.g., `fetchItems()`, `selectedItem`)
- **Constants**: `camelCase` in enums (e.g., `Metrics.spacing`)

#### SwiftUI Views

- Include `#Preview` for all views
- Use `@ViewBuilder` for conditional content
- Extract complex views into separate components

#### SwiftData Models

- Use `@Model` macro
- Include documentation comments
- Provide sample data for previews

### Documentation

- Use Swift documentation comments (`///`) for public APIs
- Keep README and other docs up to date
- Include code examples where helpful

---

## Commit Messages

We follow [Conventional Commits](https://www.conventionalcommits.org/) for clear, consistent commit history.

### Format

```
<type>(<scope>): <description>

[optional body]

[optional footer]
```

### Types

| Type | Description |
|:-----|:------------|
| `feat` | New feature |
| `fix` | Bug fix |
| `docs` | Documentation only |
| `style` | Formatting, no code change |
| `refactor` | Code change that neither fixes a bug nor adds a feature |
| `perf` | Performance improvement |
| `test` | Adding or updating tests |
| `chore` | Maintenance tasks |

### Examples

```bash
# Feature
git commit -m "feat(views): add dark mode support to SettingsView"

# Bug fix
git commit -m "fix(data): resolve crash when deleting last item"

# Documentation
git commit -m "docs: update README with new setup instructions"

# Refactor
git commit -m "refactor(models): extract validation logic to separate service"
```

---

## Pull Request Process

### Before Submitting

- [ ] Code compiles without errors
- [ ] All tests pass (`make test`)
- [ ] Code is formatted (`make format`)
- [ ] Linter passes (`make lint`)
- [ ] Documentation is updated (if applicable)
- [ ] Commit messages follow conventions

### PR Title

Use the same format as commit messages:

```
feat(scope): description of the change
```

### PR Description

Include:

1. **What** does this PR do?
2. **Why** is this change needed?
3. **How** was it implemented?
4. **Screenshots** (for UI changes)
5. **Testing** done

### Review Process

1. A maintainer will review your PR
2. Address any requested changes
3. Once approved, a maintainer will merge the PR

### After Merge

- Delete your feature branch
- Pull the latest `main` to your local repo
- Celebrate! 🎉

---

## Questions?

If you have questions, feel free to:

- Open a [GitHub Issue](https://github.com/fernandobelotto/MacAppTemplate/issues)
- Start a [Discussion](https://github.com/fernandobelotto/MacAppTemplate/discussions)

Thank you for contributing! ❤️









