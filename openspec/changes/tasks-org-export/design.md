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
- `CaldavAccount(uuid, name, accountType, url)` — `accountType = 2` (TYPE_LOCAL)
- `CaldavCalendar(uuid, name, color, account)` — ссылка `account` на `CaldavAccount.uuid`
- `CaldavTask(calendar, remoteId, obj, deleted)` — `@SerialName("object")` для `obj`, `deleted = 0` (не удалена)
- `TasksOrgTask` — все поля задачи включая `recurrence: String?` (iCalendar RRULE, не структура)
- `TasksOrgBackup` — корневая обёртка

**Обоснование**:
- Изоляция: модели Tasks.org не зависят от `ReminderItem` и не влияют на универсальный JSON
- `Codable` + `JSONEncoder` с `dateEncodingStrategy` не нужен — все даты кодируются как `Int64` (ms), это делается вручную в конвертере
- Ключи JSON должны точно совпадать с именами полей в Tasks.org (`uuid`, а не `id`; `account`, а не `accountName`; `@SerialName("object")` для `obj`) — иначе импортёр (`kotlinx.serialization`) их не распознает
- `accountType = 2` (TYPE_LOCAL) — обязательно для создания локального календаря в Tasks.org
- `CaldavTask.remoteId` — обязательное поле, генерируется как UUID
- `CaldavTask.obj = "\(remoteId).ics"` — формат `"{uuid}.ics"`, используется для дедупликации
- `CaldavTask.deleted = 0` — 0 означает «не удалена»
- `recurrence: String?` — это строка iCalendar RRULE (например `"FREQ=WEEKLY;INTERVAL=1"`), НЕ структура. Подтверждено из исходников tasks.org (Task.kt: `var recurrence: String? = null`)

### 3. Приоритет: switch-маппинг, не формула

**Решение**: Явный `switch priority { case 1: return 0; case 5: return 1; case 9: return 2; default: return 3 }`

**Обоснование**: Шкалы имеют разную семантику. Apple: 0=none, 1=high, 5=medium, 9=low (нелинейная). Tasks.org: 0=HIGH → 3=NONE (линейная). Простая формула (например, `4 - priority/3`) неочевидна и хрупка. Явный switch читаем и тестируем.

### 4. Caldav-календари: один аккаунт `"export-reminders"`, календари по `listName`

**Решение**: Все списки Apple Reminders группируются под одним Caldav-аккаунтом `"export-reminders"`. Для каждого уникального `listName` создаётся отдельный `CaldavCalendar`. `CaldavTask` связывает напоминание с календарём.

**Обоснование**: Tasks.org требует привязки задачи к календарю. Создание отдельных аккаунтов для каждого списка избыточно. `export-reminders` — семантически понятное имя аккаунта-источника.

### 5. `isCompleted` → `completionDate`: каскадный подход

**Решение**: Каскад из трёх уровней, от наиболее точного к наименее:
1. `isCompleted == false` → `completed = 0`
2. `isCompleted == true` + `completionDate != nil` → `completed = completionDate.timeIntervalSince1970 * 1000`
3. `isCompleted == true` + `completionDate == nil` + `modificationDate != nil` → `completed = modificationDate.timeIntervalSince1970 * 1000`
4. `isCompleted == true` + обе даты `nil` → `completed = Date().timeIntervalSince1970 * 1000` (fallback на текущий timestamp)

**Обоснование**: `EKReminder.completionDate` — это та самая дата, которую Apple сохраняет при отметке «выполнено». Она уже читается из EventKit и доступна в `ReminderItem`. Игнорировать её в пользу текущего timestamp бессмысленно. `modificationDate` (`EKReminder.lastModifiedDate`) — хороший второй рубеж: при выполнении напоминания эта дата тоже обновляется, хотя может быть перезаписана последующим редактированием. Текущий timestamp — последний рубеж на случай повреждённых данных (обе даты nil).

### 6. TDD: структура тестов

**Порядок**: Сначала создаются тесты `TasksOrgConverterTests`, затем реализация `TasksOrgConverter`. Тесты отталкиваются от спецификации (`specs/tasks-org-export/spec.md`), каждый сценарий → тест-кейс.

**Фикстуры**: Используют существующие `ReminderItem.samples` и создают новые таргетированные фикстуры для граничных случаев (разные приоритеты, комбинации полей).

## Risks / Trade-offs

- **[Позднее редактирование после выполнения]**: Если пользователь отредактировал выполненное напоминание, `modificationDate` сместится на время редактирования — но каскад отдаёт приоритет `completionDate`, которая не меняется при редактировании → **Mitigation**: `completionDate` — первый приоритет, она стабильна; `modificationDate` используется только если `completionDate == nil`.
- **[Потеря URL-поля]**: В Tasks.org нет поля `url`, сохраняем в тексте `notes` → **Mitigation**: документировано в справке; при импорте пользователь видит ссылку в описании задачи.
- **[Детерминизм UUID]**: `uuid` календарей и аккаунта генерируются на основе `listName` (SHA-256 → первые 16 байт → UUID) — коллизии практически невозможны → **Mitigation**: SHA-256 даёт 2^128 пространство UUID; для реальных имён списков коллизия исключена.
- **[Tasks.org API может измениться]**: Формат backup-файла не является публичным API → **Mitigation**: версия `version: 157` зафиксирована; пустые секции-заглушки обеспечивают forward-совместимость с новыми полями.

## Migration Plan

1. Добавить `tasks-org` в `Format` enum
2. Создать модели `TasksOrg/` (Codable структуры) и тесты к ним
3. Реализовать `TasksOrgConverter` в TDD-стиле
4. Интегрировать конвертер в `ExportReminders.swift` (в `makeExporter` или через отдельный switch)
5. Запустить полный набор тестов, `periphery scan`, `swiftformat .`
6. **Rollback**: удаление `tasks-org` из `Format` enum возвращает систему к исходному состоянию

## Open Questions

- Нужна ли отдельная CLI-команда `convert-to-tasks-org --input reminders.json` для конвертации уже экспортированного файла? Или достаточно `--format tasks-org`?
