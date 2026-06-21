@testable import ExportReminders
import Foundation
import Testing

@Test("MockReminderService возвращает предопределённые напоминания")
func mockServiceReturnsReminders() async throws {
    let reminders = [
        ReminderItem(id: "1", listName: "Список", title: "Задача 1", priority: 0, isCompleted: false),
        ReminderItem(id: "2", listName: "Список", title: "Задача 2", priority: 5, isCompleted: true),
    ]
    let service = MockReminderService(reminders: reminders)

    let result = try await service.fetchAllReminders()

    #expect(result.count == 2)
    #expect(result[0].id == "1")
    #expect(result[1].id == "2")
}

@Test("MockReminderService возвращает пустой массив")
func mockServiceReturnsEmpty() async throws {
    let service = MockReminderService()

    let reminders = try await service.fetchAllReminders()

    #expect(reminders.isEmpty)
}

@Test("MockReminderService выбрасывает ошибку")
func mockServiceThrowsError() async throws {
    let service = MockReminderService(errorToThrow: EventKitReminderServiceError.accessDenied)

    await #expect(throws: EventKitReminderServiceError.accessDenied) {
        try await service.fetchAllReminders()
    }
}
