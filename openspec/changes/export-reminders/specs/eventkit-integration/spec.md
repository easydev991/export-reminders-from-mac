## ADDED Requirements

### Requirement: Протокол ReminderServiceProtocol определяет контракт сервиса
Протокол `ReminderServiceProtocol` SHALL определять два асинхронных метода: `fetchAllReminders() async throws -> [ReminderItem]` и `fetchAllLists() async throws -> [ReminderList]`.

#### Scenario: Соответствие мок-реализации протоколу
- **WHEN** мок-класс реализует `ReminderServiceProtocol`
- **THEN** компиляция успешна, оба метода доступны для вызова

### Requirement: EventKitReminderService запрашивает доступ к Reminders
`EventKitReminderService` SHALL при инициализации создавать экземпляр `EKEventStore` и при первом вызове `fetchAllReminders()` запрашивать доступ к `.reminder` через `requestAccess(to:completion:)`.

#### Scenario: Доступ предоставлен
- **WHEN** пользователь предоставил доступ к Reminders
- **THEN** `fetchAllReminders()` успешно возвращает массив `[ReminderItem]`

#### Scenario: Доступ запрещён
- **WHEN** пользователь отказал в доступе к Reminders
- **THEN** `fetchAllReminders()` выбрасывает ошибку `accessDenied`

### Requirement: Чтение всех списков напоминаний
`EventKitReminderService.fetchAllLists()` SHALL возвращать все календари типа `.reminder` из `EKEventStore`, отображая каждый `EKCalendar` в `ReminderList`.

#### Scenario: Успешное чтение списков
- **WHEN** в EventKit доступно несколько календарей типа `.reminder`
- **THEN** `fetchAllLists()` возвращает массив `[ReminderList]` с корректными `id`, `title` и `color`

#### Scenario: Пустой результат
- **WHEN** в EventKit нет календарей типа `.reminder`
- **THEN** `fetchAllLists()` возвращает пустой массив (не ошибку)

### Requirement: Чтение всех напоминаний
`EventKitReminderService.fetchAllReminders()` SHALL загружать все напоминания через `EKEventStore.fetchReminders(matching:)` с предикатом на все календари типа `.reminder`, и маппить каждый `EKReminder` в `ReminderItem`.

#### Scenario: Успешное чтение напоминаний
- **WHEN** в EventKit есть напоминания в нескольких списках
- **THEN** возвращается массив `[ReminderItem]`, где каждое напоминание содержит `listName` из родительского `EKCalendar`

#### Scenario: Напоминание со всеми заполненными полями
- **WHEN** `EKReminder` имеет все возможные поля (заголовок, заметки, дата, приоритет, URL, правило повторения)
- **THEN** соответствующий `ReminderItem` содержит все поля с корректными значениями

#### Scenario: Пустой результат
- **WHEN** в EventKit нет напоминаний
- **THEN** `fetchAllReminders()` возвращает пустой массив (не ошибку)

### Requirement: Обработка ошибок EventKit
Сервис SHALL предоставлять тип `EventKitReminderServiceError` с кейсами: `accessDenied`, `fetchFailed(Error)`, `unknown`. Все ошибки EventKit SHALL быть обёрнуты в этот тип.

#### Scenario: Ошибка доступа
- **WHEN** доступ к Reminders запрещён на системном уровне
- **THEN** выбрасывается `EventKitReminderServiceError.accessDenied`

#### Scenario: Ошибка при загрузке
- **WHEN** EventKit возвращает внутреннюю ошибку при `fetchReminders(matching:)`
- **THEN** выбрасывается `EventKitReminderServiceError.fetchFailed` с оригинальной ошибкой
