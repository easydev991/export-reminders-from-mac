## 1. Модели Tasks.org

- [x] 1.1 Создать `Models/TasksOrg/` с `TasksOrgTask.swift` — структура задачи Tasks.org (Codable): `title`, `importance`, `dueDate`, `created`, `modified`, `completed`, `notes`, `recurrence: String?` (iCalendar RRULE, не структура), `remoteId`, `caldavTasks`, поля-заглушки (`hideUntil`, `estimatedSeconds`, `elapsedSeconds`, `timerStart`, `ringFlags`, `repeatFrom`, `calendarURI`, `parent`, `order`, `readOnly`, `deleted`). Ключи Codable: точные имена полей Tasks.org (JSON snake_case, совпадают с Kotlin-свойствами)
- [x] 1.2 Создать `CaldavModels.swift` — `CaldavAccount` (uuid, name, accountType: Int, url), `CaldavCalendar` (uuid, name, color: Int, account), `CaldavTask` (calendar, remoteId, obj: String?, deleted: Int64). Ключи Codable: `uuid` не `id`, `account` не `accountName`, `calendar` не `calendarId`, `@SerialName("object")` для `obj`
- [x] 1.3 Создать `TasksOrgContainer.swift` — корневая обёртка `TasksOrgBackup` (version, timestamp, data: TasksOrgData) и `TasksOrgData` со всеми секциями (tasks, caldavAccounts, caldavCalendars, places, tags, filters, taskListMetadata, taskAttachments, intPrefs, longPrefs, stringPrefs, boolPrefs, setPrefs)
- [x] 1.4 Кодировать `data.tasks` как `[{"task": TasksOrgTask}]` inline, без отдельного файла-обёртки

## 2. Тесты конвертера (TDD: RED)

- [x] 2.1 Создать `Tests/ExportRemindersTests/Converters/TasksOrgConverterTests.swift` с заглушкой тестового класса
- [x] 2.2 Тест: пустой массив напоминаний → полный конверт с `data.tasks = []`, всеми пустыми секциями, `version = 157`, `timestamp > 0`
- [x] 2.3 Тест: одно напоминание со всеми полями → проверка прямого маппинга (`title`, `recurrenceRule→recurrence`, `id→remoteId`)
- [x] 2.4 Тест: конвертация дат — ISO 8601 строки в Unix-ms числа (`dueDate`, `creationDate`, `modificationDate`), nil-даты → 0
- [x] 2.5 Тест: маппинг приоритета — 1→0 (HIGH), 5→1 (MED), 9→2 (LOW), 0→3 (NONE)
- [x] 2.6a Тест: `isCompleted == false` → `completed == 0`
- [x] 2.6b Тест: `isCompleted == true` + `completionDate != nil` → `completed = completionDate` в Unix ms
- [x] 2.6c Тест: `isCompleted == true` + `completionDate == nil` + `modificationDate != nil` → `completed = modificationDate` в Unix ms
- [x] 2.6d Тест: `isCompleted == true` + обе даты `nil` → `completed` = текущий Unix timestamp (проверка `> 0`)
- [x] 2.7 Тест: два напоминания из разных списков → два `CaldavCalendar`, один `CaldavAccount`, ссылки в `caldavTasks`
- [x] 2.8 Тест: `url` добавляется в `notes` (есть notes → `"\n\nURL: ..."`, нет notes → `"URL: ..."`, нет url → notes без изменений)
- [x] 2.9 Тест: несколько напоминаний из одного списка → один календарь
- [x] 2.10 Тест: напоминание с промежуточным приоритетом (например, 6) → fallback на NONE (3)

## 3. Реализация конвертера (TDD: GREEN)

- [x] 3.1 Создать `Sources/ExportReminders/Converters/TasksOrgConverter.swift` со структурой и методом `convert(_:) throws -> Data`
- [x] 3.2 Реализовать вспомогательную функцию `dateToUnixMs(_ date: Date?) -> Int64`
- [x] 3.3 Реализовать функцию маппинга приоритета `mapPriority(_ priority: Int) -> Int`
- [x] 3.4 Реализовать функцию `completionDateFrom(_ item: ReminderItem) -> Int64` — каскад: `completionDate` → `modificationDate` → текущий timestamp
- [x] 3.5 Реализовать конвертацию одного `ReminderItem` → `TasksOrgTask` (прямой маппинг + url в notes + priority + completed через каскад)
- [x] 3.6 Реализовать построение Caldav-календарей и аккаунта по `listName` (группировка уникальных имён)
- [x] 3.7 Реализовать генерацию UUID для календарей и аккаунта (SHA-256 от `listName` → первые 16 байт → UUID формат; `CaldavTask.remoteId` — случайный UUID на каждую задачу)
- [x] 3.8 Реализовать сборку полного конверта `TasksOrgBackup` с текущим timestamp и всеми пустыми секциями
- [x] 3.9 Сериализация через `JSONEncoder` (без dateEncodingStrategy — даты уже числа, `outputFormatting: [.prettyPrinted, .withoutEscapingSlashes]`)

## 4. CLI-интеграция

- [x] 4.1 Добавить `case tasksOrg = "tasks-org"` в enum `Format` (`Format.swift`)
- [x] 4.2 Добавить `case .tasksOrg` в `makeExporter(for:)` в `ExportReminders.swift` — сделать `TasksOrgConverter` conformable к `ReminderExporterProtocol` напрямую (`export(_:to:)` пишет результат конвертера в файл)
- [x] 4.3 Обновить дефолтное имя файла для `--format tasks-org` → `reminders_export_tasks_org.json`

## 5. Качество

- [x] 5.1 Запустить `swiftformat .` — проверить форматирование
- [x] 5.2 Запустить `periphery scan` с `--retain-codable-properties --exclude-tests` — проверить отсутствие мёртвого кода
- [x] 5.3 Запустить `swift test` — все тесты проходят
- [x] 5.4 Запустить `swift test --filter TasksOrgConverter` — только тесты конвертера

## 6. Исправления совместимости с нативным экспортом Tasks.org

### 6.1 Модели

- [x] 6.1.1 Переименовать поля в `TasksOrgTask`: `created` → `creationDate`, `modified` → `modificationDate`
- [x] 6.1.2 Заменить поле `completed` на `completionDate` (опциональное, включается только для выполненных задач)
- [x] 6.1.3 Сделать `dueDate` опциональным и опускать в JSON при отсутствии значения
- [x] 6.1.4 Удалить неиспользуемые приложением поля из `TasksOrgTask`: `readOnly`, `deleted`, `estimatedSeconds`, `elapsedSeconds`, `hideUntil`, `timerStart`, `repeatFrom`, `ringFlags`, `importance`, `caldavTasks`
- [x] 6.1.5 Создать `TasksOrgTaskWrapper` с полями `task`, `alarms`, `geofences`, `tags`, `comments`, `attachments`, `caldavTasks`
- [x] 6.1.6 Перенести `caldavTasks` из `TasksOrgTask` на уровень `TasksOrgTaskWrapper`
- [x] 6.1.7 Обновить `CaldavAccount`: `accountType = 2` (TYPE_LOCAL), убрать `url` и `lastSync`
- [x] 6.1.8 Обновить `CaldavCalendar`: `color` — реальный цвет, а не `0`
- [x] 6.1.9 Обновить `CaldavTask`: `remoteId` — строковый идентификатор вместо UUID/числа, `obj` и `deleted` опциональны (рекомендуется опускать)
- [x] 6.1.10 Обновить `TasksOrgBackup.version` до `150704`

### 6.2 Конвертер

- [x] 6.2.1 Обновить маппинг дат: `creationDate` → `creationDate`, `modificationDate` → `modificationDate`
- [x] 6.2.2 Обновить логику выполнения: генерировать `completionDate` только для `isCompleted == true`
- [x] 6.2.3 Опускать `dueDate` в JSON, если `ReminderItem.dueDate == nil`
- [x] 6.2.4 Генерировать строковый `remoteId` для `CaldavTask` на основе `ReminderItem.id`, не Int64
- [x] 6.2.5 Не заполнять `CaldavAccount.lastSync` — локальный аккаунт не синхронизируется
- [x] 6.2.6 Заполнять `CaldavCalendar.color` реальным цветом (детерминированно от `listName`)
- [x] 6.2.7 Собирать `TasksOrgTaskWrapper` с пустыми массивами и `caldavTasks`
- [x] 6.2.8 Реализовать нормализацию `recurrenceRule`: извлекать часть после `RRULE` (отбрасывая `:` или пробел) и содержащую `FREQ=` (регистронезависимую); опускать поле при отсутствии `FREQ=`

### 6.3 Тесты

- [x] 6.3.1 Тест: `version` равен `150704`
- [x] 6.3.2 Тест: `isCompleted == false` → поле `completionDate` отсутствует
- [x] 6.3.3 Тест: `isCompleted == true` + `completionDate` → `completionDate` присутствует
- [x] 6.3.4 Тест: `dueDate == nil` → поле `dueDate` отсутствует
- [x] 6.3.5 Тест: `creationDate` и `modificationDate` маппятся в правильные имена полей
- [x] 6.3.6 Тест: обёртка задачи содержит `alarms`, `geofences`, `tags`, `comments`, `attachments`, `caldavTasks`
- [x] 6.3.7 Тест: `caldavTasks` находится на уровне обёртки, а не внутри `task`
- [x] 6.3.8 Тест: `CaldavTask.remoteId` сериализуется как JSON-строка
- [x] 6.3.9 Тест: `CaldavAccount.accountType == 2` и отсутствуют `url`/`lastSync`
- [x] 6.3.10 Тест: `CaldavCalendar.color != 0`
- [x] 6.3.11 Тест: в `task` отсутствуют `readOnly`, `deleted`, `estimatedSeconds`, `elapsedSeconds`, `hideUntil`, `timerStart`, `repeatFrom`, `ringFlags`, `importance`, `caldavTasks`
- [x] 6.3.12 Тест: `recurrenceRule` вида `"EKRecurrenceRule <0x...> RRULE FREQ=DAILY;INTERVAL=12"` → `recurrence` = `"FREQ=DAILY;INTERVAL=12"`
- [x] 6.3.13a Тест: `recurrenceRule` вида `"EKRecurrenceRule <0x...> RRULE:FREQ=DAILY;INTERVAL=12"` → `recurrence` = `"FREQ=DAILY;INTERVAL=12"`
- [x] 6.3.13b Тест: `recurrenceRule` без `RRULE` или без `FREQ=` (в любом регистре) → поле `recurrence` отсутствует
