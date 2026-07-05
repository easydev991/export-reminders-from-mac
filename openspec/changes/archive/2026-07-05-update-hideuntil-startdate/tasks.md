## 1. Модель ReminderItem

- [x] 1.1 Добавить поле `startDate: Date?` в `Sources/ExportReminders/Models/ReminderItem.swift` после `dueDate`.
- [x] 1.2 Обновить инициализатор `ReminderItem`, добавив параметр `startDate: Date? = nil`.
- [x] 1.3 Дополнить `Tests/ExportRemindersTests/ReminderItemTests.swift` тестами кодирования/декодирования `startDate` и отсутствия `startDate` в JSON.

## 2. Чтение startDate из EventKit

- [x] 2.1 В `Sources/ExportReminders/Services/EventKitReminderService.swift` в `mapToReminderItem` добавить чтение `ekReminder.startDateComponents?.date`.
- [x] 2.2 Передать прочитанное значение в `ReminderItem(startDate: ...)`.
- [x] 2.3 Дополнить `Tests/ExportRemindersTests/EventKitReminderServiceTests.swift` тестами для `startDate` и его отсутствия.

## 3. Модель TasksOrgTask

- [x] 3.1 Добавить поле `hideUntil: Int64?` в `Sources/ExportReminders/Models/TasksOrg/TasksOrgTask.swift` после `dueDate`.
- [x] 3.2 Создать `Tests/ExportRemindersTests/TasksOrgTaskTests.swift` с тестами кодирования/декодирования `hideUntil` и его отсутствия при `nil`.

## 4. Конвертер TasksOrg

- [x] 4.1 В `Sources/ExportReminders/Converters/TasksOrgConverter.swift` в `convertReminder` заполнять `hideUntil: dateToUnixMs(reminder.startDate ?? reminder.dueDate)`.
- [x] 4.2 Дополнить `Tests/ExportRemindersTests/TasksOrgConverterTests.swift` сценариями: `hideUntil` из `startDate`, fallback на `dueDate`, отсутствие при отсутствии обеих дат.
- [x] 4.3 Обновить `Tests/ExportRemindersTests/Fixtures/ReminderItemFixtures.swift`: добавить `startDate` в `sample` и добавить фикстуру без `startDate` при необходимости.

## 5. CSV-экспортёр

- [x] 5.1 В `Sources/ExportReminders/Exporters/CSVExporter.swift` вставить `"startDate"` в массив `headers` между `"dueDate"` и `"completionDate"`.
- [x] 5.2 В `csvRow(for:)` вставить поле `startDate` в том же порядке.
- [x] 5.3 Обновить `Tests/ExportRemindersTests/ExporterTests.swift`:
  - `csvExporterHeaders`: ожидаемая строка с `startDate`.
  - `csvExporterOverwritesExistingFile`: ожидаемая строка с `startDate`.
  - `csvExporterNilFields`: ожидаемое количество колонок 13 вместо 12.
  - `jsonExporterOmitsNilFields`: добавить проверку отсутствия `"startDate"`.

## 6. Регрессионные проверки и качество

- [x] 6.1 Запустить `swift test` и убедиться, что все тесты проходят.
- [x] 6.2 Запустить `swiftformat .`.
- [x] 6.3 Запустить `periphery scan --targets ExportReminders` и устранить предупреждения.
- [x] 6.4 Ручная проверка: экспортировать реальные напоминания и убедиться, что в tasks.org JSON появилось `hideUntil`.
