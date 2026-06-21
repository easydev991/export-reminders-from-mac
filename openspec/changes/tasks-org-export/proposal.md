## Why

Текущие форматы экспорта (JSON/CSV) несовместимы с Tasks.org — открытым Android-приложением для задач, поддерживающим импорт только через собственный backup-формат JSON. Пользователи, мигрирующие с Apple Reminders на Tasks.org, вынуждены конвертировать данные вручную. Добавление прямого экспорта в формат Tasks.org устраняет этот разрыв.

## What Changes

- Новый конвертер `TasksOrgConverter`, работающий **поверх универсального JSON** (получает `[ReminderItem]`, возвращает Tasks.org-совместимый JSON)
- Новый формат `tasks-org` в CLI-перечислении `Format` — при выборе внутренне вызывает конвертер после получения напоминаний
- Конвертер также доступен как **утилита парсинга JSON-файла**: можно передать уже экспортированный универсальный JSON и получить Tasks.org JSON на выходе
- Выходной файл: Tasks.org backup JSON с обёрткой `{version, timestamp, data: {tasks, caldavCalendars, caldavAccounts, ...}}`
- Конвертация дат: ISO 8601 → Unix timestamp в миллисекундах (Long)
- Маппинг приоритета: шкала Apple EKReminderPriority (0=none, 1=high, 5=medium, 9=low) → Tasks.org (0=HIGH, 1=MED, 2=LOW, 3=NONE)
- Преобразование `isCompleted: Bool` → `completionDate: Long` (true → текущий timestamp, false → 0)
- Привязка списков Apple Reminders (`listName`) к Caldav-календарям Tasks.org
- Поле `url` напоминания добавляется в конец `notes` (как текстовая ссылка)
- Пустые секции-заглушки (`places`, `tags`, `filters`, `prefs` и др.) для совместимости с парсером Tasks.org
- **TDD**: тесты пишутся до реализации, отталкиваясь от спецификации

## Capabilities

### New Capabilities

- `tasks-org-export`: Экспорт напоминаний в формат Tasks.org backup JSON с конвертацией дат, приоритетов и статуса выполнения, маппингом списков в Caldav-календари и корректной структурой конверта.

### Modified Capabilities

- `cli-interface`: Добавление значения `tasks-org` в перечисление `Format` и дефолтного имени выходного файла `reminders_export_tasks_org.json`.

## Impact

- **Новый файл**: `Sources/ExportReminders/Converters/TasksOrgConverter.swift` — конвертер `[ReminderItem]` → Tasks.org JSON
- **Новые модели**: `Sources/ExportReminders/Models/TasksOrg/` — структуры для Tasks.org JSON (обёртка `TasksOrgBackup`, `TasksOrgTask`, `CaldavCalendar`, `CaldavAccount`, `CaldavTask`)
- **Изменённый файл**: `Sources/ExportReminders/Exporters/Format.swift` — новое значение `tasks-org`
- **Изменённый файл**: `Sources/ExportReminders/ExportReminders.swift` — маппинг `Format.tasksOrg` → вызов конвертера + запись результата
- **Новые тесты**: `Tests/ExportRemindersTests/Converters/TasksOrgConverterTests.swift` (TDD — тесты пишутся до реализации конвертера)
- **Не затрагивает**: `ReminderItem`, `JSONExporter`, `CSVExporter`, `EventKitReminderService`
