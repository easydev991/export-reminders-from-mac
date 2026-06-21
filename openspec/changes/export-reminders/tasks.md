# Задачи реализации: Export Reminders

## 1. Настройка проекта

- [x] 1.1 Инициализировать SPM-пакет с executable-таргетом `ExportReminders` и тестовым таргетом `ExportRemindersTests`
- [x] 1.2 Добавить зависимость `swift-argument-parser` (from: "1.2.0") в `Package.swift`
- [x] 1.3 Добавить `EventKit.framework` в зависимости таргета `ExportReminders` (через `linkerSettings` или системную линковку)
- [x] 1.4 Создать структуру папок: `Sources/ExportReminders/Models/`, `Services/`, `Exporters/`
- [x] 1.5 Создать структуру папок: `Tests/ExportRemindersTests/` с теми же подпапками
- [x] 1.6 Создать `.gitignore` для `.build/`, `.swiftpm/`, `DerivedData/`

## 2. TDD: Domain Models — ReminderItem и ReminderList

### 2.A RED — Тесты моделей (Swift Testing)

- [x] 2.1 Написать тест `ReminderItemTests` — инициализация с обязательными полями (`@Test("Инициализация ReminderItem с обязательными полями")`)
- [x] 2.2 Написать тест — JSON-сериализация ReminderItem со всеми полями (`@Test("Сериализация ReminderItem в JSON")`)
- [x] 2.3 Написать тест — JSON-десериализация ReminderItem из полного JSON (`@Test("Десериализация ReminderItem из JSON")`)
- [x] 2.4 Написать тест — десериализация с отсутствующими опциональными полями (`@Test("Десериализация ReminderItem без опциональных полей")`)
- [x] 2.5 Написать тест — Equatable: равные объекты (`@Test("Сравнение одинаковых ReminderItem")`)
- [x] 2.6 Написать тест — Equatable: разные объекты (`@Test("Сравнение разных ReminderItem")`)
- [x] 2.7 Написать тест `ReminderListTests` — инициализация с обязательными полями (`@Test("Инициализация ReminderList с обязательными полями")`)
- [x] 2.8 Написать тест — ReminderList с цветом (`@Test("Инициализация ReminderList с цветом")`)
- [x] 2.9 Написать тест — Codable roundtrip для ReminderList (`@Test("Сериализация и десериализация ReminderList")`)

### 2.B GREEN — Реализация моделей

- [x] 2.10 Реализовать `ReminderItem` — структура с 12 полями, Codable, Equatable, CodingKeys с `encodeIfPresent`
- [x] 2.11 Реализовать `ReminderList` — структура с id, title, color, Codable, Equatable
- [x] 2.12 Убедиться, что все тесты из 2.A проходят (`swift test --filter ReminderItemTests`, `swift test --filter ReminderListTests`)

### 2.C REFACTOR — Улучшение моделей

- [x] 2.13 Проверить, что все опциональные поля действительно опциональны, значения по умолчанию корректны
- [x] 2.14 Добавить `CustomTestStringConvertible` к моделям для улучшения диагностики в тестах

## 3. TDD: EventKit Service — протокол, мок, реализация

### 3.A RED — Тесты и мок-сервис (Swift Testing)

- [x] 3.1 Создать `ReminderServiceProtocol` с методами `fetchAllReminders()` и `fetchAllLists()` (оба `async throws`)
- [x] 3.2 Создать `MockReminderService` — мок, реализующий протокол с предопределёнными данными (вынести в `Tests/ExportRemindersTests/Mocks/`)
- [x] 3.3 Написать тест — мок возвращает предопределённые напоминания (`@Test("MockReminderService возвращает предопределённые напоминания")`)
- [x] 3.4 Написать тест — мок возвращает предопределённые списки (`@Test("MockReminderService возвращает предопределённые списки")`)
- [x] 3.5 Написать тест — мок возвращает пустой массив при отсутствии данных (`@Test("MockReminderService возвращает пустой массив")`)
- [x] 3.6 Написать тест — мок выбрасывает ошибку при configured failure (`@Test("MockReminderService выбрасывает ошибку")`)

### 3.B GREEN — Реализация EventKitReminderService

- [x] 3.7 Реализовать `EventKitReminderServiceError` — enum с кейсами `accessDenied`, `fetchFailed(Error)`, `unknown`
- [x] 3.8 Реализовать `EventKitReminderService` — инициализация с `EKEventStore`, запрос доступа через `requestFullAccessToReminders`
- [x] 3.9 Реализовать `fetchAllLists()` — `store.calendars(for: .reminder)`, маппинг EKCalendar → ReminderList
- [x] 3.10 Реализовать `fetchAllReminders()` — `store.fetchReminders(matching:)`, маппинг EKReminder → ReminderItem
- [x] 3.11 Реализовать маппинг полей: `calendarItemIdentifier` → `id`, `title` → `title`, `notes` → `notes`, `dueDateComponents` → `dueDate`, `completionDate` → `completionDate`, `creationDate` → `creationDate`, `lastModifiedDate` → `modificationDate`, `priority` → `priority`, `isCompleted` → `isCompleted`, `recurrenceRules` → `recurrenceRule`, `url` → `url`
- [x] 3.12 Написать unit-тесты для маппинга EKReminder → ReminderItem (создание мок-EKReminder с предопределёнными полями, проверка всех 12 полей)
- [x] 3.13 Написать unit-тест для обработки ошибки доступа (проверяется через MockReminderService, т.к. EKEventStore не мокается напрямую)

### 3.C REFACTOR — Улучшение сервиса

- [x] 3.14 Вынести маппинг `EKReminder → ReminderItem` в отдельный метод (`mapToReminderItem`)
- [x] 3.15 Вынести маппинг `EKCalendar → ReminderList` в отдельный метод (`mapToReminderList`)
- [x] 3.16 Добавить диагностическое логирование через `fputs` в stderr

## 4. TDD: Export Formats — JSON и CSV

### 4.A RED — Тесты экспортёров (Swift Testing)

- [x] 4.1 Создать `ReminderExporterProtocol` с методом `func export(_ reminders: [ReminderItem], to url: URL) throws`
- [x] 4.2 Создать shared test fixtures — `ReminderItem.sample` и `[ReminderItem].samples` в `Tests/ExportRemindersTests/Fixtures/`
- [x] 4.3 Написать тесты `JSONExporterTests` — экспорт нескольких напоминаний, проверка валидного JSON (`@Test("JSONExporter создаёт валидный JSON с массивом напоминаний")`)
- [x] 4.4 Написать тест — JSON экспорт пустого массива (`@Test("JSONExporter создаёт [] для пустого массива")`)
- [x] 4.5 Написать тест — JSON не содержит ключей для nil-полей (`@Test("JSONExporter не включает nil-поля в вывод")`)
- [x] 4.6 Написать тест — JSON ошибка записи (`@Test("JSONExporter выбрасывает ошибку при недоступной директории")`)
- [x] 4.7 Написать тесты `CSVExporterTests` — заголовки содержат все 12 полей в правильном порядке (`@Test("CSVExporter создаёт корректную строку заголовков")`)
- [x] 4.8 Написать тест — CSV экспорт одного напоминания (`@Test("CSVExporter записывает одно напоминание")`)
- [x] 4.9 Написать тест — CSV экспорт нескольких напоминаний (`@Test("CSVExporter записывает несколько напоминаний")`)
- [x] 4.10 Написать тест — CSV экранирование запятых в значениях (`@Test("CSVExporter экранирует запятые в значениях")`)
- [x] 4.11 Написать тест — CSV экранирование кавычек (`@Test("CSVExporter удваивает кавычки внутри значений")`)
- [x] 4.12 Написать тест — CSV nil-поля как пустая строка (`@Test("CSVExporter записывает nil-поля как пустую строку")`)
- [x] 4.13 Написать тест — CSV даты в ISO 8601 (`@Test("CSVExporter форматирует даты в ISO 8601")`)

### 4.B GREEN — Реализация экспортёров

- [x] 4.14 Реализовать `JSONExporter` — `JSONEncoder` с `.iso8601` dateEncodingStrategy, `.prettyPrinted`, `encodeIfPresent`
- [x] 4.15 Реализовать `CSVExporter` — формирование заголовков с универсальными англоязычными названиями колонок, экранирование значений, запись построчно
- [x] 4.16 Убедиться, что все тесты из 4.A проходят

### 4.C REFACTOR — Улучшение экспортёров

- [x] 4.17 Вынести общую сортировку и фильтрацию в shared extension (фильтрация в CLI, экспортёры чисто пишут данные)
- [x] 4.18 Вынести форматирование дат в единый DateFormatter (CSVExporter использует ISO8601DateFormatter, JSONExporter — стратегию .iso8601)
- [x] 4.19 Проверить edge cases: специальные Unicode-символы в именах списков, очень длинные заметки

## 5. TDD: CLI Interface — ArgumentParser

### 5.A RED — Тесты CLI (Swift Testing, интеграционные с мок-сервисом)

- [x] 5.1 Создать enum `Format: String, ExpressibleByArgument, CaseIterable` со значениями `json`, `csv`
- [x] 5.2 Создать `MockReminderExporter` — мок-экспортёр, проверяющий что метод `export` был вызван с ожидаемыми параметрами
- [x] 5.3 Написать тест — парсинг `--format json` (`@Test("CLI парсит аргумент --format json")`)
- [x] 5.4 Написать тест — парсинг `--format csv` (`@Test("CLI парсит аргумент --format csv")`)
- [ ] 5.5 Написать тест — неверный формат вызывает ошибку (`@Test("CLI выдаёт ошибку при неверном --format")`)
- [x] 5.6 Написать тест — парсинг `--output` (`@Test("CLI парсит аргумент --output с пользовательским путём")`)
- [x] 5.7 Написать тест — дефолтный `--output` (`@Test("CLI использует дефолтный путь для --output")`)
- [x] 5.8 Написать тест — парсинг `--list` одиночный (`@Test("CLI фильтрует по одному списку")`)
- [x] 5.9 Написать тест — парсинг `--list` множественный (`@Test("CLI фильтрует по нескольким спискам")`)
- [x] 5.10 Написать тест — парсинг `--completed true` (`@Test("CLI фильтрует только выполненные напоминания")`)
- [x] 5.11 Написать тест — парсинг `--completed false` (`@Test("CLI фильтрует только невыполненные напоминания")`)
- [x] 5.12 Написать тест — интеграция CLI + мок-сервис + мок-экспортёр (`@Test("CLI вызывает сервис и экспортёр в правильном порядке")`)
- [x] 5.13 Написать тест — CLI выводит ошибку при `accessDenied` (`@Test("CLI выводит сообщение об ошибке доступа в stderr")`)
- [x] 5.14 Написать тест — CLI выводит ошибку при сбое экспорта (`@Test("CLI выводит сообщение об ошибке записи файла в stderr")`)

### 5.B GREEN — Реализация CLI

- [x] 5.15 Реализовать `ExportRemindersCLI` — `@main`, `ParsableCommand`, аргументы `--format`, `--output`, `--list`, `--completed`
- [x] 5.16 Реализовать `run()` — создание сервиса, вызов `fetchAllReminders()`, применение фильтров, вызов экспортёра
- [x] 5.17 Реализовать выбор экспортёра по значению `--format` (switch по enum: `json` → `JSONExporter`, `csv` → `CSVExporter`)
- [x] 5.18 Реализовать фильтрацию по `--list` (регистро-независимое сравнение `listName`)
- [x] 5.19 Реализовать фильтрацию по `--completed`
- [x] 5.20 Реализовать обработку ошибок: код выхода 1 для ошибок доступа, код 2 для ошибок записи
- [x] 5.21 Убедиться, что все тесты из 5.A проходят

### 5.C REFACTOR — Улучшение CLI

- [x] 5.22 Вынести фильтрацию напоминаний в отдельный метод/extension (`applyFilters(to:)`)
- [x] 5.23 Добавить индикатор прогресса (количество экспортированных напоминаний в stdout)
- [x] 5.24 Добавить `--help` с понятными описаниями на английском (для совместимости с ArgumentParser)

## 6. Сборка, подпись и финальная проверка

- [ ] 6.1 Убедиться, что `swift test` проходит все тесты (полный прогон без фильтров)
- [ ] 6.2 Проверить `swift build -c release` без ошибок
- [ ] 6.3 Создать entitlements с `com.apple.security.personal-information.reminders`
- [ ] 6.4 Подписать бинарник ad-hoc: `codesign --sign - --entitlements <file> .build/release/export-reminders`
- [ ] 6.5 Протестировать запуск: `swift run export-reminders --format json`
- [ ] 6.6 Протестировать запуск: `swift run export-reminders --format csv --output ./out.csv`
- [ ] 6.7 Протестировать фильтрацию: `swift run export-reminders --list "Покупки" --completed false`
- [ ] 6.8 Проверить производительность на 1 000+ напоминаний (должно быть < 5 секунд)
- [ ] 6.9 Написать README.md с инструкцией по сборке, настройке TCC и примерами использования
