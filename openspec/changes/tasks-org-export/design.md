## Context

Export Reminders уже экспортирует напоминания в универсальный JSON (`JSONExporter`) — канонический формат с полным сохранением данных, ISO 8601 датами и пропуском nil-полей. Пользователи хотят импортировать эти данные в Tasks.org (Android), но формат несовместим.

Вместо создания прямого экспортёра (который дублировал бы логику сериализации), мы строим **конвертер поверх универсального формата**: он получает `[ReminderItem]` (те же данные, что используются для универсального JSON) и преобразует их в формат Tasks.org.

Конвертер также может работать как утилита: прочитать уже экспортированный универсальный JSON-файл и сконвертировать его.

## Goals / Non-Goals

**Goals:**
- Конвертация `[ReminderItem]` в Tasks.org backup JSON — совместимый с `TasksJsonImporter`
- Добавление `tasks-org` как третьего значения `Format` в CLI
- TDD: тесты пишутся первыми, реализация — после
- Конвертер доступен как библиотечный компонент (принимает `[ReminderItem]`, возвращает `Data`)
- Совместимость с парсером Tasks.org (kotlinx.serialization, `ignoreUnknownKeys = true`)

**Non-Goals:**
- Двусторонняя синхронизация (Tasks.org → Apple Reminders)
- Поддержка CSV-импорта в Tasks.org (его нет)
- Изменение структуры `ReminderItem` или `JSONExporter`
- Поддержка вложений (attachments) — поле `url` сохраняется в тексте `notes`
- Полноценный Caldav-сервер — календари создаются как заглушки для импорта

## Decisions

### 1. Конвертер на уровне `[ReminderItem]`, не на уровне JSON-строки

**Решение**: `TasksOrgConverter.convert(_ reminders: [ReminderItem]) throws -> Data`

**Альтернатива**: конвертация `JSON String → JSON String` (парсинг универсального JSON, трансформация, запись).

**Обоснование**: Работа на уровне типизированных данных исключает двойную сериализацию/десериализацию. CLI уже получает `[ReminderItem]` от `EventKitReminderService` — конвертер встраивается в тот же пайплайн. При необходимости работы с файлом — достаточно декодировать универсальный JSON в `[ReminderItem]` (стандартным `JSONDecoder`), затем передать в конвертер.

### 2. Модели Tasks.org — отдельные Codable-структуры в `Models/TasksOrg/`

**Решение**: Создать пакет структур, точно повторяющих JSON-формат Tasks.org:
- `CaldavAccount(uuid, name, accountType)` — `accountType = 2` (TYPE_LOCAL)
- `CaldavCalendar(uuid, name, color, account)` — ссылка `account` на `CaldavAccount.uuid`, `color` — реальный цвет календаря в формате Android `Color` (signed 32-bit int, alpha=0xFF)
- `CaldavTask(calendar, remoteId, obj, deleted)` — `@SerialName("object")` для `obj`, `remoteId` — строковый идентификатор, `obj` и `deleted` опциональны
- `TasksOrgTask` — поля задачи Tasks.org; лишние поля (`readOnly`, `deleted`, `estimatedSeconds`, `elapsedSeconds`, `hideUntil`, `timerStart`, `repeatFrom`, `ringFlags`, `importance`, `caldavTasks`) не включаются
- `TasksOrgTaskWrapper` — обёртка задачи на верхнем уровне: `{"task": TasksOrgTask, "alarms": [], "geofences": [], "tags": [], "comments": [], "attachments": [], "caldavTasks": [CaldavTask]}`
- `TasksOrgBackup` — корневая обёртка, `version = 150704`

**Обоснование**:
- Изоляция: модели Tasks.org не зависят от `ReminderItem` и не влияют на универсальный JSON
- `Codable` + `JSONEncoder` с `dateEncodingStrategy` не нужен — все даты кодируются как `Int64` (ms), это делается вручную в конвертере
- Ключи JSON должны точно совпадать с именами полей в Tasks.org (`uuid`, а не `id`; `account`, а не `accountName`; `@SerialName("object")` для `obj`) — иначе импортёр (`kotlinx.serialization`) их не распознает
- `accountType = 2` (TYPE_LOCAL) — локальный аккаунт, как в рабочем примере нативного экспорта Tasks.org для данных без синхронизации
- `url` и `lastSync` в `CaldavAccount` не включаются — локальный аккаунт не синхронизируется
- `CaldavTask.remoteId` — строковый идентификатор, соответствующий типу `CaldavTask.remoteId: String?` в Tasks.org (data/src/commonMain/kotlin/org/tasks/data/entity/CaldavTask.kt:45)
- `CaldavTask.obj` опускается; импортёр Tasks.org генерирует его сам как `"{remoteId}.ics"` при необходимости
- `CaldavTask.deleted` опускается; импортёр использует значение по умолчанию `0` (не удалена)
- `recurrence: String?` — это строка iCalendar RRULE (например `"FREQ=WEEKLY;INTERVAL=1"`), НЕ структура. Подтверждено из исходников tasks.org (Task.kt: `var recurrence: String? = null`). Перед записью значение из `EKRecurrenceRule.description` нормализуется: извлекается часть после `RRULE` (с отбрасыванием последующего двоеточия или пробела) и содержащая `FREQ=` (регистронезависимая проверка); если `FREQ=` отсутствует, поле не записывается
- `TasksOrgTaskWrapper` повторяет структуру нативного экспорта: `alarms`, `geofences`, `tags`, `comments`, `attachments` и `caldavTasks` находятся на уровне обёртки, а не внутри `task`
- `version = 150704` — актуальная версия backup-формата Tasks.org (нативный экспорт использует её, а не устаревшую `157`)

### 3. Caldav-календари: один аккаунт `"export-reminders"`, календари по `listName`

**Решение**: Все списки Apple Reminders группируются под одним Caldav-аккаунтом `"export-reminders"`. Для каждого уникального `listName` создаётся отдельный `CaldavCalendar`. `CaldavTask` связывает напоминание с календарём.

**Обоснование**: Tasks.org требует привязки задачи к календарю. Создание отдельных аккаунтов для каждого списка избыточно. `export-reminders` — семантически понятное имя аккаунта-источника.

### 5. `isCompleted` → `completionDate`: только для выполненных задач

**Решение**: В нативном экспорте Tasks.org используется поле `completionDate` (Long, Unix ms), и оно включается только если задача выполнена. Если задача не выполнена, поле отсутствует в JSON.

Каскад для определения значения `completionDate`:
1. `isCompleted == false` → поле `completionDate` не включается в JSON
2. `isCompleted == true` + `completionDate != nil` → `completionDate = completionDate.timeIntervalSince1970 * 1000`
3. `isCompleted == true` + `completionDate == nil` + `modificationDate != nil` → `completionDate = modificationDate.timeIntervalSince1970 * 1000`
4. `isCompleted == true` + обе даты `nil` → `completionDate = Date().timeIntervalSince1970 * 1000` (fallback на текущий timestamp)

**Обоснование**: `EKReminder.completionDate` — это та самая дата, которую Apple сохраняет при отметке «выполнено». Она уже читается из EventKit и доступна в `ReminderItem`. Игнорировать её в пользу текущего timestamp бессмысленно. `modificationDate` (`EKReminder.lastModifiedDate`) — хороший второй рубеж: при выполнении напоминания эта дата тоже обновляется, хотя может быть перезаписана последующим редактированием. Текущий timestamp — последний рубеж на случай повреждённых данных (обе даты nil). Поле `completionDate` вместо устаревшего `completed` требуется Tasks.org для распознавания выполненных задач.

### 6. TDD: структура тестов

**Порядок**: Сначала создаются тесты `TasksOrgConverterTests`, затем реализация `TasksOrgConverter`. Тесты отталкиваются от спецификации (`specs/tasks-org-export/spec.md`), каждый сценарий → тест-кейс.

**Фикстуры**: Используют существующие `ReminderItem.samples` и создают новые таргетированные фикстуры для граничных случаев (разные приоритеты, комбинации полей).

### 7. Имена полей дат: `creationDate` и `modificationDate`

**Решение**: В `TasksOrgTask` поля называются `creationDate` и `modificationDate` (а не `created` и `modified`).

**Обоснование**: Нативный экспорт Tasks.org использует именно эти имена. Парсер `kotlinx.serialization` сопоставляет JSON-ключи напрямую с именами свойств Kotlin; несоответствие имён приводит к тому, что даты не читаются приложением.

### 8. Отсутствие `dueDate` → поле опускается

**Решение**: Если `ReminderItem.dueDate == nil`, ключ `dueDate` не включается в JSON задачи.

**Обоснование**: Нативный экспорт Tasks.org не пишет `dueDate` для задач без срока. Наше текущее значение `dueDate: 0` интерпретируется приложением как срок в Unix-эпоху (1970-01-01), что помещает задачи в «Просроченное». Опускание поля эквивалентно отсутствию срока.

### 9. Обёртка задачи: пустые массивы на верхнем уровне

**Решение**: Каждый элемент `data.tasks` кодируется как объект-обёртка:
```json
{
  "task": { ... },
  "alarms": [],
  "geofences": [],
  "tags": [],
  "comments": [],
  "attachments": [],
  "caldavTasks": [ { ... } ]
}
```

**Обоснование**: Это точная структура нативного экспорта Tasks.org. `caldavTasks` должен находиться на уровне обёртки, а не внутри `task`. Пустые массивы требуются парсеру для корректной десериализации.

### 10. `remoteId` для `CaldavTask` — строковый идентификатор

**Решение**: `CaldavTask.remoteId` генерируется как строковый идентификатор на основе `ReminderItem.id` (например, сам `ReminderItem.id` UUID-строкой или его детерминированная строковая производная), а не как числовой идентификатор.

**Обоснование**: В Tasks.org поле `CaldavTask.remoteId` объявлено как `String?` (data/src/commonMain/kotlin/org/tasks/data/entity/CaldavTask.kt:45), и нативный backup-экспорт Tasks.org хранит его как строку (например, `"4125374714962732824"`). Запись числа напрямую (`-5628122126948131574`) ломает десериализацию в `TasksJsonImporter`, потому что `lenientJson` с `isLenient = true` не конвертирует JSON number в Kotlin `String?` автоматически, и возникает `SerializationException`. Строковый `remoteId` совместим с парсером и повторяет нативный экспорт.

### 11. Версия backup-формата

**Решение**: `TasksOrgBackup.version = 150704`.

**Обоснование**: Нативный экспорт Tasks.org использует версию `150704`. Наша текущая версия `157` сильно устарела и может приводить к отказу импорта или неполной обработке данных.

### 12. `CaldavAccount`: `accountType = 2` (TYPE_LOCAL)

**Решение**: `CaldavAccount` имеет `accountType = 2` (TYPE_LOCAL) и не содержит `url`, `lastSync`.

**Обоснование**: В Tasks.org константа `TYPE_LOCAL = 2`. Рабочий пример нативного экспорта содержит аккаунт `export-reminders` именно с `accountType = 2`. `TYPE_CALDAV = 0` предполагает синхронизацию по URL и требует дополнительных полей, что не соответствует импорту из Apple Reminders.

### 13. Цвет календаря

**Решение**: `CaldavCalendar.color` заполняется реальным цветом в формате Android `Color` (signed 32-bit int, alpha=0xFF), а не `0`.

**Обоснование**: Нативный экспорт Tasks.org содержит реальные цвета календарей, сериализованные как Kotlin `Int` (signed 32-bit). Значения с alpha=0xFF превышают `Int.MAX_VALUE`, поэтому их нужно сериализовать как signed int (`Int32(bitPattern:)` в Swift), иначе Kotlin `decodeInt` падает с `NumberFormatException`. Детерминированный цвет получаем из `listName` через SHA-256.

### 14. Нормализация `recurrenceRule` перед записью

**Решение**: Перед записью в поле `recurrence` значение из `EKRecurrenceRule.description` нормализуется: находится подстрока после `RRULE` (с отбрасыванием последующего `:` или пробела), и она записывается только если содержит `FREQ=` (регистронезависимая проверка). Если `RRULE` отсутствует, или присутствует `RRULE` без `FREQ=`, поле `recurrence` не включается в JSON.

**Обоснование**: `EKRecurrenceRule.description` возвращает строку вида `"EKRecurrenceRule <0xadcf66ca0> RRULE FREQ=DAILY;INTERVAL=12"`. Tasks.org передаёт значение `recurrence` напрямую в ical4j `RRule`, который принимает только чистое правило `"FREQ=DAILY;INTERVAL=12"` или legacy-форму `"RRULE:FREQ=DAILY;INTERVAL=12"`. Пробел в `"RRULE FREQ=..."` ломает парсер ical4j и вызывает краш при открытии задачи. Поэтому префикс `RRULE` вместе с разделителем отбрасывается, а в JSON сохраняется только валидное тело правила.

**Важно**: При первом импорте нового backup-файла после исправления конвертера Tasks.org запишет корректное значение `recurrence`. Если ранее импортировался файл с некорректным форматом (`"RRULE FREQ=..."` с пробелом или `"RRULE"` без `FREQ=`), Tasks.org может сохранить это старое значение при повторном импорте. Поэтому перед повторным импортом рекомендуется очистить хранилище приложения Tasks.org ("Очистить данные" / "Clear storage") или удалить старый аккаунт `export-reminders`, иначе ранее импортированные задачи с некорректным `recurrence` продолжат вызывать краш.

### 15. Makefile: отдельный таргет `export-tasks-org`

**Решение**: В `Makefile` добавить фиктивный таргет `export-tasks-org`, который делегирует в `export` с фиксированным форматом:
```make
export-tasks-org: ## Build, sign, and export reminders to Tasks.org format
	@$(MAKE) export ARGS="--format tasks-org"
```

**Обоснование**: Пользователи ожидают удобную команду для часто используемого формата. Универсальный `export` с `ARGS` сохраняется для гибкости; новый таргет — тонкая обёртка, не дублирующая логику сборки и подписания.

### 16. Перезапись существующего выходного файла

**Решение**: Все экспортёры (`JSONExporter`, `CSVExporter`, `TasksOrgConverter`) при записи в файл SHALL перезаписывать существующий файл. Для `Data.write(to:options:)` использовать опцию `.atomic`; для `String.write(to:atomically:encoding:)` атомарная запись уже перезаписывает файл. Если платформенный API не гарантирует перезапись, перед записью выполнять `FileManager.default.removeItem(at: url)` с игнорированием `fileNoSuchFileErr`.

**Обоснование**: Пользователь ожидает идиоматичного поведения CLI-утилиты: повторный запуск команды обновляет выходной файл. Текущее поведение `Data.write(to:)` без опций может завершаться ошибкой при существующем файле (в зависимости от платформы/версии Foundation), что ломает UX. Перезапись — общее требование для всех форматов, чтобы поведение было согласованным.

### 16. Сокращение кода после ревью

**Решение**: Применить lazy-упрощения, не влияющие на поведение:
- `TasksOrgData` получает `init` с дефолтными пустыми коллекциями, чтобы в конвертере оставались только непустые поля.
- `normalizeRecurrence` сводится к `trimmingCharacters(in: [":", " "])` + `uppercased().contains("FREQ=")`.
- `deterministicUUID` собирается через `map { String(format: "%02X", $0) }.joined()` + группировка `prefix`/`dropFirst`.
- `colorForList` использует `UInt32(bigEndian: Data(digest.prefix(4)))` вместо byte-by-byte цикла.
- Тесты: объединить/удалить избыточные кейсы (`dateConversionAndOmission`, 4 теста `completionDate`, `unusedFieldsAbsent`, лишние проверки в `localAccountType`, 5 тестов `recurrenceRule`) без потери покрытия.

**Обоснование**: Меньше кода — меньше поверхность для ошибок, проще ревью. Codable сам исключает отсутствующие ключи, а параметризованные тесты Swift Testing покрывают те же ветки компактнее.

## Risks / Trade-offs

- **[Позднее редактирование после выполнения]**: Если пользователь отредактировал выполненное напоминание, `modificationDate` сместится на время редактирования — но каскад отдаёт приоритет `completionDate`, которая не меняется при редактировании → **Mitigation**: `completionDate` — первый приоритет, она стабильна; `modificationDate` используется только если `completionDate == nil`.
- **[Потеря URL-поля]**: В Tasks.org нет поля `url`, сохраняем в тексте `notes` → **Mitigation**: документировано в справке; при импорте пользователь видит ссылку в описании задачи.
- **[Детерминизм UUID]**: `uuid` календарей и аккаунта генерируются на основе `listName` (SHA-256 → первые 16 байт → UUID) — коллизии практически невозможны → **Mitigation**: SHA-256 даёт 2^128 пространство UUID; для реальных имён списков коллизия исключена.
- **[Строковый remoteId]**: `CaldavTask.remoteId` в Tasks.org объявлен как `String?`; нативный экспорт хранит его как строку. Использование строки на основе `ReminderItem.id` сохраняет детерминизм и совместимость с `TasksJsonImporter` → **Mitigation**: `remoteId` генерируется как строка от `ReminderItem.id`.
- **[Tasks.org API может измениться]**: Формат backup-файла не является публичным API → **Mitigation**: версия `version: 150704` зафиксирована на основе нативного экспорта; структура обёртки и пустые секции обеспечивают forward-совместимость с новыми полями.
- **[Обратная совместимость]**: Исправление имён полей (`created` → `creationDate` и т.д.) ломает ранее сгенерированные файлы, но они всё равно были некорректны с точки зрения Tasks.org → **Mitigation**: это осознанное исправление; старые файлы можно перегенерировать.
- **[Повторный импорт и старый формат recurrence]**: Tasks.org может сохранить у существующих задач старое значение `recurrence` из предыдущего импорта, даже если новый backup-файл содержит корректное значение. Если старое значение было в неверном формате (например, `"RRULE FREQ=..."` с пробелом или `"RRULE"` без `FREQ=`), открытие такой задачи продолжит вызывать краш → **Mitigation**: перед повторным импортом очистить хранилище приложения Tasks.org или удалить аккаунт `export-reminders`; в документации указать это требование.

## Migration Plan

1. Обновить модели `TasksOrg/`:
   - Переименовать поля `created` → `creationDate`, `modified` → `modificationDate`, `completed` → `completionDate`
   - Добавить `TasksOrgTaskWrapper` с пустыми массивами `alarms`, `geofences`, `tags`, `comments`, `attachments`, `caldavTasks`
   - Перенести `caldavTasks` из `TasksOrgTask` на уровень обёртки
   - Удалить неиспользуемые поля из `TasksOrgTask`
   - Обновить `CaldavAccount`: `accountType = 2` (TYPE_LOCAL), убрать `url`/`lastSync`
    - Обновить `CaldavCalendar`: `color` — реальный цвет в signed 32-bit int
   - Обновить `CaldavTask`: `remoteId` — строковый идентификатор, `obj` и `deleted` опциональны (рекомендуется опускать)
   - Обновить `TasksOrgBackup.version` до `150704`
2. Обновить `TasksOrgConverter`:
   - `completionDate` включается только для выполненных задач
   - `dueDate` опускается, если nil
   - Генерация строкового `remoteId` для `CaldavTask` на основе `ReminderItem.id`
   - Нормализация `recurrenceRule` до RRULE перед записью в `recurrence`
   - Заполнение реального цвета
3. Обновить тесты `TasksOrgConverterTests`
4. Интегрировать конвертер в `ExportReminders.swift` (если ещё не интегрирован)
5. Добавить Makefile-таргет `export-tasks-org`, делирующий в `export ARGS="--format tasks-org"`
6. Обеспечить перезапись существующего выходного файла во всех экспортёрах (`JSONExporter`, `CSVExporter`, `TasksOrgConverter`)
7. Запустить полный набор тестов, `periphery scan`, `swiftformat .`
8. **Rollback**: удаление `tasks-org` из `Format` enum и таргета `export-tasks-org` из `Makefile` возвращает систему к исходному состоянию

## Open Questions

- Нужна ли отдельная CLI-команда `convert-to-tasks-org --input reminders.json` для конвертации уже экспортированного файла? Или достаточно `--format tasks-org`?
- Нужно ли полностью повторять структуру нативного экспорта (включая `places`, `tags` и т.д. на верхнем уровне), или достаточно минимальных исправлений (`completionDate` + отсутствие `dueDate: 0`)?
