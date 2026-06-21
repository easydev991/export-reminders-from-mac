## Purpose

Экспортёр `JSONExporter` сериализует напоминания в JSON-формат. JSON — канонический формат с полным сохранением данных, ISO 8601 датами и пропуском nil-полей.

## Requirements

### Requirement: Протокол ReminderExporterProtocol определяет контракт экспорта
Протокол `ReminderExporterProtocol` SHALL определять метод `func export(_ reminders: [ReminderItem], to url: URL) throws`.

#### Scenario: Экспортёр реализует протокол
- **WHEN** класс `JSONExporter` реализует `ReminderExporterProtocol`
- **THEN** метод `export(_:to:)` доступен для вызова

### Requirement: JSONExporter формирует валидный JSON
`JSONExporter` SHALL сериализовать массив `[ReminderItem]` в JSON и записывать в файл по указанному URL. Даты SHALL быть в ISO 8601 формате.

#### Scenario: Экспорт нескольких напоминаний
- **WHEN** массив из 3 напоминаний со всеми полями экспортируется в JSON
- **THEN** выходной файл содержит валидный JSON-массив с 3 объектами
- **THEN** каждый объект содержит все 12 полей

#### Scenario: Экспорт пустого массива
- **WHEN** пустой массив экспортируется в JSON
- **THEN** выходной файл содержит `[]` (пустой JSON-массив)

#### Scenario: Экспорт с опциональными полями
- **WHEN** напоминание имеет опциональные поля равные `nil`
- **THEN** JSON не содержит ключей для `nil`-полей (используется `encodeIfPresent`)

#### Scenario: Ошибка записи в недоступную директорию
- **WHEN** `URL` указывает на недоступную для записи директорию
- **THEN** метод выбрасывает ошибку

### Requirement: ISO 8601 формат дат
Все даты (`Date?`) SHALL быть сериализованы в формате ISO 8601 через `ISO8601DateFormatter` или стратегию `dateEncodingStrategy = .iso8601`.

#### Scenario: Дата сериализуется в ISO 8601
- **WHEN** `dueDate` содержит дату "2025-01-15T10:30:00Z"
- **THEN** в JSON это поле записано как `"2025-01-15T10:30:00Z"`
