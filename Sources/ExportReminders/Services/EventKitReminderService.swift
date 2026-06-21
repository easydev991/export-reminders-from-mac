@preconcurrency import EventKit
import Foundation

/// Сервис, читающий напоминания из системного хранилища Apple Reminders через EventKit.
final class EventKitReminderService: @unchecked Sendable, ReminderServiceProtocol {
    private let store: EKEventStore

    init(store: EKEventStore = .init()) {
        self.store = store
    }

    // MARK: - ReminderServiceProtocol

    func fetchAllReminders() async throws -> [ReminderItem] {
        try await requestAccess()
        let predicate = store.predicateForReminders(in: nil)
        let ekReminders = try await fetchReminders(with: predicate)
        return ekReminders.map { mapToReminderItem($0) }
    }

    // MARK: - Private

    private func requestAccess() async throws {
        let granted = try await store.requestFullAccessToReminders()
        guard granted else {
            log("Доступ к напоминаниям запрещён")
            throw EventKitReminderServiceError.accessDenied
        }
    }

    private func fetchReminders(with predicate: NSPredicate) async throws -> [EKReminder] {
        try await withCheckedThrowingContinuation { continuation in
            store.fetchReminders(matching: predicate) { reminders in
                if let reminders {
                    continuation.resume(returning: reminders)
                } else {
                    let error = EventKitReminderServiceError.fetchFailed(
                        EventKitReminderServiceError.accessDenied
                    )
                    self.log("Ошибка при загрузке напоминаний: \(error)")
                    continuation.resume(throwing: error)
                }
            }
        }
    }

    private func log(_ message: String) {
        fputs("[EventKitReminderService] \(message)\n", stderr)
    }

    func mapToReminderItem(_ ekReminder: EKReminder) -> ReminderItem {
        ReminderItem(
            id: ekReminder.calendarItemIdentifier,
            listName: ekReminder.calendar.title,
            title: ekReminder.title ?? "",
            notes: ekReminder.notes,
            dueDate: ekReminder.dueDateComponents?.date,
            completionDate: ekReminder.completionDate,
            creationDate: ekReminder.creationDate,
            modificationDate: ekReminder.lastModifiedDate,
            priority: ekReminder.priority,
            isCompleted: ekReminder.isCompleted,
            recurrenceRule: ekReminder.recurrenceRules?.first?.description,
            url: ekReminder.url?.absoluteString
        )
    }
}
