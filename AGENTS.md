# AGENTS.md — Export Reminders

## Key facts

- **SPM-only** — no `.xcodeproj`. Build/test from repo root.
- **macOS 14+**, `EventKit.framework` linked in Package.swift.
- **Single executable target** `ExportReminders`, single test target `ExportRemindersTests`.
- **`swift test --filter SuiteName`** — filters by test suite, not individual test name.

## Quality checks (before every commit)

```bash
swiftformat .        # formatting (SwiftFormat 0.61+, /opt/homebrew/bin/swiftformat)
periphery scan --targets ExportReminders   # detect dead code
```
Fix all warnings before committing — no exceptions.

## Structure

- `Sources/ExportReminders/Models/`, `Services/`, `Exporters/` + `ExportReminders.swift` (entrypoint)
- `Tests/ExportRemindersTests/` mirrors source structure
- `scripts/` — JXA/AppleScript fallbacks. **Do not delete.**
- `README.md` — архитектура, поля модели, примеры использования
- `openspec/specs/` — main specifications (domain-models, eventkit-integration, json-export, csv-export, cli-interface)
- `openspec/changes/archive/` — archived changes (spec-driven)

## Testing (Swift Testing only)

- `import Testing` — **never** `import XCTest`
- Every test: `@Test("русское описание")`
- Assertions: `#expect(condition)`, `try #require(optional)`
- Never write `== true` / `== false` in assertions
- Mock via protocols: `ReminderServiceProtocol`, `ReminderExporterProtocol`
- Shared fixtures: `Tests/ExportRemindersTests/Fixtures/`

## Language

- Documentation, plan, test descriptions: **Russian**
- Code identifiers (types, functions, variables): **English**
