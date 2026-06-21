## MODIFIED Requirements

### Requirement: Аргумент --format

Аргумент `--format` SHALL принимать одно из трёх значений: `json`, `csv`, `tasks-org`. Значение по умолчанию SHALL быть `json`. SHALL быть определён enum `Format: String, ExpressibleByArgument` со значениями `json`, `csv`, `tasksOrg`.

#### Scenario: Указан формат json

- **WHEN** команда вызвана с `--format json`
- **THEN** используется `JSONExporter`

#### Scenario: Указан формат csv

- **WHEN** команда вызвана с `--format csv`
- **THEN** используется `CSVExporter`

#### Scenario: Указан формат tasks-org

- **WHEN** команда вызвана с `--format tasks-org`
- **THEN** напоминания конвертируются через `TasksOrgConverter.convert(_:)`
- **THEN** результат записывается в файл
- **THEN** дефолтное имя файла — `reminders_export_tasks_org.json`

#### Scenario: Неверный формат

- **WHEN** команда вызвана с `--format xml`
- **THEN** выводится сообщение об ошибке и `--help`

### Requirement: CLI точка входа

Приложение SHALL использовать `@main` entry point с `AsyncParsableCommand` (требуется для асинхронного `run()`). Имя команды SHALL быть `export-reminders`.

#### Scenario: Запуск без аргументов

- **WHEN** команда вызывается без аргументов
- **THEN** используется формат `json` и файл `./reminders_export.json`
