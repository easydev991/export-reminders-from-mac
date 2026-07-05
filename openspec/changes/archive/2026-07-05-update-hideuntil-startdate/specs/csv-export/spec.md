## MODIFIED Requirements

### Requirement: CSVExporter формирует корректный CSV
`CSVExporter` SHALL записывать массив `[ReminderItem]` в CSV-файл. Первая строка SHALL содержать заголовки — имена всех полей `ReminderItem`. Поля SHALL быть перечислены в фиксированном порядке: `id`, `listName`, `title`, `notes`, `dueDate`, `startDate`, `completionDate`, `creationDate`, `modificationDate`, `priority`, `isCompleted`, `recurrenceRule`, `url`.

#### Scenario: Экспорт одного напоминания
- **WHEN** одно напоминание экспортируется в CSV
- **THEN** выходной файл содержит строку заголовков и одну строку данных
- **THEN** значения разделены запятыми

#### Scenario: Экспорт нескольких напоминаний
- **WHEN** массив из 3 напоминаний экспортируется в CSV
- **THEN** выходной файл содержит 1 строку заголовков + 3 строки данных = 4 строки

#### Scenario: Пустой массив
- **WHEN** пустой массив экспортируется в CSV
- **THEN** выходной файл содержит только строку заголовков

#### Scenario: Заголовки содержат startDate
- **WHEN** экспортируется пустой массив в CSV
- **THEN** первая строка равна `id,listName,title,notes,dueDate,startDate,completionDate,creationDate,modificationDate,priority,isCompleted,recurrenceRule,url`

### Requirement: Формат значений nil
Опциональные поля со значением `nil` SHALL быть представлены пустой строкой (без кавычек).

#### Scenario: Nil-поле
- **WHEN** `dueDate` равен `nil`
- **THEN** в CSV это поле записано как пустая строка (между запятыми)

#### Scenario: Nil startDate
- **WHEN** `startDate` равен `nil`
- **THEN** в CSV это поле записано как пустая строка

### Requirement: Формат дат в CSV
Даты SHALL быть записаны в формате ISO 8601 в UTC (`yyyy-MM-dd'T'HH:mm:ss'Z'`). `nil`-даты SHALL быть пустой строкой.

#### Scenario: Дата startDate в CSV
- **WHEN** `startDate` содержит дату "2025-06-20T09:00:00Z"
- **THEN** в CSV это поле записано как `2025-06-20T09:00:00Z`
