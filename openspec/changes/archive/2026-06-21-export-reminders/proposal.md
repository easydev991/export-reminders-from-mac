## Why

Экспорт 1 000+ напоминаний из Apple Reminders через AppleScript/JXA занимает минуты из-за IPC-вызовов к приложению «Напоминания». Swift + EventKit читает базу Reminders напрямую через нативный фреймворк без межпроцессных вызовов — выгрузка за 1–2 секунды. Это даёт быстрый, автономный CLI-инструмент для резервного копирования, миграции и аналитики напоминаний.

## What Changes

- Добавлены доменные модели `ReminderItem` и `ReminderList` (Equatable, Codable)
- Добавлен EventKit-сервис для чтения всех напоминаний и списков из системного хранилища
- Добавлены два формата экспорта: JSON (канонический, для полного сохранения данных) и CSV (табличный, для импорта в сторонние приложения)
- Добавлен CLI-интерфейс на `swift-argument-parser` с фильтрацией по списку и статусу выполнения
- Оставлены AppleScript/JXA-скрипты как fallback для пользователей, не собирающих бинарник

## Capabilities

### New Capabilities

- `domain-models`: Основные модели данных — ReminderItem (12 полей) и ReminderList. Codable для сериализации, Equatable для тестирования.
- `eventkit-integration`: Доступ к Apple Reminders через EventKit — запрос разрешения, чтение календарей и напоминаний, маппинг EKReminder/EKCalendar → доменные модели, обработка ошибок (доступ запрещён, iCloud-ошибки).
- `json-export`: Экспорт напоминаний в JSON — валидная структура, корректная сериализация всех полей, включая опциональные и даты.
- `csv-export`: Экспорт напоминаний в CSV с универсальными названиями колонок для импорта в сторонние приложения (TickTick, Microsoft To Do, Notion). Экранирование спецсимволов, формат дат ISO 8601.
- `cli-interface`: Интерфейс командной строки — аргументы `--format` (json/csv), `--output` (путь к файлу), `--list` (фильтр по имени списка), `--completed` (фильтр по статусу).

### Modified Capabilities

<!-- Нет изменяемых существующих capability — проект создаётся с нуля -->

## Impact

- **Новый код**: Sources/ExportReminders/ (Models, Services, Exporters, CLI-точка входа)
- **Тесты**: Tests/ExportRemindersTests/ (unit-тесты для всех модулей)
- **Сборка**: Package.swift с зависимостью `swift-argument-parser` и системным `EventKit.framework`
- **Безопасность**: Entitlements `com.apple.security.personal-information.reminders` для доступа к Reminders
- **Fallback**: scripts/export-reminders.js и scripts/export-reminders.applescript сохранены без изменений
