@testable import ExportReminders
import Foundation

/// Мок-сервис для тестирования без доступа к EventKit.
///
/// Позволяет предопределить возвращаемые напоминания и списки,
/// а также сконфигурировать ошибку для тестирования сценариев отказа.
actor MockReminderService: ReminderServiceProtocol {
    var reminders: [ReminderItem]
    var lists: [ReminderList]
    var errorToThrow: Error?

    init(
        reminders: [ReminderItem] = [],
        lists: [ReminderList] = [],
        errorToThrow: Error? = nil
    ) {
        self.reminders = reminders
        self.lists = lists
        self.errorToThrow = errorToThrow
    }

    func fetchAllReminders() async throws -> [ReminderItem] {
        if let error = errorToThrow {
            throw error
        }
        return reminders
    }

    func fetchAllLists() async throws -> [ReminderList] {
        if let error = errorToThrow {
            throw error
        }
        return lists
    }
}
