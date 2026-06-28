## Purpose

Конвертер `TasksOrgConverter` преобразует универсальные напоминания (`[ReminderItem]`) в JSON-файл формата backup-файла Tasks.org, пригодный для импорта через `Intent.ACTION_OPEN_DOCUMENT` в Android-приложении Tasks.org. Конвертер работает как на уровне данных (из `[ReminderItem]`), так и поверх уже экспортированного универсального JSON-файла (через декодирование в `[ReminderItem]`). Формат совместим с парсером `TasksJsonImporter` (kotlinx.serialization с `ignoreUnknownKeys = true`).

## ADDED Requirements

### Requirement: Конвертер принимает массив ReminderItem и возвращает Data

`TasksOrgConverter` SHALL предоставлять метод `convert(_ reminders: [ReminderItem]) throws -> Data`, возвращающий готовый JSON в формате Tasks.org для записи в файл.

#### Scenario: Успешная конвертация

- **WHEN** метод `convert(_:)` вызван с массивом из 2 напоминаний
- **THEN** возвращается `Data`, содержащий валидный JSON Tasks.org
- **THEN** JSON содержит корневые ключи `version`, `timestamp`, `data`

#### Scenario: Пустой массив

- **WHEN** метод `convert(_:)` вызван с пустым массивом `[]`
- **THEN** возвращается `Data` с полной структурой конверта, `data.tasks` — пустой массив `[]`

### Requirement: JSON-конверт Tasks.org

Выходной JSON SHALL иметь корневую структуру `{version, timestamp, data}`, где `version` — целое число (`150704`), `timestamp` — текущее Unix-время в миллисекундах, `data` — объект с секциями `tasks`, `caldavAccounts`, `caldavCalendars`, `places`, `tags`, `filters`, `taskListMetadata`, `taskAttachments`, `intPrefs`, `longPrefs`, `stringPrefs`, `boolPrefs`, `setPrefs`.

#### Scenario: Пустой массив напоминаний

- **WHEN** экспортируется пустой массив
- **THEN** выходной JSON содержит полную структуру конверта, `data.tasks` — пустой массив `[]`
- **THEN** все обязательные секции присутствуют с пустыми значениями

#### Scenario: Несколько напоминаний

- **WHEN** экспортируется массив из 2 напоминаний из одного списка
- **THEN** `data.tasks` содержит 2 объекта
- **THEN** `data.caldavCalendars` содержит 1 календарь
- **THEN** `data.caldavAccounts` содержит 1 аккаунт
- **THEN** каждый объект в `data.tasks` имеет поле `task` с полями задачи Tasks.org

### Requirement: Формат дат — Unix timestamp в миллисекундах

Все даты в выходном JSON SHALL быть представлены как число (Long) — количество миллисекунд с Unix-эпохи (1970-01-01T00:00:00Z). `nil`-даты SHALL опускаться в JSON, а не записываться как `0`.

#### Scenario: Дата в Unix ms

- **WHEN** `dueDate` содержит "2024-01-15T10:30:00Z"
- **THEN** в JSON поле `dueDate` записано как `1705312200000`

#### Scenario: Nil-дата

- **WHEN** `completionDate` равен `nil` и задача не выполнена
- **THEN** в JSON поле `completionDate` отсутствует

#### Scenario: Отсутствие dueDate

- **WHEN** `dueDate` равен `nil`
- **THEN** в JSON поле `dueDate` отсутствует (не записывается как `0`)

### Requirement: Маппинг приоритета Apple → Tasks.org

Приоритет `ReminderItem.priority` (0–9, шкала Apple EKReminderPriority) SHALL быть сконвертирован в шкалу Tasks.org: 0=HIGH, 1=MEDIUM, 2=LOW, 3=NONE. Правила маппинга:
- `priority == 1` (Apple High) → `0` (HIGH)
- `priority == 5` (Apple Medium) → `1` (MEDIUM)
- `priority == 9` (Apple Low) → `2` (LOW)
- `priority == 0` или любое другое значение → `3` (NONE)

#### Scenario: Высокий приоритет Apple → HIGH

- **WHEN** `priority == 1`
- **THEN** в JSON `importance` равно `0`

#### Scenario: Средний приоритет Apple → MEDIUM

- **WHEN** `priority == 5`
- **THEN** в JSON `importance` равно `1`

#### Scenario: Низкий приоритет Apple → LOW

- **WHEN** `priority == 9`
- **THEN** в JSON `importance` равно `2`

#### Scenario: Без приоритета → NONE

- **WHEN** `priority == 0`
- **THEN** в JSON `importance` равно `3`

### Requirement: Преобразование isCompleted в completionDate

Статус выполнения `isCompleted` SHALL быть преобразован в поле `completionDate` (Long) формата Tasks.org каскадным методом:
1. `isCompleted == false` → поле `completionDate` не включается в JSON
2. `isCompleted == true` И `completionDate != nil` → `completionDate = completionDate.timeIntervalSince1970 * 1000`
3. `isCompleted == true` И `completionDate == nil` И `modificationDate != nil` → `completionDate = modificationDate.timeIntervalSince1970 * 1000`
4. `isCompleted == true` И обе даты `nil` → `completionDate = Date().timeIntervalSince1970 * 1000` (текущий timestamp)

#### Scenario: Невыполненное напоминание

- **WHEN** `isCompleted == false`
- **THEN** в JSON отсутствует поле `completionDate`

#### Scenario: Выполненное — есть completionDate

- **WHEN** `isCompleted == true` и `completionDate` содержит "2024-01-14T18:00:00Z"
- **THEN** в JSON `completionDate` = `1705255200000`

#### Scenario: Выполненное — completionDate nil, есть modificationDate

- **WHEN** `isCompleted == true`, `completionDate == nil`, `modificationDate` содержит "2024-01-14T19:00:00Z"
- **THEN** в JSON `completionDate` = `1705258800000`

#### Scenario: Выполненное — обе даты nil

- **WHEN** `isCompleted == true`, `completionDate == nil`, `modificationDate == nil`
- **THEN** в JSON `completionDate` > 0 (текущий Unix timestamp в миллисекундах)

### Requirement: Маппинг listName в Caldav-календари и задачи

Каждый уникальный `listName` из массива напоминаний SHALL порождать:
- Один `CaldavAccount` с полями `uuid` = `<детерминированный UUID>`, `name` = `"export-reminders"`, `accountType` = `2` (TYPE_LOCAL)
- Один `CaldavCalendar` с полями `uuid` = `<детерминированный UUID>`, `name` = значение `listName`, `color` = `<реальный цвет в signed 32-bit int (Android Color) с alpha=0xFF>`, `account` = `uuid` аккаунта
- Каждое напоминание связывается с календарём через `CaldavTask` на уровне обёртки задачи с полями `calendar` = `uuid` календаря, `remoteId` = `<строковый идентификатор>`

Идентификаторы (`uuid` календаря, `uuid` аккаунта) SHALL генерироваться детерминированно на основе `listName` (например, через SHA-256 → первые 16 байт → UUID). `CaldavTask.remoteId` SHALL быть уникальным строковым идентификатором для каждой задачи. `CaldavTask.obj` (ключ `"object"`) MAY присутствовать; если указан, SHALL иметь формат `"{remoteId}.ics"` (используется импортёром для дедупликации). Рекомендуется опускать `obj`, так как импортёр Tasks.org генерирует его сам как `"{remoteId}.ics"`. `CaldavTask.deleted` MAY присутствовать; если отсутствует, импортёр использует значение по умолчанию `0` (не удалена). Рекомендуется опускать `deleted`.

#### Scenario: Один список — один календарь

- **WHEN** все напоминания имеют `listName == "Личные"`
- **THEN** в `caldavCalendars` один элемент с `name == "Личные"` и `color` — signed 32-bit int, не равный `0`
- **THEN** в `caldavAccounts` один элемент с `accountType == 2` и отсутствуют `url` и `lastSync`
- **THEN** каждое напоминание в `caldavTasks` на уровне обёртки задачи ссылается на этот календарь
- **THEN** `remoteId` в `caldavTasks` является строкой
- **THEN** `obj` в `caldavTasks` отсутствует или равен `"{remoteId}.ics"`

#### Scenario: Несколько списков

- **WHEN** напоминания из двух списков: "Личные" и "Работа"
- **THEN** в `caldavCalendars` два элемента
- **THEN** в `caldavAccounts` один элемент
- **THEN** напоминания из "Личные" ссылаются на календарь "Личные", из "Работа" — на "Работа"

### Requirement: Поле url добавляется в notes

Поле `url` из `ReminderItem` SHALL быть присоединено к полю `notes` в формате `"\n\nURL: <url>"` (с двумя переводами строки перед URL). Если `url == nil`, notes не изменяется.

#### Scenario: URL присутствует, notes есть

- **WHEN** `notes == "Купить 2% жирности"` и `url == "https://example.com"`
- **THEN** в JSON `notes` = `"Купить 2% жирности\n\nURL: https://example.com"`

#### Scenario: URL присутствует, notes nil

- **WHEN** `notes == nil` и `url == "https://example.com"`
- **THEN** в JSON `notes` = `"URL: https://example.com"`

#### Scenario: URL отсутствует

- **WHEN** `url == nil` и `notes == "Текст"`
- **THEN** в JSON `notes` = `"Текст"` (без изменений)

### Requirement: Нормализация recurrenceRule до FREQ-правила

Если `ReminderItem.recurrenceRule` не равен `nil`, конвертер SHALL извлечь из него только iCalendar-часть после `RRULE`, отбросив последующий разделитель (`:` или пробел). Извлечённая часть SHALL содержать `FREQ=` в любом регистре; в противном случае поле `recurrence` SHALL быть опущено.

#### Scenario: recurrenceRule содержит RRULE с пробелом

- **WHEN** `recurrenceRule` содержит `"EKRecurrenceRule <0x...x> RRULE FREQ=DAILY;INTERVAL=12"`
- **THEN** в JSON `recurrence` = `"FREQ=DAILY;INTERVAL=12"`

#### Scenario: recurrenceRule содержит RRULE с двоеточием

- **WHEN** `recurrenceRule` содержит `"EKRecurrenceRule <0x...x> RRULE:FREQ=DAILY;INTERVAL=12"`
- **THEN** в JSON `recurrence` = `"FREQ=DAILY;INTERVAL=12"`

#### Scenario: recurrenceRule содержит RRULE без FREQ

- **WHEN** `recurrenceRule` содержит `"EKRecurrenceRule <0x...x> RRULE"` без `FREQ=`
- **THEN** в JSON поле `recurrence` отсутствует

#### Scenario: recurrenceRule содержит RRULE с freq= в нижнем регистре

- **WHEN** `recurrenceRule` содержит `"EKRecurrenceRule <0x...x> RRULE freq=DAILY;INTERVAL=12"`
- **THEN** в JSON `recurrence` = `"freq=DAILY;INTERVAL=12"` (значение сохраняется как есть; проверка `FREQ=` регистронезависимая)

#### Scenario: recurrenceRule не содержит RRULE

- **WHEN** `recurrenceRule` содержит `"FREQ=DAILY;INTERVAL=12"` без префикса `RRULE`
- **THEN** в JSON поле `recurrence` отсутствует

### Requirement: Прямой маппинг полей без изменений

Следующие поля SHALL быть скопированы из `ReminderItem` в Tasks.org Task без преобразований:
- `title` → `title` (String)
- `creationDate` → `creationDate` (Long, через Unix-ms конвертацию)
- `modificationDate` → `modificationDate` (Long, через Unix-ms конвертацию)

Поле `recurrenceRule` → `recurrence` (String) SHALL быть нормализовано: извлекается часть, начиная с `RRULE` (см. Requirement «Нормализация recurrenceRule до RRULE`).

Поле `id` напоминания используется для генерации `remoteId` в `CaldavTask` (строковый идентификатор).

Следующие поля SHALL отсутствовать в `task`, так как не используются приложением Tasks.org:
- `readOnly`, `deleted`, `estimatedSeconds`, `elapsedSeconds`, `hideUntil`, `timerStart`, `repeatFrom`, `ringFlags`, `importance`, `caldavTasks`

#### Scenario: Все поля скопированы

- **WHEN** напоминание имеет `title`, `recurrenceRule`, `creationDate`, `modificationDate`, `id`
- **THEN** соответствующие поля в выходном JSON содержат преобразованные значения

### Requirement: Пустые секции для совместимости с парсером

Следующие секции в `data` SHALL присутствовать с пустыми значениями:
- `places` — пустой массив `[]`
- `tags` — пустой массив `[]`
- `filters` — пустой массив `[]`
- `taskListMetadata` — пустой массив `[]`
- `taskAttachments` — пустой массив `[]`
- `intPrefs` — пустой объект `{}`
- `longPrefs` — пустой объект `{}`
- `stringPrefs` — пустой объект `{}`
- `boolPrefs` — пустой объект `{}`
- `setPrefs` — пустой объект `{}`

#### Scenario: Пустые секции присутствуют

- **WHEN** экспортируется любое количество напоминаний
- **THEN** все перечисленные секции присутствуют в выходном JSON с пустыми значениями

### Requirement: Структура обёртки задачи

Каждый элемент `data.tasks` SHALL быть объектом-обёрткой со следующими ключами:
- `task` — объект задачи Tasks.org (`TasksOrgTask`)
- `alarms` — пустой массив `[]`
- `geofences` — пустой массив `[]`
- `tags` — пустой массив `[]`
- `comments` — пустой массив `[]`
- `attachments` — пустой массив `[]`
- `caldavTasks` — массив из одного `CaldavTask`, связанного с календарём задачи

`caldavTasks` SHALL находиться на уровне обёртки, а не внутри `task`.

#### Scenario: Обёртка содержит все обязательные ключи

- **WHEN** экспортируется одно напоминание
- **THEN** элемент `data.tasks[0]` содержит ключи `task`, `alarms`, `geofences`, `tags`, `comments`, `attachments`, `caldavTasks`
- **THEN** `task` не содержит ключа `caldavTasks`
- **THEN** `caldavTasks` содержит один элемент с `calendar`, равным `uuid` календаря
