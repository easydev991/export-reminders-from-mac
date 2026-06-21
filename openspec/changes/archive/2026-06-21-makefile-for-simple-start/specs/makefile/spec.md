## ADDED Requirements

### Requirement: Project-level automation with Makefile

The project SHALL include a `Makefile` in the root directory providing automation targets for development and export workflows.

The Makefile SHALL use `.PHONY` for all targets (no file-based dependencies).

#### Scenario: Makefile exists in project root
- **WHEN** user navigates to the project root
- **THEN** a `Makefile` SHALL be present

#### Scenario: Help target
- **WHEN** user runs `make help` or `make` without arguments
- **THEN** system SHALL print available targets and their descriptions

---

### Requirement: `make export` — build, sign, and export reminders

The `make export` target SHALL build the project in release mode, sign the binary with the required entitlement, and run the export.

#### Scenario: Full export pipeline
- **WHEN** user runs `make export`
- **THEN** system SHALL execute `swift build -c release`
- **THEN** system SHALL execute `codesign --sign - --entitlements entitlements.plist .build/release/ExportReminders`
- **THEN** system SHALL execute `.build/release/ExportReminders --format json --output ./reminders.json`

#### Scenario: Custom arguments via ARGS variable
- **WHEN** user runs `make export ARGS="--format csv --output ./reminders.csv"`
- **THEN** system SHALL pass the `ARGS` value as arguments to the final binary instead of the default

#### Scenario: Build failure stops pipeline
- **WHEN** `swift build -c release` fails
- **THEN** the pipeline SHALL stop immediately with a non-zero exit code
- **THEN** subsequent steps (codesign, run) SHALL NOT execute

#### Scenario: Codesign missing binary does not crash
- **WHEN** the binary does not exist at `.build/release/ExportReminders`
- **THEN** codesign SHALL fail with a clear error message
- **THEN** the pipeline SHALL stop

---

### Requirement: `make setup` — check and install development tools

The `make setup` target SHALL check for required development tools (Homebrew, SwiftFormat, Periphery) and offer to install any missing ones via interactive y/N prompts.

Each missing tool SHALL prompt the user independently with its own y/N dialog.

#### Scenario: Homebrew not found
- **WHEN** `brew` is not available
- **THEN** system SHALL print "Homebrew not found. Install Homebrew? (y/N)"
- **WHEN** user answers "y" or "Y"
- **THEN** system SHALL install Homebrew via `/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"`
- **WHEN** user answers anything other than "y" or "Y"
- **THEN** system SHALL skip installation and proceed to the next check

#### Scenario: SwiftFormat not found via `which`
- **WHEN** `which swiftformat` fails
- **THEN** system SHALL print "SwiftFormat not found. Install via Homebrew? (y/N)"
- **WHEN** user answers "y" or "Y"
- **THEN** system SHALL run `brew install swiftformat`
- **WHEN** user answers anything other than "y" or "Y"
- **THEN** system SHALL skip installation and proceed to the next check

#### Scenario: Periphery not found via `which`
- **WHEN** `which periphery` fails
- **THEN** system SHALL print "Periphery not found. Install via Homebrew? (y/N)"
- **WHEN** user answers "y" or "Y"
- **THEN** system SHALL run `brew install periphery`
- **WHEN** user answers anything other than "y" or "Y"
- **THEN** system SHALL skip installation and proceed to the next check

#### Scenario: All tools present
- **WHEN** `brew`, `swiftformat`, and `periphery` are all available
- **THEN** system SHALL print "All tools are installed." and exit with code 0
