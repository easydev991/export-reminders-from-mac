# План: Export Reminders — выгрузка напоминаний из iCloud / приложения «Напоминания»

## 1. Цель

Создать инструмент для выгрузки (экспорта) всех напоминаний из Apple Reminders (iCloud) на macOS в читаемый формат: JSON, CSV, Markdown и/или ICS.

Репозиторий: `github.com/your-account/export-reminders` (пока пустой).

---

## 2. Подходы к решению

### A. Swift Command-Line Tool (EventKit) — **рекомендуется**

| Характеристика | Значение |
|---|---|
| Язык | Swift (SPM-пакет) |
| Фреймворк | `EventKit` / `EKEventStore` + `EKReminder` |
| Формат | Command-line tool |
| Сложность | Средняя |
| Плюсы | Официальный API; типизирован; можно собрать как бинарник; читабельный код |
| Минусы | Требуется подпись кода с entitlements; TCC-разрешение для CLI-тулзов сложнее, чем для GUI-приложений |

**Особенность macOS TCC**: Command-line инструменты **не получают** стандартный TCC-диалог. Чтобы получить доступ к напоминаниям, нужно либо:
- Запускать через приложение с GUI (минимальное SwiftUI-приложение, которое вызывает CLI), либо
- Подписать бинарник с `com.apple.security.personal-information.reminders` и воспользоваться `authopen` / `tccutil`, либо
- Сделать гибрид: минимальное GUI-приложение (даже без окна), которое через `XPC` или `Process` запускает логику экспорта от имени приложения.

**Более практичный вариант**: сделать **минимальное macOS-приложение** (можно без UI, `LSUIElement=true` в Info.plist), которое использует EventKit, и предоставить CLI-интерфейс через аргументы командной строки. Приложение получит TCC-диалог при первом запуске.

### B. AppleScript / osascript — **быстрый старт**

| Характеристика | Значение |
|---|---|
| Язык | AppleScript / JXA |
| Формат | `.applescript` или `.js` скрипт |
| Сложность | Низкая |
| Плюсы | Не требует компиляции, подписи, entitlements; работает «из коробки» |
| Минусы | Медленный (на больших коллекциях); нет типизации; сложнее поддерживать; ограниченный контроль ошибок |

> **Итог**: проект на Swift (подход A) — основной трек. AppleScript можно добавить как быстрый скрипт в `scripts/` для тех, кому не нужна компиляция.

---

## 3. Форматы экспорта

Для каждого формата — свой output-модуль:

| Формат | Назначение |
|---|---|
| **JSON** | Машиночитаемый, можно передавать в другие системы |
| **CSV** | Импорт в Excel/Google Sheets |
| **Markdown** | Человекочитаемый, можно архивировать в git |
| **ICS** (iCalendar) | Импорт в Календарь / другие календарные приложения (VTODO) |

---

## 4. Поля напоминаний для экспорта

Из `EKReminder` и AppleScript dictionary можно получить:

- `title` — заголовок
- `notes` — заметки
- `priority` — приоритет (1–5, 0 = none)
- `completed` — завершено ли
- `completionDate` — дата завершения
- `dueDate` — срок (due date)
- `creationDate` — дата создания
- `lastModifiedDate` — дата изменения
- `calendar.title` — название списка (категории)
- `alarms` — напоминания-будильники
- `recurrenceRules` — правила повторения
- `location` — геолокация (если привязана)
- `url` — URL (если есть)

---

## 5. Этапы реализации

### Этап 1: Исследование и прототип

- [x] Определиться с подходом (Swift + EventKit)
- [ ] Создать SPM-пакет (`swift package init --type executable`)
- [ ] Подключить `EventKit.framework` (входит в macOS SDK)
- [ ] Написать минимальный прототип: запрос доступа к напоминаниям, вывод count в консоль
- [ ] Проверить TCC: собрать, запустить, убедиться, что появляется диалог разрешения
- [ ] Подписать бинарник для ad-hoc distribution (или настроить Development signing)

### Этап 2: Модели данных (Domain Layer)

- [ ] Создать модель `ReminderItem` (value type) с полями из раздела 4
- [ ] Создать модель `ReminderList` (список/категория)
- [ ] Написать мапперы из `EKReminder` / `EKCalendar` в доменные модели
- [ ] Написать unit-тесты для мапперов
- [ ] Написать unit-тесты для моделей (Equatable, Codable для JSON)

### Этап 3: Data Layer — получение данных через EventKit

- [ ] Создать протокол `ReminderServiceProtocol`
- [ ] Реализовать `EventKitReminderService`, который:
  - Запрашивает доступ через `EKEventStore.requestAccess(to:)`
  - Загружает все списки (`calendars(for: .reminder)`)
  - Загружает все напоминания через `predicateForReminders(in:)`
  - Маппит в `ReminderItem` / `ReminderList`
- [ ] Написать unit-тесты с мок-сервисом
- [ ] Обработать граничные случаи: пустые списки, nil-поля, cancelled-доступ

### Этап 4: Output-модули (сериализация)

- [ ] Создать протокол `ReminderExporter` с методом `export(_ items:, to url:)`
- [ ] Реализовать `JSONExporter` — `JSONEncoder` с `.prettyPrinted`
- [ ] Реализовать `CSVExporter` — ручная запись CSV с экранированием полей
- [ ] Реализовать `MarkdownExporter` — группировка по спискам, Markdown-формат
- [ ] Реализовать `ICSExporter` — формат VTODO для iCalendar
- [ ] Написать unit-тесты для каждого экспортёра (проверка корректности вывода)

### Этап 5: CLI-интерфейс

- [ ] Создать структуру аргументов (использовать `ArgumentParser` от Apple)
  - `--format` (json, csv, md, ics) — обязательный
  - `--output` (путь к файлу или директории) — опциональный
  - `--list` (фильтр по имени списка) — опциональный
  - `--completed` (true/false) — опциональный фильтр
- [ ] Реализовать главную координацию: сервис → экспортёр → запись в файл
- [ ] Обработать ошибки (нет доступа, нет данных, ошибки записи)
- [ ] Вывести понятный help и error messages

### Этап 6: Сборка и подпись (macOS distribution)

- [ ] Настроить сборку через `xcodebuild` или `swift build`
- [ ] Настроить entitlements: `com.apple.security.personal-information.reminders`
- [ ] Hardened Runtime: включить, добавить exception если нужно
- [ ] Подписать бинарник (Development или ad-hoc)
- [ ] Создать `Makefile` или скрипт для сборки
- [ ] Написать инструкцию по настройке TCC (первый запуск, System Settings)

### Этап 7: README и документация

- [ ] README.md с описанием, примерами использования
- [ ] Инструкция по первому запуску (TCC permission)
- [ ] Примеры вывода для каждого формата
- [ ] Скрипт `scripts/export-reminders.applescript` как быстрый fallback

---

## 6. Граничные случаи и обработка ошибок

| Случай | Обработка |
|---|---|
| Нет доступа к напоминаниям | Чёткое сообщение с инструкцией по System Settings → Privacy → Reminders |
| Нет напоминаний | Пустой экспорт (корректный JSON `[]`, CSV с заголовками, пустой md) |
| Очень много напоминаний | Прогресс-бар (опционально), потоковая запись в файл |
| Спецсимволы в названиях | Экранирование в CSV, валидный JSON |
| Повторяющиеся напоминания | Каждое вхождение — отдельная запись |
| Удалённые списки | iCloud синхронизирует; показываем то, что доступно на устройстве |

---

## 7. Зависимости

**Внешние зависимости** — минимум:
- `swift-argument-parser` (от Apple) — для CLI-аргументов
- Всё остальное — Foundation + EventKit (macOS SDK)

```swift
// Package.swift
dependencies: [
    .package(url: "https://github.com/apple/swift-argument-parser", from: "1.2.0"),
]
```

---

## 8. Критерии завершения

- [ ] `swift build` проходит без ошибок
- [ ] `swift run export-reminders --format json --output ~/Desktop/reminders.json` выгружает все напоминания
- [ ] `swift run export-reminders --format csv --output ~/Desktop/reminders.csv` выгружает в CSV
- [ ] `swift run export-reminders --format md --output ~/Desktop/reminders.md` выгружает в Markdown
- [ ] `swift run export-reminders --format ics --output ~/Desktop/reminders.ics` выгружает в iCalendar
- [ ] Все unit-тесты проходят
- [ ] README написан с инструкциями

---

## 9. Альтернатива (JXA / AppleScript) — быстрый старт

Параллельно с основным Swift-треком можно добавить скрипт `scripts/export-reminders.js`, который экспортирует все напоминания в JSON через `osascript -l JavaScript`.

**Важно про JXA**: в экосистеме Apple свойства объектов (имя, даты, заметки) отдаются не как обычные значения, а как функции-указатели. Чтобы получить реальное значение, их **нужно вызывать со скобками `()`**.

```javascript
// export-reminders.js — запуск: osascript -l JavaScript export-reminders.js
const Reminders = Application('Reminders');
const lists = Reminders.lists();
const allItems = [];

lists.forEach(list => {
  const listName = list.name(); // функция-указатель → строка
  const reminders = list.reminders();

  reminders.forEach(r => {
    // Правила повторения могут быть недоступны — оборачиваем в try/catch
    let recurrenceRule = "";
    try {
      recurrenceRule = r.recurrence() || "";
    } catch(e) {
      recurrenceRule = "";
    }

    allItems.push({
      list: listName,
      title: r.name() || "",
      notes: r.body() || "",            // заметки к напоминанию
      dueDate: r.dueDate() ? r.dueDate().toString() : null,
      completed: r.completed() || false,
      priority: r.priority() || 0,
      recurrence: recurrenceRule         // например: "FREQ=DAILY;"
    });
  });
});

// Файл создаётся в текущей директории (рядом со скриптом)
const scriptPath = Path(__filename);
const scriptDir = scriptPath.toString().replace(/\/[^/]+$/, "");
const filePath = scriptDir + "/reminders_export.json";

const app = Application.currentApplication();
app.includeStandardAdditions = true;

// Создаём или перезаписываем файл
const file = app.openForAccess(Path(filePath), { writePermission: true });
app.setEof(file, { to: 0 });
app.write(JSON.stringify(allItems, null, 2), { to: file, as: "text" });
app.closeAccess(file);

console.log("Успешно экспортировано! Файл: " + filePath);
```

Без подписи, без компиляции, сразу работает. Но медленнее на больших наборах.

---
