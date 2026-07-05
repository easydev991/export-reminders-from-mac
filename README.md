# export-reminders-from-mac

Swift CLI-инструмент для экспорта напоминаний из Apple Reminders (iCloud) на macOS в JSON, CSV и Tasks.org.

Использует **EventKit** напрямую — без межпроцессных вызовов к приложению «Напоминания». Выгрузка 1000+ напоминаний за < 1 секунды.

## Быстрый старт

```bash
# Экспорт в формате Tasks.org (сборка + подпись + выгрузка) для импорта в Android-приложение Tasks.org
make export-tasks-org

# Экспорт в CSV
make export ARGS="--format csv --output ./reminders.csv"

# Проверка и установка инструментов разработки
make setup
```

## Требования

- macOS 14+
- Xcode 15+ **или** Command Line Tools (`xcode-select --install`)
- Разрешение **Reminders** в Системных настройках → Конфиденциальность и безопасность → Напоминания

## Сборка

```bash
# Отладка
swift build

# Релиз
swift build -c release

# Тесты (Swift Testing)
swift test
```

## Настройка TCC

При первом запуске macOS запросит доступ к Напоминаниям. Для работы из терминала:

```bash
# Запись разрешения в TCC (требуется пароль администратора)
tccutil reset Reminders
# Затем запустите export-reminders — появится диалог запроса доступа
```

### Подпись для macOS 14+

После релизной сборки необходимо подписать бинарник с entitlement:

```bash
swift build -c release
codesign --sign - --entitlements entitlements.plist .build/release/ExportReminders
```

Файл `entitlements.plist` уже включён в репозиторий.

## Использование

```bash
# JSON (формат по умолчанию)
swift run ExportReminders --format json --output ./reminders.json

# CSV
swift run ExportReminders --format csv --output ./reminders.csv

# Tasks.org (Android-приложение Tasks.org)
swift run ExportReminders --format tasks-org --output ./reminders_export_tasks_org.json

# Фильтрация по списку (регистронезависимо)
swift run ExportReminders --list "Покупки" --list "Работа"

# Фильтрация только невыполненных
swift run ExportReminders --completed false

# Комбинированная фильтрация
swift run ExportReminders --format json --list "Покупки" --completed false

# Справка
swift run ExportReminders --help
```

## Форматы вывода

### JSON

ISO 8601 даты, без экранирования слэшей, ключи для nil-полей не включаются.

```json
[
  {
    "id" : "x-apple-reminder:...",
    "listName" : "Покупки",
    "title" : "Молоко",
    "notes" : "2.5%, если нет — 3.2%",
    "isCompleted" : false,
    "priority" : 0,
    "creationDate" : "2025-12-01T10:00:00Z",
    "modificationDate" : "2025-12-01T12:00:00Z"
  }
]
```

### CSV

Английские заголовки, 13 колонок, ISO 8601 даты, запятые и кавычки экранированы, nil = пустая строка.

```csv
id,listName,title,notes,dueDate,startDate,completionDate,creationDate,modificationDate,priority,isCompleted,recurrenceRule,url
x-apple-reminder:...,Покупки,Молоко,2.5%,,,,2025-12-01T10:00:00Z,2025-12-01T12:00:00Z,0,false,,
```

### Tasks.org

Backup-JSON для импорта в Android-приложение Tasks.org. Даты — Unix timestamp в миллисекундах, списки Apple Reminders мапятся в Caldav-календари. Поле `url` добавляется в конец `notes`.

```json
{
  "version": 150704,
  "timestamp": 1712345678901,
  "data": {
    "tasks": [
      {
        "task": {
          "title": "Молоко",
          "remoteId": "x-apple-reminder:...",
          "notes": null,
          "dueDate": null,
          "creationDate": null,
          "modificationDate": null,
          "completionDate": null
        },
        "caldavTasks": [
          { "calendar": "...", "remoteId": "x-apple-reminder:..." }
        ]
      }
    ],
    "caldavAccounts": [{ "uuid": "...", "name": "export-reminders" }],
    "caldavCalendars": [{ "uuid": "...", "name": "Покупки" }]
  }
}
```

## Поля экспорта (ReminderItem)

| Поле             | Тип        | Описание                     |
|------------------|-----------|------------------------------|
| `id`             | String     | Уникальный идентификатор     |
| `listName`       | String     | Название списка              |
| `title`          | String     | Заголовок напоминания        |
| `notes`          | String?    | Заметки                      |
| `dueDate`        | Date?      | Срок выполнения              |
| `startDate`      | Date?      | Дата начала                  |
| `completionDate` | Date?      | Дата выполнения              |
| `creationDate`   | Date?      | Дата создания                |
| `modificationDate`| Date?     | Дата изменения               |
| `priority`       | Int        | Приоритет (0..9)             |
| `isCompleted`    | Bool       | Флаг выполнения              |
| `recurrenceRule` | String?    | Правило повторения           |
| `url`            | String?    | URL-ссылка                   |

## Структура проекта

```
Sources/ExportReminders/
├── ExportReminders.swift            # CLI (AsyncParsableCommand)
├── Models/
│   ├── ReminderItem.swift           # Модель напоминания
│   └── TasksOrg/                    # Модели Tasks.org
├── Services/
│   ├── ReminderServiceProtocol.swift   # Протокол сервиса
│   ├── EventKitReminderService.swift   # Реализация через EventKit
│   └── EventKitReminderServiceError.swift  # Ошибки
├── Exporters/
│   ├── ReminderExporterProtocol.swift  # Протокол экспортёра
│   ├── Format.swift                    # Enum форматов
│   ├── JSONExporter.swift              # Экспорт в JSON
│   └── CSVExporter.swift               # Экспорт в CSV
└── Converters/
    └── TasksOrgConverter.swift         # Конвертер [ReminderItem] → Tasks.org JSON
```

## Тестирование

```bash
# Все тесты
swift test

# Только CLI-тесты
swift test --filter CLITestSuite

# Только тесты экспортёров
swift test --filter JSONExporterTests
swift test --filter CSVExporterTests
swift test --filter TasksOrgConverterTests
```
