# План: Export Reminders — Swift CLI + EventKit (TDD)

## 1. Цель

Swift command-line инструмент для выгрузки всех напоминаний из Apple Reminders (iCloud) на macOS в JSON.

**Почему Swift, а не AppleScript/JXA**: 1 000+ напоминаний через IPC к приложению «Напоминания» обрабатываются минутами. Swift + EventKit напрямую читает базу данных Reminders через нативный фреймворк без межпроцессных вызовов — вся выгрузка за **1–2 секунды**.

---

## 2. Структура проекта (SPM)

```
export-reminders/
├── Package.swift
├── Sources/
│   └── ExportReminders/
│       ├── ExportReminders.swift               # точка входа (CLI)
│       ├── Models/
│       │   ├── ReminderItem.swift
│       │   └── ReminderList.swift
│       ├── Services/
│       │   ├── ReminderServiceProtocol.swift
│       │   ├── EventKitReminderService.swift
│       │   └── EventKitReminderServiceError.swift
│       └── Exporters/
│           ├── ReminderExporterProtocol.swift
│           ├── JSONExporter.swift
│           ├── CSVExporter.swift
│           └── MarkdownExporter.swift
├── Tests/
│   └── ExportRemindersTests/
│       ├── ReminderItemTests.swift
│       ├── ReminderListTests.swift
│       ├── EventKitReminderServiceTests.swift
│       ├── JSONExporterTests.swift
│       ├── CSVExporterTests.swift
│       └── MarkdownExporterTests.swift
├── scripts/
│   ├── export-reminders.js                     # JXA fallback
│   └── export-reminders.applescript            # AppleScript fallback
├── PLAN.md
└── .gitignore
```

---

## 3. Этапы реализации (TDD: Red → Green → Refactor)

### Этап 1: Модели данных (Domain Layer)

**Red**: Написать тесты для моделей.
- `ReminderItem` — Equatable, Codable (JSON encode/decode)
- `ReminderList` — название, цвет, id
- Проверить инициализацию со всеми полями, включая опциональные

**Green**: Реализовать модели.
```swift
struct ReminderItem: Codable, Equatable {
    let id: String
    let listName: String
    let title: String
    let notes: String?
    let dueDate: Date?
    let completionDate: Date?
    let creationDate: Date?
    let modificationDate: Date?
    let priority: Int
    let isCompleted: Bool
    let recurrenceRule: String?
    let url: String?
}
```

**Refactor**: Убедиться, что поля опциональны там, где нужно.

---

### Этап 2: Data Layer — Service

**Red**: Написать тесты с мок-сервисом, реализующим `ReminderServiceProtocol`:
- `fetchAllReminders() async throws -> [ReminderItem]`
- `fetchAllLists() async throws -> [ReminderList]`
- mock отдаёт предопределённый набор напоминаний

**Green**: Реализовать `EventKitReminderService`:
- Запрос доступа через `EKEventStore.requestAccess(to: .reminder)`
- Загрузка календарей: `store.calendars(for: .reminder)`
- Загрузка напоминаний: `store.fetchReminders(matching:)`
- Маппинг `EKReminder` → `ReminderItem`
- Маппинг `EKCalendar` → `ReminderList`

**Refactor**: Добавить обработку ошибок (доступ запрещён, пустые списки, iCloud-ошибки).

---

### Этап 3: Output-модули (Exporters)

**Red**: Тесты для каждого экспортёра:
- **JSONExporter**: проверить, что на выходе валидный JSON с корректными полями
- **CSVExporter**: проверить заголовки, экранирование кавычек и запятых
- **MarkdownExporter**: проверить группировку по спискам, форматирование

**Green**: Реализовать три экспортёра через общий протокол:
```swift
protocol ReminderExporter {
    func export(_ reminders: [ReminderItem], to url: URL) throws
}
```

**Refactor**: Вынести общую логику (сортировка, фильтрация, группировка).

---

### Этап 4: CLI (Command-Line Interface)

**Зависимости**: `swift-argument-parser`

**Red**: Написать интеграционные тесты, проверяющие парсинг аргументов:
- `--format` (json | csv | md)
- `--output` (URL)
- `--list` (фильтр по имени списка, опционально, multiple)
- `--completed` (true | false — фильтр по статусу)

**Green**: Реализовать `ExportRemindersCLI`:
```swift
@main
struct ExportRemindersCLI: ParsableCommand {
    @Option var format: Format = .json
    @Option var output: String = "./reminders_export.json"
    @Option var list: [String] = []
    @Option var completed: Bool? = nil

    func run() throws {
        // 1. Service → fetch
        // 2. Exporter → export
        // 3. Print result
    }
}
```

**Refactor**: Обработка ошибок, понятные сообщения, сигнатура выхода.

---

### Этап 5: Сборка, подпись и запуск

- Настроить entitlements: `com.apple.security.personal-information.reminders`
- Собрать через `swift build -c release`
- Подписать ad-hoc: `codesign --sign - --entitlements`
- Запустить и проверить TCC-диалог

Если TCC-диалог не появится для CLI-бинарника:
- Собрать как минимальное приложение с `LSUIElement=true`
- Или использовать `tccutil` для ручного добавления разрешения

---

## 4. Поля для экспорта

| Поле | Тип | Источник |
|---|---|---|
| `id` | String | EKReminder.calendarItemIdentifier |
| `listName` | String | EKCalendar.title |
| `title` | String | EKReminder.title |
| `notes` | String? | EKReminder.notes |
| `dueDate` | Date? | EKReminder.dueDateComponents |
| `completionDate` | Date? | EKReminder.completionDate |
| `creationDate` | Date? | EKReminder.creationDate |
| `modificationDate` | Date? | EKReminder.lastModifiedDate |
| `priority` | Int | EKReminder.priority (0..9) |
| `isCompleted` | Bool | EKReminder.isCompleted |
| `recurrenceRule` | String? | EKRecurrenceRule → description |
| `url` | String? | EKReminder.url |

---

## 5. Зависимости

```swift
// Package.swift
dependencies: [
    .package(url: "https://github.com/apple/swift-argument-parser", from: "1.2.0"),
]
```

Внешние: `EventKit.framework` (macOS SDK, без дополнительных зависимостей).

---

## 6. Критерии завершения

- [ ] `swift test` — все unit-тесты проходят
- [ ] `swift run export-reminders --format json` выгружает все напоминания в JSON
- [ ] `swift run export-reminders --format csv --output ./out.csv` выгружает в CSV
- [ ] `swift run export-reminders --format md --output ./out.md` выгружает в Markdown
- [ ] `swift run export-reminders --list "Покупки" --completed false` — фильтрация работает
- [ ] Выгрузка 1 000+ напоминаний занимает < 5 секунд
- [ ] README с инструкцией по сборке и настройке TCC

---

## 7. Что остаётся от AppleScript/JXA

В `scripts/` остаются как fallback для тех, у кого мало напоминаний и нет желания собирать бинарник:
- `export-reminders.js` — JXA-скрипт
- `export-reminders.applescript` — AppleScript-скрипт

---
