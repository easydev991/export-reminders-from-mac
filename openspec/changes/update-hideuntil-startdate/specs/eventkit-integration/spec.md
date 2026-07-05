## MODIFIED Requirements

### Requirement: Чтение всех напоминаний
`EventKitReminderService.fetchAllReminders()` SHALL загружать все напоминания через `EKEventStore.fetchReminders(matching:)` с предикатом на все календари типа `.reminder`, и маппить каждый `EKReminder` в `ReminderItem`.

#### Scenario: Успешное чтение напоминаний
- **WHEN** в EventKit есть напоминания в нескольких списках
- **THEN** возвращается массив `[ReminderItem]`, где каждое напоминание содержит `listName` из родительского `EKCalendar`

#### Scenario: Напоминание со всеми заполненными полями
- **WHEN** `EKReminder` имеет все возможные поля (заголовок, заметки, дата, дата начала, приоритет, URL, правило повторения)
- **THEN** соответствующий `ReminderItem` содержит все поля с корректными значениями
- **THEN** поле `startDate` равно дате из `EKReminder.startDateComponents`

#### Scenario: Напоминание без startDateComponents
- **WHEN** `EKReminder` не содержит `startDateComponents`
- **THEN** соответствующий `ReminderItem.startDate` равен `nil`

#### Scenario: Пустой результат
- **WHEN** в EventKit нет напоминаний
- **THEN** `fetchAllReminders()` возвращает пустой массив (не ошибку)
