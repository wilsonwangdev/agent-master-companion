---
name: Swift Conventions
type: rule
severity: medium
verified: 2026-04-24
trigger: writing or modifying Swift code
---

# Swift Conventions

## Rule

This is a living document. Agent should update this rule as conventions are established during development.

### General

- Follow Swift API Design Guidelines
- Use Swift's type system to prevent invalid states (prefer enums over string constants)
- Use `Codable` for all serialization
- Prefer value types (struct) over reference types (class) unless identity semantics are needed

### SwiftUI

- Keep views small and composable
- Extract reusable components into separate files
- Use `@State` for view-local state, `@StateObject` for owned observable objects
- Use `@EnvironmentObject` for dependency injection of shared services

### Error Handling

- Use Swift's `Result` type or `throws` for recoverable errors
- Never force-unwrap (`!`) outside of tests or IBOutlet patterns
- Provide meaningful error messages that help the developer debug

### File Organization

- One primary type per file, named after the type
- Group related files in directories matching the project structure in CLAUDE.md
