## Why

Текущие форматы экспорта (JSON/CSV) несовместимы с Tasks.org — открытым Android-приложением для задач, поддерживающим импорт только через собственный backup-формат JSON. Пользователи, мигрирующие с Apple Reminders на Tasks.org, вынуждены конвертировать данные вручную. Добавление прямого экспорта в формат Tasks.org устраняет этот разрыв.

## What Changes

- Новый конвертер `TasksOrgConverter`, работающий **поверх универсального JSON** (получает `[ReminderItem]`, возвращает Tasks.org-совместимый JSON)
- Новый формат `tasks-org` в CLI-перечислении `Format` — при выборе внутренне вызывает конвертер после получения напоминаний
- Конвертер также доступен как **утилита парсинга JSON-файла**: можно передать уже экспортированный универсальный JSON и получить Tasks.org JSON на выходе
- Выходной файл: Tasks.org backup JSON с обёрткой `{version, timestamp, data: {tasks, caldavCalendars, caldavAccounts, ...}}`
- Конвертация дат: ISO 8601 → Unix timestamp в миллисекундах (Long)
- Маппинг приоритета: шкала Apple EKReminderPriority (0=none, 1=high, 5=medium, 9=low) → Tasks.org (0=HIGH, 1=MED, 2=LOW, 3=NONE)
- Преобразование `isCompleted: Bool` → `completionDate: Long?` (включается только для выполненных задач, значение — из `completionDate` / `modificationDate` / текущего timestamp)
- Привязка списков Apple Reminders (`listName`) к Caldav-календарям Tasks.org
- Поле `url` напоминания добавляется в конец `notes` (как текстовая ссылка)
- Пустые секции-заглушки (`places`, `tags`, `filters`, `prefs` и др.) для совместимости с парсером Tasks.org
- **TDD**: тесты пишутся до реализации, отталкиваясь от спецификации

### Исправления совместимости с нативным экспортом Tasks.org (по результатам сравнения)

- Поле выполнения: `completed` → `completionDate`, включается только при фактическом выполнении задачи (не `0`)
- Даты создания/изменения: `created` → `creationDate`, `modified` → `modificationDate`
- Отсутствие даты выполнения: `dueDate` опускается, если нет значения, вместо `dueDate: 0`
- Обёртка задачи: добавление пустых массивов `alarms`, `geofences`, `tags`, `comments`, `attachments`, `caldavTasks` на уровне задачи
- `caldavTasks` переносится из `task` на уровень обёртки задачи
- `caldavTasks.remoteId` генерируется как строковый идентификатор на основе `ReminderItem.id` (соответствует типу `String?` в Tasks.org и нативному экспорту)
- Удаление неиспользуемых приложением полей из `task`: `readOnly`, `deleted`, `estimatedSeconds`, `elapsedSeconds`, `hideUntil`, `timerStart`, `repeatFrom`, `ringFlags`, `importance` (если не используется), `caldavTasks`
- Версия backup-формата обновляется с `157` до `150704`
- `caldavAccounts`: использование `accountType = 2` (TYPE_LOCAL) без `url`/`lastSync` — как в рабочем примере нативного экспорта Tasks.org для локальных данных
- `caldavCalendars.color`: использование реального цвета календаря в формате Android `Color` (signed 32-bit int, alpha=0xFF) вместо `0`
- `recurrence`: нормализация `EKRecurrenceRule.description` до чистого iCalendar-правила (`FREQ=DAILY;INTERVAL=12`) перед записью; Tasks.org/ical4j принимают также legacy-форму `RRULE:FREQ=...`, но отвергают `RRULE FREQ=...` с пробелом, которую возвращает EventKit; правило без `FREQ=` (в любом регистре) не записывается

**Примечание по повторному импорту**: Tasks.org может сохранить у существующих задач старое значение `recurrence` из предыдущего импорта. Если старое значение было в неверном формате (`"RRULE FREQ=..."` с пробелом или `"RRULE"` без `FREQ=`), открытие такой задачи будет падать даже после импорта исправленного файла. Перед повторным импортом рекомендуется очистить хранилище приложения Tasks.org или удалить аккаунт `export-reminders`.

## Capabilities

### New Capabilities

- `tasks-org-export`: Экспорт напоминаний в формат Tasks.org backup JSON с конвертацией дат, приоритетов и статуса выполнения, маппингом списков в Caldav-календари и корректной структурой конверта.

### Modified Capabilities

- `tasks-org-export`: Исправление совместимости с нативным backup-форматом Tasks.org: `completionDate` вместо `completed`, `creationDate`/`modificationDate` вместо `created`/`modified`, опускание `dueDate` при отсутствии значения, обновлённая структура обёртки задачи, версия backup `150704`, локальный аккаунт с `accountType = 2`.
- `cli-interface`: Добавление значения `tasks-org` в перечисление `Format` и дефолтного имени выходного файла `reminders_export_tasks_org.json`.

## Impact

- **Изменённый файл**: `Sources/ExportReminders/Converters/TasksOrgConverter.swift` — корректировка маппинга полей, структуры обёртки задачи и версии backup
- **Изменённые модели**: `Sources/ExportReminders/Models/TasksOrg/` — переименование полей (`creationDate`, `modificationDate`, `completionDate`), перенос `caldavTasks` на уровень обёртки, обновление `version` до `150704`, `CaldavAccount` с `accountType = 2` (TYPE_LOCAL)
- **Изменённый файл**: `Sources/ExportReminders/Exporters/Format.swift` — новое значение `tasks-org`
- **Изменённый файл**: `Sources/ExportReminders/ExportReminders.swift` — маппинг `Format.tasksOrg` → вызов конвертера + запись результата
- **Новые/обновлённые тесты**: `Tests/ExportRemindersTests/Converters/TasksOrgConverterTests.swift` — тесты на исправленную совместимость с Tasks.org
- **Не затрагивает**: `ReminderItem`, `JSONExporter`, `CSVExporter`, `EventKitReminderService`
