## Purpose

Доменные модели `ReminderItem` и `ReminderList` представляют напоминания и списки напоминаний из Apple Reminders. Они используются всеми компонентами системы: сервисом чтения (EventKit), экспортёрами (JSON, CSV) и CLI.

## Requirements

### Requirement: Модель ReminderItem содержит все поля напоминания
Модель `ReminderItem` SHALL быть `Codable` и `Equatable` структурой с 13 полями: `id`, `listName`, `title`, `notes`, `dueDate`, `startDate`, `completionDate`, `creationDate`, `modificationDate`, `priority`, `isCompleted`, `recurrenceRule`, `url`. Опциональные поля SHALL быть объявлены как `Optional` (`nil` по умолчанию). Поле `priority` SHALL быть типа `Int` со значением по умолчанию `0`.

#### Scenario: Корректная инициализация со всеми обязательными полями
- **WHEN** создаётся `ReminderItem` с обязательными полями (`id`, `listName`, `title`, `isCompleted`, `priority`)
- **THEN** объект успешно создаётся, опциональные поля равны `nil`, `priority` равен переданному значению

#### Scenario: Инициализация с startDate
- **WHEN** создаётся `ReminderItem` с `startDate`, равным "2025-06-20T09:00:00Z"
- **THEN** поле `startDate` содержит переданную дату

#### Scenario: Сериализация в JSON
- **WHEN** `ReminderItem` со всеми заполненными полями кодируется через `JSONEncoder`
- **THEN** выходной JSON содержит все 13 полей с корректными значениями
- **THEN** даты сериализованы в ISO 8601 формат

#### Scenario: Десериализация из JSON
- **WHEN** валидный JSON со всеми полями декодируется через `JSONDecoder`
- **THEN** полученный `ReminderItem` равен исходному (сравнение через `Equatable`)

#### Scenario: Десериализация с отсутствующими опциональными полями
- **WHEN** JSON без опциональных полей (`notes`, `dueDate`, `startDate`, `completionDate`, `creationDate`, `modificationDate`, `recurrenceRule`, `url`) декодируется
- **THEN** полученный `ReminderItem` имеет `nil` для всех отсутствующих опциональных полей

#### Scenario: Сравнение двух одинаковых объектов
- **WHEN** два `ReminderItem` имеют одинаковые значения всех полей
- **THEN** `==` возвращает `true`

#### Scenario: Сравнение двух разных объектов
- **WHEN** два `ReminderItem` отличаются хотя бы одним полем
- **THEN** `==` возвращает `false`

### Requirement: Модель ReminderList представляет список напоминаний
Модель `ReminderList` SHALL быть `Codable` и `Equatable` структурой с полями: `id: String`, `title: String`, `color: String?`. Поле `color` SHALL быть опциональным.

#### Scenario: Корректная инициализация с обязательными полями
- **WHEN** создаётся `ReminderList` с `id` и `title`
- **THEN** объект успешно создаётся, `color` равен `nil`

#### Scenario: Инициализация с цветом
- **WHEN** создаётся `ReminderList` с `id`, `title` и `color`
- **THEN** все три поля содержат переданные значения

#### Scenario: Сериализация и десериализация
- **WHEN** `ReminderList` кодируется в JSON и затем декодируется обратно
- **THEN** полученный объект равен исходному
