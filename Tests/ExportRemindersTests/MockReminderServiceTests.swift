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

@Test("MockReminderService возвращает предопределённые списки")
func mockServiceReturnsLists() async throws {
    let lists = [
        ReminderList(id: "list-1", title: "Покупки"),
        ReminderList(id: "list-2", title: "Работа", color: "1E90FF"),
    ]
    let service = MockReminderService(lists: lists)

    let result = try await service.fetchAllLists()

    #expect(result.count == 2)
    #expect(result[0].title == "Покупки")
    #expect(result[1].title == "Работа")
}

@Test("MockReminderService возвращает пустой массив")
func mockServiceReturnsEmpty() async throws {
    let service = MockReminderService()

    let reminders = try await service.fetchAllReminders()
    let lists = try await service.fetchAllLists()

    #expect(reminders.isEmpty)
    #expect(lists.isEmpty)
}

@Test("MockReminderService выбрасывает ошибку")
func mockServiceThrowsError() async {
    let service = MockReminderService(errorToThrow: EventKitReminderServiceError.accessDenied)

    do {
        _ = try await service.fetchAllReminders()
        #expect(Bool(false), "Expected error to be thrown")
    } catch {
        #expect(error as? EventKitReminderServiceError == .accessDenied)
    }
}
