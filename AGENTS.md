# AGENTS.md — Export Reminders

## Build & Test

```bash
swift build                  # debug
swift build -c release       # release
swift test                   # all tests (Swift Testing, not XCTest)
swift test --filter TestSuiteName   # single suite
swift run export-reminders --format json
```

## Formatting

```bash
swiftformat .
```
SwiftFormat 0.61+ installed via Homebrew at `/opt/homebrew/bin/swiftformat`.
Run **before every commit** — no exceptions.

## Project Structure

- **SPM executable** — single target `ExportReminders`, test target `ExportRemindersTests`
- **No .xcodeproj** — SPM-only. Run `swift build`/`swift test` from repo root
- `Sources/ExportReminders/Models/`, `Services/`, `Exporters/` + `ExportReminders.swift` (entrypoint)
- `Tests/ExportRemindersTests/` mirrors source structure
- `scripts/` — JXA/AppleScript fallbacks. **Do not delete.**
- `PLAN.md` — source of truth for architecture and field mapping
- `openspec/changes/export-reminders/` — spec-driven artifacts (proposal → design → specs → tasks)

## Testing Rules (critical)

- `import Testing` — **never** `import XCTest`
- Every test: `@Test("русское описание")`
- Assertions: `#expect(condition)`, `try #require(optional)` — never `== true`/`== false`
- TDD cycle: Red (write failing test) → Green (minimal impl) → Refactor
- Mock via protocols: `ReminderServiceProtocol`, `ReminderExporterProtocol`
- Shared fixtures in `Tests/ExportRemindersTests/Fixtures/`

## Dependencies

- `swift-argument-parser` (from: "1.2.0") — only external package
- `EventKit.framework` — system, linked in Package.swift
- macOS 14+ target only

## Formats

| Format | Role |
|--------|------|
| JSON   | Canonical — full data preservation, ISO 8601 dates, `encodeIfPresent` for nil fields |
| CSV    | Universal table — English column names, comma-quote escaping, ISO 8601 dates |

**NOT included**: Markdown (human-readable only, not for import), ICS (VTODO unsupported by Android apps).

## Security

Entitlement required: `com.apple.security.personal-information.reminders`
After `swift build -c release`:
```bash
codesign --sign - --entitlements entitlements.plist .build/release/export-reminders
```

## Language

- Documentation, plan, test descriptions: **Russian**
- Code identifiers (types, functions, variables): **English**
