---
name: swiftui-pro
description: Review SwiftUI changes for correctness, API usage, accessibility, and performance. Use for a requested review or a focused review needed by the task.
license: MIT
metadata:
  author: Paul Hudson
  version: "1.1"
---

# Focused SwiftUI review

Review the files or behavior in scope and report concrete problems with evidence. Keep the project’s deployment target, Swift version, architecture, and dependency policy. A review does not authorize unrelated migrations or new frameworks.

Select only the relevant checks:

| Review concern | Reference |
|---|---|
| API availability and deprecations | [api](references/api.md) |
| View identity, composition, animation | [views](references/views.md) |
| State ownership and updates | [data](references/data.md) |
| Navigation and presentation | [navigation](references/navigation.md) |
| Native design and accessibility | [design](references/design.md), [accessibility](references/accessibility.md) |
| Rendering or computation cost | [performance](references/performance.md) |
| Swift correctness or maintainability | [swift](references/swift.md), [hygiene](references/hygiene.md) |

Explain each actionable finding with its file, line, observable consequence, and a proportional fix. Distinguish a proven bug from a style preference or an optimization that still needs measurement. Use the primary `swiftui-expert-skill` for implementation/refactoring topics when its deeper references are needed.
