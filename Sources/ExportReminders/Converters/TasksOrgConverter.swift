import CryptoKit
import Foundation

struct TasksOrgConverter {
    func convert(_ reminders: [ReminderItem]) throws -> Data {
        let now = Int64(Date().timeIntervalSince1970 * 1000)
        let accountUUID = deterministicUUID("export-reminders")
        let account = reminders.isEmpty
            ? nil
            : CaldavAccount(
                uuid: accountUUID,
                name: "export-reminders",
                accountType: 2
            )

        let calendars = buildCalendars(from: reminders, accountUUID: accountUUID)
        let wrappers = reminders.map { reminder in
            convertReminder(reminder, now: now)
        }

        let data = TasksOrgData(
            tasks: wrappers,
            caldavAccounts: account.map { [$0] } ?? [],
            caldavCalendars: calendars,
            places: [],
            tags: [],
            filters: [],
            taskListMetadata: [],
            taskAttachments: [],
            intPrefs: [:],
            longPrefs: [:],
            stringPrefs: [:],
            boolPrefs: [:],
            setPrefs: [:]
        )

        let backup = TasksOrgBackup(
            version: 150_704,
            timestamp: now,
            data: data
        )

        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .withoutEscapingSlashes]
        return try encoder.encode(backup)
    }
}

// MARK: - Private helpers

private func convertReminder(_ reminder: ReminderItem, now: Int64) -> TasksOrgTaskWrapper {
    let calUUID = deterministicUUID(reminder.listName)
    let caldavTask = CaldavTask(
        calendar: calUUID,
        remoteId: reminder.id,
        obj: nil,
        deleted: nil
    )

    let task = TasksOrgTask(
        title: reminder.title,
        dueDate: dateToUnixMs(reminder.dueDate),
        creationDate: dateToUnixMs(reminder.creationDate),
        modificationDate: dateToUnixMs(reminder.modificationDate),
        completionDate: reminder.isCompleted ? completionDateFrom(reminder, now: now) : nil,
        notes: appendURL(reminder.notes, reminder.url),
        recurrence: normalizeRecurrence(reminder.recurrenceRule),
        remoteId: reminder.id
    )

    return TasksOrgTaskWrapper(
        task: task,
        alarms: [],
        geofences: [],
        tags: [],
        comments: [],
        attachments: [],
        caldavTasks: [caldavTask]
    )
}

private func buildCalendars(from reminders: [ReminderItem], accountUUID: String) -> [CaldavCalendar] {
    let uniqueLists = Array(Set(reminders.map(\.listName)))
    return uniqueLists.map { name in
        CaldavCalendar(
            uuid: deterministicUUID(name),
            name: name,
            color: colorForList(name),
            account: accountUUID
        )
    }
}

private func dateToUnixMs(_ date: Date?) -> Int64? {
    guard let date else { return nil }
    return Int64(date.timeIntervalSince1970 * 1000)
}

private func completionDateFrom(_ reminder: ReminderItem, now: Int64) -> Int64 {
    if let d = reminder.completionDate { return Int64(d.timeIntervalSince1970 * 1000) }
    if let d = reminder.modificationDate { return Int64(d.timeIntervalSince1970 * 1000) }
    return now
}

private func appendURL(_ notes: String?, _ url: String?) -> String? {
    guard let url else { return notes }
    if let notes { return "\(notes)\n\nURL: \(url)" }
    return "URL: \(url)"
}

private func normalizeRecurrence(_ rule: String?) -> String? {
    guard let rule else { return nil }
    guard let rruleRange = rule.range(of: "RRULE") else { return nil }
    var substring = String(rule[rruleRange.upperBound...])
    // Tasks.org feeds the value directly into ical4j's RRule parser, which only
    // accepts `FREQ=...` or the legacy `RRULE:FREQ=...` form. The space that
    // EventKit inserts (`RRULE FREQ=...`) is invalid, so drop the prefix and any
    // trailing separator (colon or space).
    if substring.hasPrefix(":") || substring.hasPrefix(" ") {
        substring = String(substring.dropFirst())
    }
    guard substring.localizedUppercase.contains("FREQ=") else { return nil }
    return substring
}

private func deterministicUUID(_ input: String) -> String {
    let digest = SHA256.hash(data: Data(input.utf8))
    var bytes = Array(digest.prefix(16))
    bytes[6] = (bytes[6] & 0x0F) | 0x50 // version 5
    bytes[8] = (bytes[8] & 0x3F) | 0x80 // variant RFC 4122
    return String(format: "%02X%02X%02X%02X-%02X%02X-%02X%02X-%02X%02X-%02X%02X%02X%02X%02X%02X",
                  bytes[0], bytes[1], bytes[2], bytes[3],
                  bytes[4], bytes[5],
                  bytes[6], bytes[7],
                  bytes[8], bytes[9],
                  bytes[10], bytes[11], bytes[12], bytes[13], bytes[14], bytes[15])
}

private func colorForList(_ name: String) -> Int {
    let digest = SHA256.hash(data: Data(name.utf8))
    let bytes = Array(digest.prefix(4))
    var value: UInt32 = 0
    for byte in bytes {
        value = (value << 8) | UInt32(byte)
    }
    value |= 0xFF00_0000 // alpha
    return Int(Int32(bitPattern: value)) // signed 32-bit, as expected by Kotlin Int
}

extension TasksOrgConverter: ReminderExporterProtocol {
    func export(_ reminders: [ReminderItem], to url: URL) throws {
        let data = try convert(reminders)
        try data.write(to: url)
    }
}
