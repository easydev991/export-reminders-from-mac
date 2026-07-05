## Purpose

Экспортёр `CSVExporter` записывает напоминания в табличный CSV-формат для импорта в сторонние приложения (TickTick, Microsoft To Do, Notion). Универсальные англоязычные заголовки, экранирование спецсимволов, ISO 8601 даты.

## Requirements

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

### Requirement: CSV экранирование специальных символов
Значения, содержащие запятые, кавычки или переводы строк, SHALL быть обёрнуты в двойные кавычки. Двойные кавычки внутри значений SHALL быть удвоены (`"` → `""`).

#### Scenario: Значение с запятой
- **WHEN** `title` содержит `"Купить хлеб, молоко"`
- **THEN** значение в CSV записано как `"Купить хлеб, молоко"`

#### Scenario: Значение с двойными кавычками
- **WHEN** `notes` содержит `Сказать "Привет"`
- **THEN** значение в CSV записано как `"Сказать ""Привет"""`

#### Scenario: Значение с переводом строки
- **WHEN** `notes` содержит многострочный текст
- **THEN** значение обёрнуто в двойные кавычки, переводы строк сохранены внутри кавычек

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
