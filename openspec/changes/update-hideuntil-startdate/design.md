## Context

Экспортёр напоминаний работает в три слоя:

1. **EventKit → `ReminderItem`** (`EventKitReminderService.mapToReminderItem`)
2. **`ReminderItem` → формат Tasks.org** (`TasksOrgConverter`)
3. **`ReminderItem` → JSON/CSV** (`JSONExporter`, `CSVExporter`)

Сейчас `ReminderItem` содержит только `dueDate`, но не `startDate`. `TasksOrgTask` не содержит `hideUntil`. В результате Tasks.org не получает «Дату начала» и не может ставить пуш-уведомления типа `TYPE_REL_START`.

## Goals / Non-Goals

**Goals:**

- Промежуточная модель `ReminderItem` должна содержать `startDate`.
- `EventKitReminderService` должен читать `EKReminder.startDateComponents`.
- `TasksOrgTask` должен содержать `hideUntil`.
- `TasksOrgConverter` должен заполнять `hideUntil = startDate ?? dueDate`.
- CSV-экспортёр должен экспортировать `startDate`.
- Все изменения должны быть покрыты тестами TDD.

**Non-Goals:**

- Отдельный API или специальный путь вычисления `hideUntil`, отличный от fallback-а `startDate ?? dueDate`.
- Ручной парсинг RRULE для вычисления следующей даты — используем уже вычисленный `dueDate` из EventKit.
- Изменение поведения JSON-экспортёра, кроме автоматического кодирования нового поля.
- Изменение CLI-аргументов.

## Decisions

1. **Fallback `hideUntil = startDate ?? dueDate`**
   - `startDate` передаёт пользовательскую «Дату начала» из Apple Reminders.
   - Если пользователь не задал `startDate`, берём `dueDate`, потому что для повторяющихся напоминаний EventKit уже предоставляет дату следующего срабатывания.
   - Альтернатива — оставить `hideUntil` пустым при отсутствии `startDate`. Отклонено: тогда одноразовые напоминания без явной даты начала потеряют уведомления.

2. **Позиция `startDate` в `ReminderItem`**
   - Вставлена после `dueDate`, перед `completionDate`. Это сохраняет логический порядок полей дат и минимизирует diff в JSON/CSV.

3. **Позиция `hideUntil` в `TasksOrgTask`**
   - Вставлена после `dueDate`, как в Android-модели `Task`.

4. **CSV-заголовок**
   - Новая колонка `startDate` идёт сразу после `dueDate`: `id,listName,title,notes,dueDate,startDate,completionDate,creationDate,modificationDate,priority,isCompleted,recurrenceRule,url`.

## Risks / Trade-offs

- **[Risk] Изменение формата CSV сломает внешних потребителей** → не критично: проект — CLI-утилита, CSV используется вручную. Новая колонка добавлена в середине, чтобы соответствовать порядку полей модели.
- **[Risk] `startDateComponents` может содержать только дату без времени** → `EKReminder.startDateComponents?.date` вернёт дату с временем 00:00, что совместимо с tasks.org.
- **[Risk] Equatable-синтез Swift включает новое поле** → обновляем фикстуры и тесты, это ожидаемо.
