## MODIFIED Requirements

### Requirement: Прямой маппинг полей без изменений

Следующие поля SHALL быть скопированы из `ReminderItem` в Tasks.org Task без преобразований:
- `title` → `title` (String)
- `creationDate` → `creationDate` (Long, через Unix-ms конвертацию)
- `modificationDate` → `modificationDate` (Long, через Unix-ms конвертацию)

Поле `recurrenceRule` → `recurrence` (String) SHALL быть нормализовано: извлекается часть, начиная с `RRULE` (см. Requirement «Нормализация recurrenceRule до RRULE`).

Поле `id` напоминания используется для генерации `remoteId` в `CaldavTask` (строковый идентификатор).

Поле `hideUntil` SHALL быть заполнено в Tasks.org Task на основе `ReminderItem` следующим образом:
1. Если `startDate` не равен `nil`, `hideUntil` SHALL равняться `startDate` в миллисекундах Unix-эпохи.
2. Иначе, если `dueDate` не равен `nil`, `hideUntil` SHALL равняться `dueDate` в миллисекундах Unix-эпохи.
3. Если обе даты равны `nil`, поле `hideUntil` SHALL отсутствовать в JSON.

Следующие поля SHALL отсутствовать в `task`, так как не используются приложением Tasks.org:
- `readOnly`, `deleted`, `estimatedSeconds`, `elapsedSeconds`, `timerStart`, `repeatFrom`, `ringFlags`, `caldavTasks`

#### Scenario: Все поля скопированы
- **WHEN** напоминание имеет `title`, `recurrenceRule`, `creationDate`, `modificationDate`, `id`
- **THEN** соответствующие поля в выходном JSON содержат преобразованные значения

#### Scenario: hideUntil заполняется из startDate
- **WHEN** `startDate` содержит "2025-06-20T09:00:00Z", а `dueDate` равен `nil`
- **THEN** в JSON поле `hideUntil` записано как `1750410000000`

#### Scenario: hideUntil заполняется из dueDate
- **WHEN** `startDate` равен `nil`, а `dueDate` содержит "2025-06-21T10:30:00Z"
- **THEN** в JSON поле `hideUntil` записано как `1750501800000`

#### Scenario: hideUntil отсутствует без дат
- **WHEN** и `startDate`, и `dueDate` равны `nil`
- **THEN** в JSON поле `hideUntil` отсутствует

### Requirement: Поля Tasks.org Task

JSON-модель `TasksOrgTask` SHALL содержать поля задачи Tasks.org. Поле `hideUntil` (Long, optional) SHALL присутствовать после `dueDate`.

#### Scenario: TasksOrgTask с hideUntil
- **WHEN** `TasksOrgTask` кодируется в JSON с `hideUntil = 1750410000000`
- **THEN** выходной JSON содержит поле `hideUntil` с переданным значением

#### Scenario: TasksOrgTask без hideUntil
- **WHEN** `TasksOrgTask` кодируется в JSON с `hideUntil = nil`
- **THEN** в JSON поле `hideUntil` отсутствует
