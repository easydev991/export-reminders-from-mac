## 1. Модели Tasks.org

- [ ] 1.1 Создать `Models/TasksOrg/` с `TasksOrgTask.swift` — структура задачи Tasks.org (Codable): `title`, `importance`, `dueDate`, `created`, `modified`, `completed`, `notes`, `recurrence: String?` (iCalendar RRULE, не структура), `remoteId`, `caldavTasks`, поля-заглушки (`hideUntil`, `estimatedSeconds`, `elapsedSeconds`, `timerStart`, `ringFlags`, `repeatFrom`, `calendarURI`, `parent`, `order`, `readOnly`, `deleted`). Ключи Codable: точные имена полей Tasks.org (JSON snake_case, совпадают с Kotlin-свойствами)
- [ ] 1.2 Создать `CaldavModels.swift` — `CaldavAccount` (uuid, name, accountType: Int, url), `CaldavCalendar` (uuid, name, color: Int, account), `CaldavTask` (calendar, remoteId, obj: String?, deleted: Int64). Ключи Codable: `uuid` не `id`, `account` не `accountName`, `calendar` не `calendarId`, `@SerialName("object")` для `obj`
- [ ] 1.3 Создать `TasksOrgContainer.swift` — корневая обёртка `TasksOrgBackup` (version, timestamp, data: TasksOrgData) и `TasksOrgData` со всеми секциями (tasks, caldavAccounts, caldavCalendars, places, tags, filters, taskListMetadata, taskAttachments, intPrefs, longPrefs, stringPrefs, boolPrefs, setPrefs)
- [ ] 1.4 Создать `TasksOrgTaskWrapper.swift` — обёртка `{"task": TasksOrgTask}` для формата `data.tasks`

## 2. Тесты конвертера (TDD: RED)

- [ ] 2.1 Создать `Tests/ExportRemindersTests/Converters/TasksOrgConverterTests.swift` с заглушкой тестового класса
- [ ] 2.2 Тест: пустой массив напоминаний → полный конверт с `data.tasks = []`, всеми пустыми секциями, `version = 157`, `timestamp > 0`
- [ ] 2.3 Тест: одно напоминание со всеми полями → проверка прямого маппинга (`title`, `recurrenceRule→recurrence`, `id→remoteId`)
- [ ] 2.4 Тест: конвертация дат — ISO 8601 строки в Unix-ms числа (`dueDate`, `creationDate`, `modificationDate`), nil-даты → 0
- [ ] 2.5 Тест: маппинг приоритета — 1→0 (HIGH), 5→1 (MED), 9→2 (LOW), 0→3 (NONE)
- [ ] 2.6a Тест: `isCompleted == false` → `completed == 0`
- [ ] 2.6b Тест: `isCompleted == true` + `completionDate != nil` → `completed = completionDate` в Unix ms
- [ ] 2.6c Тест: `isCompleted == true` + `completionDate == nil` + `modificationDate != nil` → `completed = modificationDate` в Unix ms
- [ ] 2.6d Тест: `isCompleted == true` + обе даты `nil` → `completed` = текущий Unix timestamp (проверка `> 0`)
- [ ] 2.7 Тест: два напоминания из разных списков → два `CaldavCalendar`, один `CaldavAccount`, ссылки в `caldavTasks`
- [ ] 2.8 Тест: `url` добавляется в `notes` (есть notes → `"\n\nURL: ..."`, нет notes → `"URL: ..."`, нет url → notes без изменений)
- [ ] 2.9 Тест: несколько напоминаний из одного списка → один календарь
- [ ] 2.10 Тест: напоминание с промежуточным приоритетом (например, 6) → fallback на NONE (3)

## 3. Реализация конвертера (TDD: GREEN)

- [ ] 3.1 Создать `Sources/ExportReminders/Converters/TasksOrgConverter.swift` со структурой и методом `convert(_:) throws -> Data`
- [ ] 3.2 Реализовать вспомогательную функцию `dateToUnixMs(_ date: Date?) -> Int64`
- [ ] 3.3 Реализовать функцию маппинга приоритета `mapPriority(_ priority: Int) -> Int`
- [ ] 3.4 Реализовать функцию `completionDateFrom(_ item: ReminderItem) -> Int64` — каскад: `completionDate` → `modificationDate` → текущий timestamp
- [ ] 3.5 Реализовать конвертацию одного `ReminderItem` → `TasksOrgTask` (прямой маппинг + url в notes + priority + completed через каскад)
- [ ] 3.6 Реализовать построение Caldav-календарей и аккаунта по `listName` (группировка уникальных имён)
- [ ] 3.7 Реализовать генерацию UUID для календарей и аккаунта (SHA-256 от `listName` → первые 16 байт → UUID формат; `CaldavTask.remoteId` — случайный UUID на каждую задачу)
- [ ] 3.8 Реализовать сборку полного конверта `TasksOrgBackup` с текущим timestamp и всеми пустыми секциями
- [ ] 3.9 Сериализация через `JSONEncoder` (без dateEncodingStrategy — даты уже числа, `outputFormatting: [.prettyPrinted, .withoutEscapingSlashes]`)

## 4. CLI-интеграция

- [ ] 4.1 Добавить `case tasksOrg = "tasks-org"` в enum `Format` (`Format.swift`)
- [ ] 4.2 Добавить `case .tasksOrg` в `makeExporter(for:)` в `ExportReminders.swift` — создать тонкую обёртку (структуру-адаптер), реализующую `ReminderExporterProtocol`, которая внутри вызывает `TasksOrgConverter.convert(_:)` и пишет результат в файл
- [ ] 4.3 Обновить дефолтное имя файла для `--format tasks-org` → `reminders_export_tasks_org.json`

## 5. Качество

- [ ] 5.1 Запустить `swiftformat .` — проверить форматирование
- [ ] 5.2 Запустить `periphery scan --targets ExportReminders` — проверить отсутствие мёртвого кода
- [ ] 5.3 Запустить `swift test` — все тесты проходят
- [ ] 5.4 Запустить `swift test --filter TasksOrgConverter` — только тесты конвертера
