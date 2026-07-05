@testable import ExportReminders
import Foundation
import Testing

@Test("Сериализация TasksOrgTask с hideUntil")
func tasksOrgTaskSerializationWithHideUntil() throws {
    let encoder = JSONEncoder()
    encoder.outputFormatting = [.prettyPrinted]
    let task = TasksOrgTask(
        title: "Купить молоко",
        dueDate: nil,
        hideUntil: 1_750_410_000_000,
        creationDate: nil,
        modificationDate: nil,
        completionDate: nil,
        notes: nil,
        recurrence: nil,
        remoteId: "rem-001"
    )

    let data = try encoder.encode(task)
    let json = try #require(String(data: data, encoding: .utf8))

    #expect(json.contains("\"hideUntil\" : 1750410000000"))
}

@Test("Сериализация TasksOrgTask без hideUntil")
func tasksOrgTaskSerializationWithoutHideUntil() throws {
    let encoder = JSONEncoder()
    encoder.outputFormatting = [.prettyPrinted]
    let task = TasksOrgTask(
        title: "Купить молоко",
        dueDate: nil,
        hideUntil: nil,
        creationDate: nil,
        modificationDate: nil,
        completionDate: nil,
        notes: nil,
        recurrence: nil,
        remoteId: "rem-001"
    )

    let data = try encoder.encode(task)
    let json = try #require(String(data: data, encoding: .utf8))

    #expect(!json.contains("\"hideUntil\""))
}
