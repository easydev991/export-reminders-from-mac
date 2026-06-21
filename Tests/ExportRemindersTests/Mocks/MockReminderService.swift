@testable import ExportReminders
import Foundation

/// Мок-сервис для тестирования без доступа к EventKit.
///
/// Позволяет предопределить возвращаемые напоминания,
/// а также сконфигурировать ошибку для тестирования сценариев отказа.
actor MockReminderService: ReminderServiceProtocol {
    var reminders: [ReminderItem]
    var errorToThrow: Error?

    init(
        reminders: [ReminderItem] = [],
        errorToThrow: Error? = nil
    ) {
        self.reminders = reminders
        self.errorToThrow = errorToThrow
    }

    func fetchAllReminders() async throws -> [ReminderItem] {
        if let error = errorToThrow {
            throw error
        }
        return reminders
    }
}
