@testable import ExportReminders
import Foundation
import Testing

@Test("Инициализация ReminderItem с обязательными полями")
func reminderItemInitWithRequiredFields() {
    let item = ReminderItem(
        id: "test-id",
        listName: "Покупки",
        title: "Купить молоко",
        priority: 5,
        isCompleted: false
    )

    #expect(item.id == "test-id")
    #expect(item.listName == "Покупки")
    #expect(item.title == "Купить молоко")
    #expect(!item.isCompleted)
    #expect(item.priority == 5)
    #expect(item.notes == nil)
    #expect(item.dueDate == nil)
    #expect(item.startDate == nil)
    #expect(item.completionDate == nil)
    #expect(item.creationDate == nil)
    #expect(item.modificationDate == nil)
    #expect(item.recurrenceRule == nil)
    #expect(item.url == nil)
}

@Test("Инициализация ReminderItem с startDate")
func reminderItemInitWithStartDate() throws {
    let startDate = try #require(ISO8601DateFormatter().date(from: "2025-06-20T09:00:00Z"))
    let item = ReminderItem(
        id: "test-id",
        listName: "Покупки",
        title: "Купить молоко",
        startDate: startDate,
        priority: 5,
        isCompleted: false
    )

    #expect(item.startDate == startDate)
}

@Test("Сериализация ReminderItem в JSON")
func reminderItemJSONSerialization() throws {
    let date = try #require(ISO8601DateFormatter().date(from: "2026-06-25T10:30:00Z"))
    let startDate = try #require(ISO8601DateFormatter().date(from: "2025-06-20T09:00:00Z"))
    let item = ReminderItem(
        id: "test-id-1",
        listName: "Покупки",
        title: "Купить молоко",
        notes: "Лучше безлактозное",
        dueDate: date,
        startDate: startDate,
        completionDate: date,
        creationDate: date,
        modificationDate: date,
        priority: 5,
        isCompleted: false,
        recurrenceRule: "FREQ=DAILY",
        url: "https://example.com"
    )

    let encoder = JSONEncoder()
    encoder.dateEncodingStrategy = .iso8601
    encoder.outputFormatting = [.prettyPrinted, .withoutEscapingSlashes]
    let data = try encoder.encode(item)
    let json = try #require(String(data: data, encoding: .utf8))

    #expect(json.contains("\"id\" : \"test-id-1\""))
    #expect(json.contains("\"listName\" : \"Покупки\""))
    #expect(json.contains("\"title\" : \"Купить молоко\""))
    #expect(json.contains("\"notes\" : \"Лучше безлактозное\""))
    #expect(json.contains("\"dueDate\" : \"2026-06-25T10:30:00Z\""))
    #expect(json.contains("\"startDate\" : \"2025-06-20T09:00:00Z\""))
    #expect(json.contains("\"priority\" : 5"))
    #expect(json.contains("\"isCompleted\" : false"))
    #expect(json.contains("\"recurrenceRule\" : \"FREQ=DAILY\""))
    #expect(json.contains("\"url\" : \"https://example.com\""))
}

@Test("Десериализация ReminderItem из JSON")
func reminderItemJSONDeserialization() throws {
    let json = """
    {
        "id": "test-id-1",
        "listName": "Покупки",
        "title": "Купить молоко",
        "notes": "Лучше безлактозное",
        "dueDate": "2026-06-25T10:30:00Z",
        "startDate": "2025-06-20T09:00:00Z",
        "completionDate": "2026-06-25T10:30:00Z",
        "creationDate": "2026-06-20T08:00:00Z",
        "modificationDate": "2026-06-21T12:00:00Z",
        "priority": 5,
        "isCompleted": false,
        "recurrenceRule": "FREQ=DAILY",
        "url": "https://example.com"
    }
    """
    let data = try #require(json.data(using: .utf8))
    let decoder = JSONDecoder()
    decoder.dateDecodingStrategy = .iso8601
    let item = try decoder.decode(ReminderItem.self, from: data)

    #expect(item.id == "test-id-1")
    #expect(item.listName == "Покупки")
    #expect(item.title == "Купить молоко")
    #expect(item.notes == "Лучше безлактозное")
    #expect(item.priority == 5)
    #expect(!item.isCompleted)
    #expect(item.recurrenceRule == "FREQ=DAILY")
    #expect(item.url == "https://example.com")

    let expectedDate = try #require(ISO8601DateFormatter().date(from: "2026-06-25T10:30:00Z"))
    let expectedStartDate = try #require(ISO8601DateFormatter().date(from: "2025-06-20T09:00:00Z"))
    #expect(item.dueDate == expectedDate)
    #expect(item.startDate == expectedStartDate)
    #expect(item.completionDate == expectedDate)
}

@Test("Десериализация ReminderItem без опциональных полей")
func reminderItemDeserializationWithoutOptionals() throws {
    let json = """
    {
        "id": "test-id-2",
        "listName": "Работа",
        "title": "Отчёт",
        "priority": 0,
        "isCompleted": true
    }
    """
    let data = try #require(json.data(using: .utf8))
    let decoder = JSONDecoder()
    decoder.dateDecodingStrategy = .iso8601
    let item = try decoder.decode(ReminderItem.self, from: data)

    #expect(item.id == "test-id-2")
    #expect(item.listName == "Работа")
    #expect(item.title == "Отчёт")
    #expect(item.isCompleted)
    #expect(item.priority == 0)
    #expect(item.notes == nil)
    #expect(item.dueDate == nil)
    #expect(item.startDate == nil)
    #expect(item.completionDate == nil)
    #expect(item.creationDate == nil)
    #expect(item.modificationDate == nil)
    #expect(item.recurrenceRule == nil)
    #expect(item.url == nil)
}

@Test("Сравнение одинаковых ReminderItem")
func reminderItemEquatableEqual() {
    let item1 = ReminderItem(
        id: "id-1",
        listName: "Список",
        title: "Задача",
        priority: 1,
        isCompleted: false
    )
    let item2 = ReminderItem(
        id: "id-1",
        listName: "Список",
        title: "Задача",
        priority: 1,
        isCompleted: false
    )
    #expect(item1 == item2)
}

@Test("Сравнение разных ReminderItem")
func reminderItemEquatableNotEqual() throws {
    let item1 = ReminderItem(
        id: "id-1",
        listName: "Список",
        title: "Задача А",
        priority: 1,
        isCompleted: false
    )
    let startDate = try #require(ISO8601DateFormatter().date(from: "2025-06-20T09:00:00Z"))
    let item2 = ReminderItem(
        id: "id-2",
        listName: "Список",
        title: "Задача Б",
        startDate: startDate,
        priority: 5,
        isCompleted: true
    )
    #expect(item1 != item2)
}
