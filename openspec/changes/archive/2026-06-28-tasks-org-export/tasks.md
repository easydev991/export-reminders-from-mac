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
- [x] 4.4 Тест: CLI с `--format tasks-org` и без `--output` использует `reminders_export_tasks_org.json` (`CLITests.swift`)
- [x] 4.5 Тест: CLI с `--format tasks-org` и явным `--output` использует указанный путь

## 5. Makefile

- [x] 5.1 Добавить таргет `export-tasks-org` в `Makefile`, который вызывает `make export ARGS="--format tasks-org"`
- [x] 5.2 Обновить `help` и список примеров в `Makefile`
- [x] 5.3 Интеграционная проверка: `make export-tasks-org` собирает release-билд, подписывает бинарь и запускает экспорт в `reminders_export_tasks_org.json`

## 6. Перезапись существующего выходного файла

- [x] 6.1 Тест (TDD: RED): повторный вызов `TasksOrgConverter.export(_:to:)` перезаписывает существующий файл новым содержимым
- [x] 6.2 Тест (TDD: RED): повторный вызов `JSONExporter.export(_:to:)` перезаписывает существующий файл
- [x] 6.3 Тест (TDD: RED): повторный вызов `CSVExporter.export(_:to:)` перезаписывает существующий файл
- [x] 6.4 Реализация (TDD: GREEN): все экспортёры перезаписывают существующий выходной файл

## 7. Качество

- [x] 7.1 Запустить `swiftformat .` — проверить форматирование
- [x] 7.2 Запустить `periphery scan` с `--retain-codable-properties --exclude-tests` — проверить отсутствие мёртвого кода
- [x] 7.3 Запустить `swift test` — все тесты проходят
- [x] 7.4 Запустить `swift test --filter TasksOrgConverter` — только тесты конвертера

## 8. Исправления совместимости с нативным экспортом Tasks.org

### 8.1 Модели

- [x] 8.1.1 Переименовать поля в `TasksOrgTask`: `created` → `creationDate`, `modified` → `modificationDate`
- [x] 8.1.2 Заменить поле `completed` на `completionDate` (опциональное, включается только для выполненных задач)
- [x] 8.1.3 Сделать `dueDate` опциональным и опускать в JSON при отсутствии значения
- [x] 8.1.4 Удалить неиспользуемые приложением поля из `TasksOrgTask`: `readOnly`, `deleted`, `estimatedSeconds`, `elapsedSeconds`, `hideUntil`, `timerStart`, `repeatFrom`, `ringFlags`, `importance`, `caldavTasks`
- [x] 8.1.5 Создать `TasksOrgTaskWrapper` с полями `task`, `alarms`, `geofences`, `tags`, `comments`, `attachments`, `caldavTasks`
- [x] 8.1.6 Перенести `caldavTasks` из `TasksOrgTask` на уровень `TasksOrgTaskWrapper`
- [x] 8.1.7 Обновить `CaldavAccount`: `accountType = 2` (TYPE_LOCAL), убрать `url` и `lastSync`
- [x] 8.1.8 Обновить `CaldavCalendar`: `color` — реальный цвет, а не `0`
- [x] 8.1.9 Обновить `CaldavTask`: `remoteId` — строковый идентификатор вместо UUID/числа, `obj` и `deleted` опциональны (рекомендуется опускать)
- [x] 8.1.10 Обновить `TasksOrgBackup.version` до `150704`

### 8.2 Конвертер

- [x] 8.2.1 Обновить маппинг дат: `creationDate` → `creationDate`, `modificationDate` → `modificationDate`
- [x] 8.2.2 Обновить логику выполнения: генерировать `completionDate` только для `isCompleted == true`
- [x] 8.2.3 Опускать `dueDate` в JSON, если `ReminderItem.dueDate == nil`
- [x] 8.2.4 Генерировать строковый `remoteId` для `CaldavTask` на основе `ReminderItem.id`, не Int64
- [x] 8.2.5 Не заполнять `CaldavAccount.lastSync` — локальный аккаунт не синхронизируется
- [x] 8.2.6 Заполнять `CaldavCalendar.color` реальным цветом (детерминированно от `listName`)
- [x] 8.2.7 Собирать `TasksOrgTaskWrapper` с пустыми массивами и `caldavTasks`
- [x] 8.2.8 Реализовать нормализацию `recurrenceRule`: извлекать часть после `RRULE` (отбрасывая `:` или пробел) и содержащую `FREQ=` (регистронезависимую); опускать поле при отсутствии `FREQ=`

### 8.3 Тесты

- [x] 8.3.1 Тест: `version` равен `150704`
- [x] 8.3.2 Тест: `isCompleted == false` → поле `completionDate` отсутствует
- [x] 8.3.3 Тест: `isCompleted == true` + `completionDate` → `completionDate` присутствует
- [x] 8.3.4 Тест: `dueDate == nil` → поле `dueDate` отсутствует
- [x] 8.3.5 Тест: `creationDate` и `modificationDate` маппятся в правильные имена полей
- [x] 8.3.6 Тест: обёртка задачи содержит `alarms`, `geofences`, `tags`, `comments`, `attachments`, `caldavTasks`
- [x] 8.3.7 Тест: `caldavTasks` находится на уровне обёртки, а не внутри `task`
- [x] 8.3.8 Тест: `CaldavTask.remoteId` сериализуется как JSON-строка
- [x] 8.3.9 Тест: `CaldavAccount.accountType == 2` и отсутствуют `url`/`lastSync`
- [x] 8.3.10 Тест: `CaldavCalendar.color != 0`
- [x] 8.3.11 Тест: в `task` отсутствуют `readOnly`, `deleted`, `estimatedSeconds`, `elapsedSeconds`, `hideUntil`, `timerStart`, `repeatFrom`, `ringFlags`, `importance`, `caldavTasks`
- [x] 8.3.12 Тест: `recurrenceRule` вида `"EKRecurrenceRule <0x...> RRULE FREQ=DAILY;INTERVAL=12"` → `recurrence` = `"FREQ=DAILY;INTERVAL=12"`
- [x] 8.3.13a Тест: `recurrenceRule` вида `"EKRecurrenceRule <0x...> RRULE:FREQ=DAILY;INTERVAL=12"` → `recurrence` = `"FREQ=DAILY;INTERVAL=12"`
- [x] 8.3.13b Тест: `recurrenceRule` без `RRULE` или без `FREQ=` (в любом регистре) → поле `recurrence` отсутствует

## 9. Сокращение кода после ревью (ponytail/cleanup)

### 9.1 Модель `TasksOrgData` — дефолтные пустые коллекции

- [x] 9.1.1 Добавить в `TasksOrgData` `init(tasks:caldavAccounts:caldavCalendars:)` с дефолтными `[]`/ `[:]` для пустых секций
- [x] 9.1.2 Упростить инициализацию в `TasksOrgConverter.convert` до `TasksOrgData(tasks: wrappers, caldavAccounts: account.map { [$0] } ?? [], caldavCalendars: calendars)`
- [x] 9.1.3 Тест `emptyReminders` продолжает проверять наличие пустых секций

### 9.2 Нормализация `recurrenceRule`

- [x] 9.2.1 Заменить многоступенчатую нормализацию на: `substring = String(rule[range.upperBound...]).trimmingCharacters(in: [":", " "])`; `uppercased().contains("FREQ=")` — иначе `nil`
- [x] 9.2.2 Сохранить регистронезависимую проверку и сохранение исходного регистра значения
- [x] 9.2.3 Параметризованный тест `recurrenceRule` покрывает все кейсы одним `@Test`

### 9.3 Генерация детерминированного UUID

- [x] 9.3.1 Собрать hex через `map { String(format: "%02X", $0) }.joined()`
- [x] 9.3.2 Разбить на UUID-группы через `prefix`/`dropFirst` вместо ручного `String(format:)`
- [x] 9.3.3 Сохранить версию/вариант (bytes[6] & 0x0F | 0x50, bytes[8] & 0x3F | 0x80)

### 9.4 Цвет календаря

- [x] 9.4.1 Заменить byte-by-byte сборку `UInt32` на `UInt32(bigEndian: Data(digest.prefix(4)))`
- [x] 9.4.2 Сохранить alpha=0xFF и `Int32(bitPattern:)`
- [x] 9.4.3 Тест `calendarColorSignedInt32` сохраняет ожидаемое детерминированное значение

### 9.5 Тесты — удалить/сократить избыточные

- [x] 9.5.1 Удалить `dateConversionAndOmission`; перенести проверку nil-дат в `directFieldMapping`
- [x] 9.5.2 Объединить 4 теста `completionDate` в один тест с четырьмя reminder'ами
- [x] 9.5.3 Удалить `unusedFieldsAbsent` (Codable сам убирает отсутствующие ключи)
- [x] 9.5.4 Удалить проверки `url == nil` / `lastSync == nil` из `localAccountType` (эти поля в модели отсутствуют)
- [x] 9.5.5 Объединить 5 тестов `recurrenceRule` в один параметризованный `@Test` с массивом кейсов
- [x] 9.5.6 Проверить, что нет регрессии по покрытию: `swift test` проходит

### 9.6 Качество после сокращения

- [x] 9.6.1 `swiftformat .`
- [x] 9.6.2 `periphery scan --targets ExportReminders`
- [x] 9.6.3 `swift test`
- [x] 9.6.4 `swift test --filter TasksOrgConverter`
