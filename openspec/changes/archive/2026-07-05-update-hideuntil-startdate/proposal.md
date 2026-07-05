## Why

Напоминания Apple Reminders имеют поле «Дата начала» (`EKReminder.startDateComponents`). В бэкапе Tasks.org Android это поле хранится в колонке `hideUntil` таблицы `tasks`. Без заполненного `hideUntil` пуш-уведомления типа «в момент даты начала» (`Alarm.TYPE_REL_START = 1`) не срабатывают после импорта. Текущий экспортёр не переносит это поле, поэтому пользователи теряют напоминания при переносе из Apple Reminders в Tasks.org.

## What Changes

- Добавить поле `startDate: Date?` в промежуточную модель `ReminderItem`.
- Читать `EKReminder.startDateComponents` в `EventKitReminderService.mapToReminderItem`.
- Добавить поле `hideUntil: Int64?` в JSON-модель `TasksOrgTask`.
- Заполнять `hideUntil` в `TasksOrgConverter` значением `startDate ?? dueDate`.
- Обновить CSV-экспортёр, добавив колонку `startDate` после `dueDate`.
- Обновить тесты, включая новые сценарии для `hideUntil` и `startDate`.

## Capabilities

### New Capabilities

(none)

### Modified Capabilities

- `domain-models`: добавить поле `startDate` в модель `ReminderItem`.
- `eventkit-integration`: читать `startDateComponents` из `EKReminder`.
- `tasks-org-export`: заполнять поле `hideUntil` в выходном бэкапе.
- `csv-export`: добавить колонку `startDate` в CSV-выгрузку.

## Impact

- Изменяются публичные структуры `ReminderItem` и `TasksOrgTask` (добавление полей).
- Меняется формат CSV-файла: добавляется новая колонка `startDate`.
- Требуется обновить существующие тесты и фикстуры.
- Нет изменений в CLI-интерфейсе и внешних зависимостях.
