@testable import ExportReminders
import Foundation
import Testing

// MARK: - Helpers

private let iso = ISO8601DateFormatter()

private func date(_ string: String) -> Date {
    iso.date(from: string)!
}

/// Парсит JSON-данные конвертера в словарь.
private func parsed(_ data: Data) throws -> [String: Any] {
    try JSONSerialization.jsonObject(with: data) as! [String: Any]
}

/// Извлекает массив tasks из корня JSON.
private func tasksArray(_ root: [String: Any]) throws -> [[String: Any]] {
    let data = try #require(root["data"] as? [String: Any])
    return try #require(data["tasks"] as? [[String: Any]])
}

/// Извлекает первую обёртку задачи.
private func firstWrapper(_ root: [String: Any]) throws -> [String: Any] {
    let arr = try tasksArray(root)
    return try #require(arr.first)
}

/// Извлекает task из обёртки { "task": {...} }.
private func taskFromWrapper(_ wrapper: [String: Any]) throws -> [String: Any] {
    try #require(wrapper["task"] as? [String: Any])
}

/// Извлекает первый task из корня JSON.
private func firstTask(_ root: [String: Any]) throws -> [String: Any] {
    try taskFromWrapper(firstWrapper(root))
}

/// Извлекает календари из data.
private func calendarsArray(_ root: [String: Any]) throws -> [[String: Any]] {
    let data = try #require(root["data"] as? [String: Any])
    return try #require(data["caldavCalendars"] as? [[String: Any]])
}

/// Извлекает аккаунты из data.
private func accountsArray(_ root: [String: Any]) throws -> [[String: Any]] {
    let data = try #require(root["data"] as? [String: Any])
    return try #require(data["caldavAccounts"] as? [[String: Any]])
}

// MARK: - Тесты

@Test("Пустой массив напоминаний")
func emptyReminders() throws {
    let data = try TasksOrgConverter().convert([])
    let root = try parsed(data)

    #expect(root["version"] as? Int == 150_704)
    let timestamp = try #require(root["timestamp"] as? Int64)
    #expect(timestamp > 0)

    #expect(try tasksArray(root).isEmpty)
    #expect(try accountsArray(root).isEmpty)
    #expect(try calendarsArray(root).isEmpty)

    let taskData = try #require(root["data"] as? [String: Any])

    let arraySections = ["tags", "filters", "places", "taskListMetadata", "taskAttachments"]
    for key in arraySections {
        #expect(try (#require(taskData[key] as? [String])).isEmpty)
    }

    let dictSections = ["intPrefs", "longPrefs", "stringPrefs", "boolPrefs", "setPrefs"]
    for key in dictSections {
        #expect(try (#require(taskData[key] as? [String: Any])).isEmpty)
    }
}

@Test("Прямой маппинг полей")
func directFieldMapping() throws {
    let reminder = ReminderItem(
        id: "rem-001",
        listName: "Покупки",
        title: "Купить молоко",
        notes: "Безлактозное",
        dueDate: date("2026-06-25T10:00:00Z"),
        completionDate: nil,
        creationDate: date("2026-06-20T08:00:00Z"),
        modificationDate: date("2026-06-21T12:00:00Z"),
        priority: 5,
        isCompleted: false,
        recurrenceRule: "EKRecurrenceRule <0xabc> RRULE FREQ=WEEKLY;INTERVAL=1",
        url: "https://example.com"
    )

    let data = try TasksOrgConverter().convert([reminder])
    let root = try parsed(data)
    let task = try firstTask(root)

    #expect(task["title"] as? String == "Купить молоко")
    #expect(task["recurrence"] as? String == "FREQ=WEEKLY;INTERVAL=1")
    #expect(task["remoteId"] as? String == "rem-001")

    #expect(task["dueDate"] as? Int64 == Int64(date("2026-06-25T10:00:00Z").timeIntervalSince1970 * 1000))
    #expect(task["creationDate"] as? Int64 == Int64(date("2026-06-20T08:00:00Z").timeIntervalSince1970 * 1000))
    #expect(task["modificationDate"] as? Int64 == Int64(date("2026-06-21T12:00:00Z").timeIntervalSince1970 * 1000))
}

@Test("Даты в Unix-миллисекундах, nil опускаются")
func dateConversionAndOmission() throws {
    let reminder = ReminderItem(
        id: "dates-1",
        listName: "Список",
        title: "Даты",
        dueDate: date("2026-01-01T00:00:00Z"),
        creationDate: date("2026-01-02T00:00:00Z"),
        modificationDate: date("2026-01-03T00:00:00Z"),
        isCompleted: false
    )

    let data = try TasksOrgConverter().convert([reminder])
    let root = try parsed(data)
    let task = try firstTask(root)

    #expect(task["dueDate"] as? Int64 == Int64(date("2026-01-01T00:00:00Z").timeIntervalSince1970 * 1000))
    #expect(task["creationDate"] as? Int64 == Int64(date("2026-01-02T00:00:00Z").timeIntervalSince1970 * 1000))
    #expect(task["modificationDate"] as? Int64 == Int64(date("2026-01-03T00:00:00Z").timeIntervalSince1970 * 1000))

    let reminderNilDates = ReminderItem(
        id: "no-dates",
        listName: "Список",
        title: "Без дат",
        isCompleted: false
    )
    let dataNil = try TasksOrgConverter().convert([reminderNilDates])
    let taskNil = try firstTask(parsed(dataNil))

    #expect(taskNil["dueDate"] == nil)
    #expect(taskNil["creationDate"] == nil)
    #expect(taskNil["modificationDate"] == nil)
}

@Test("isCompleted false → completionDate отсутствует")
func completionDateAbsentWhenNotCompleted() throws {
    let reminder = ReminderItem(id: "c-false", listName: "L", title: "T", isCompleted: false)
    let task = try firstTask(parsed(TasksOrgConverter().convert([reminder])))
    #expect(task["completionDate"] == nil)
}

@Test("isCompleted true + completionDate → completionDate присутствует")
func completionDateFromCompletionDate() throws {
    let completion = date("2026-06-25T12:00:00Z")
    let reminder = ReminderItem(
        id: "c-comp",
        listName: "L",
        title: "T",
        completionDate: completion,
        modificationDate: date("2026-06-21T08:00:00Z"),
        isCompleted: true
    )
    let task = try firstTask(parsed(TasksOrgConverter().convert([reminder])))
    let expected = Int64(completion.timeIntervalSince1970 * 1000)
    #expect(task["completionDate"] as? Int64 == expected)
}

@Test("isCompleted true, completionDate nil, modificationDate задана → completionDate = modificationDate ms")
func completionDateFromModificationDate() throws {
    let modified = date("2026-06-21T08:00:00Z")
    let reminder = ReminderItem(
        id: "c-mod",
        listName: "L",
        title: "T",
        completionDate: nil,
        modificationDate: modified,
        isCompleted: true
    )
    let task = try firstTask(parsed(TasksOrgConverter().convert([reminder])))
    let expected = Int64(modified.timeIntervalSince1970 * 1000)
    #expect(task["completionDate"] as? Int64 == expected)
}

@Test("isCompleted true, обе даты nil → completionDate > 0")
func completionDateFallbackToNow() throws {
    let before = Int64(Date().timeIntervalSince1970 * 1000)
    let reminder = ReminderItem(
        id: "c-fallback",
        listName: "L",
        title: "T",
        isCompleted: true
    )
    let task = try firstTask(parsed(TasksOrgConverter().convert([reminder])))
    let after = Int64(Date().timeIntervalSince1970 * 1000)
    let completed = try #require(task["completionDate"] as? Int64)
    #expect(completed > before - 1000)
    #expect(completed <= after + 1000)
}

@Test("dueDate nil → поле отсутствует")
func dueDateOmittedWhenNil() throws {
    let reminder = ReminderItem(
        id: "no-due",
        listName: "L",
        title: "T",
        dueDate: nil,
        isCompleted: false
    )
    let task = try firstTask(parsed(TasksOrgConverter().convert([reminder])))
    #expect(task["dueDate"] == nil)
}

@Test("Структура обёртки задачи")
func taskWrapperStructure() throws {
    let reminder = ReminderItem(id: "wrap-1", listName: "L", title: "T", isCompleted: false)
    let wrapper = try firstWrapper(parsed(TasksOrgConverter().convert([reminder])))

    #expect(wrapper["alarms"] as? [Any] != nil)
    #expect(wrapper["geofences"] as? [Any] != nil)
    #expect(wrapper["tags"] as? [Any] != nil)
    #expect(wrapper["comments"] as? [Any] != nil)
    #expect(wrapper["attachments"] as? [Any] != nil)
    #expect(wrapper["caldavTasks"] as? [[String: Any]] != nil)

    let task = try taskFromWrapper(wrapper)
    #expect(task["caldavTasks"] == nil)
}

@Test("CaldavTask.remoteId — строковый идентификатор")
func stringRemoteId() throws {
    let reminder = ReminderItem(id: "rem-001", listName: "L", title: "T", isCompleted: false)
    let wrapper = try firstWrapper(parsed(TasksOrgConverter().convert([reminder])))
    let caldavTasks = try #require(wrapper["caldavTasks"] as? [[String: Any]])
    #expect(caldavTasks.count == 1)
    let ct = try #require(caldavTasks.first)
    #expect(ct["remoteId"] as? String == "rem-001")
    #expect(ct["object"] == nil)
    #expect(ct["deleted"] == nil)
}

@Test("Два listName → два календаря, один аккаунт")
func twoLists() throws {
    let reminders = [
        ReminderItem(id: "a1", listName: "Покупки", title: "A", isCompleted: false),
        ReminderItem(id: "b1", listName: "Работа", title: "B", isCompleted: false),
    ]
    let root = try parsed(TasksOrgConverter().convert(reminders))

    let accounts = try accountsArray(root)
    #expect(accounts.count == 1)
    let account = try #require(accounts.first)
    #expect(account["name"] as? String == "export-reminders")
    #expect(account["accountType"] as? Int == 2)

    let calendars = try calendarsArray(root)
    #expect(calendars.count == 2)
    let names = calendars.compactMap { $0["name"] as? String }.sorted()
    #expect(names == ["Покупки", "Работа"])

    let accountUuid = try #require(account["uuid"] as? String)
    for cal in calendars {
        #expect(cal["account"] as? String == accountUuid)
        #expect(cal["color"] as? Int != 0)
    }

    let wrappers = try tasksArray(root)
    #expect(wrappers.count == 2)
    for wrapper in wrappers {
        let ctArr = try #require(wrapper["caldavTasks"] as? [[String: Any]])
        let ct = try #require(ctArr.first)
        let calUuid = try #require(ct["calendar"] as? String)
        #expect(calendars.contains { ($0["uuid"] as? String) == calUuid })
    }
}

@Test("Несколько напоминаний из одного listName → один календарь")
func sameListSingleCalendar() throws {
    let reminders = [
        ReminderItem(id: "s1", listName: "Здоровье", title: "Витамины", isCompleted: false),
        ReminderItem(id: "s2", listName: "Здоровье", title: "Спорт", isCompleted: false),
        ReminderItem(id: "s3", listName: "Здоровье", title: "Сон", isCompleted: false),
    ]
    let root = try parsed(TasksOrgConverter().convert(reminders))

    let calendars = try calendarsArray(root)
    #expect(calendars.count == 1)
    #expect(calendars.first?["name"] as? String == "Здоровье")

    let wrappers = try tasksArray(root)
    #expect(wrappers.count == 3)

    let calUuid = try #require(calendars.first?["uuid"] as? String)
    for wrapper in wrappers {
        let ctArr = try #require(wrapper["caldavTasks"] as? [[String: Any]])
        let ct = try #require(ctArr.first)
        #expect(ct["calendar"] as? String == calUuid)
    }
}

@Test("URL добавляется к заметкам корректно")
func urlAppending() throws {
    let withNotes = ReminderItem(
        id: "url1", listName: "L", title: "T",
        notes: "Заметка", isCompleted: false, url: "https://example.com"
    )
    let task1 = try firstTask(parsed(TasksOrgConverter().convert([withNotes])))
    #expect(task1["notes"] as? String == "Заметка\n\nURL: https://example.com")

    let noNotes = ReminderItem(
        id: "url2", listName: "L", title: "T",
        notes: nil, isCompleted: false, url: "https://example.com"
    )
    let task2 = try firstTask(parsed(TasksOrgConverter().convert([noNotes])))
    #expect(task2["notes"] as? String == "URL: https://example.com")

    let noUrl = ReminderItem(
        id: "url3", listName: "L", title: "T",
        notes: "Заметка без ссылки", isCompleted: false, url: nil
    )
    let task3 = try firstTask(parsed(TasksOrgConverter().convert([noUrl])))
    #expect(task3["notes"] as? String == "Заметка без ссылки")
}

@Test("В task отсутствуют неиспользуемые приложением поля")
func unusedFieldsAbsent() throws {
    let reminder = ReminderItem(
        id: "fields-1",
        listName: "L",
        title: "T",
        priority: 5,
        isCompleted: false
    )
    let task = try firstTask(parsed(TasksOrgConverter().convert([reminder])))

    let unused = [
        "readOnly", "deleted", "estimatedSeconds", "elapsedSeconds",
        "hideUntil", "timerStart", "repeatFrom", "ringFlags",
        "importance", "caldavTasks",
    ]
    for key in unused {
        #expect(task[key] == nil, "поле \(key) не должно присутствовать")
    }
}

@Test("Аккаунт локальный (TYPE_LOCAL)")
func localAccountType() throws {
    let reminder = ReminderItem(id: "acc-1", listName: "L", title: "T", isCompleted: false)
    let root = try parsed(TasksOrgConverter().convert([reminder]))
    let accounts = try accountsArray(root)
    #expect(accounts.count == 1)
    let account = try #require(accounts.first)
    #expect(account["accountType"] as? Int == 2)
    #expect(account["url"] == nil)
    #expect(account["lastSync"] == nil)
}

@Test("recurrenceRule с RRULE нормализуется")
func recurrenceRuleWithRRULE() throws {
    let reminder = ReminderItem(
        id: "rrule-1",
        listName: "L",
        title: "T",
        isCompleted: false,
        recurrenceRule: "EKRecurrenceRule <0x1234567890abcdef> RRULE FREQ=DAILY;INTERVAL=12"
    )
    let task = try firstTask(parsed(TasksOrgConverter().convert([reminder])))
    #expect(task["recurrence"] as? String == "FREQ=DAILY;INTERVAL=12")
}

@Test("recurrenceRule с RRULE: нормализуется")
func recurrenceRuleWithRRULEColon() throws {
    let reminder = ReminderItem(
        id: "rrule-1b",
        listName: "L",
        title: "T",
        isCompleted: false,
        recurrenceRule: "EKRecurrenceRule <0x1234567890abcdef> RRULE:FREQ=DAILY;INTERVAL=12"
    )
    let task = try firstTask(parsed(TasksOrgConverter().convert([reminder])))
    #expect(task["recurrence"] as? String == "FREQ=DAILY;INTERVAL=12")
}

@Test("recurrenceRule без FREQ опускается")
func recurrenceRuleWithoutFREQ() throws {
    let reminder = ReminderItem(
        id: "rrule-3",
        listName: "L",
        title: "T",
        isCompleted: false,
        recurrenceRule: "EKRecurrenceRule <0x...x> RRULE"
    )
    let task = try firstTask(parsed(TasksOrgConverter().convert([reminder])))
    #expect(task["recurrence"] == nil)
}

@Test("recurrenceRule без RRULE/FREQ опускается")
func recurrenceRuleWithoutRRULE() throws {
    let reminder = ReminderItem(
        id: "rrule-2",
        listName: "L",
        title: "T",
        isCompleted: false,
        recurrenceRule: "FREQ=DAILY;INTERVAL=12"
    )
    let task = try firstTask(parsed(TasksOrgConverter().convert([reminder])))
    #expect(task["recurrence"] == nil)
}

@Test("recurrenceRule с freq= в нижнем регистре сохраняется")
func recurrenceRuleWithLowercaseFreq() throws {
    let reminder = ReminderItem(
        id: "rrule-4",
        listName: "L",
        title: "T",
        isCompleted: false,
        recurrenceRule: "EKRecurrenceRule <0x...x> RRULE freq=DAILY;INTERVAL=12"
    )
    let task = try firstTask(parsed(TasksOrgConverter().convert([reminder])))
    #expect(task["recurrence"] as? String == "freq=DAILY;INTERVAL=12")
}

@Test("Цвет календаря — signed 32-bit int")
func calendarColorSignedInt32() throws {
    let reminder = ReminderItem(id: "col-1", listName: "Цветной список", title: "T", isCompleted: false)
    let root = try parsed(TasksOrgConverter().convert([reminder]))
    let calendars = try calendarsArray(root)
    #expect(calendars.count == 1)
    let calendar = try #require(calendars.first)
    let color = try #require(calendar["color"] as? Int)
    #expect(color != 0)
    #expect(color >= Int32.min && color <= Int32.max)
    // Deterministic for same listName: matches Int32(bitPattern: UInt32) with alpha=0xFF
    #expect(color == -16_477_567)
}
