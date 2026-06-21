@testable import ExportReminders
import Foundation
import Testing

@Test("Инициализация ReminderList с обязательными полями")
func reminderListInitWithRequiredFields() {
    let list = ReminderList(id: "list-1", title: "Покупки")

    #expect(list.id == "list-1")
    #expect(list.title == "Покупки")
    #expect(list.color == nil)
}

@Test("Инициализация ReminderList с цветом")
func reminderListInitWithColor() {
    let list = ReminderList(id: "list-2", title: "Работа", color: "1E90FF")

    #expect(list.id == "list-2")
    #expect(list.title == "Работа")
    #expect(list.color == "1E90FF")
}

@Test("Сериализация и десериализация ReminderList")
func reminderListCodableRoundtrip() throws {
    let original = ReminderList(id: "list-3", title: "Здоровье", color: "32CD32")

    let encoder = JSONEncoder()
    encoder.outputFormatting = .prettyPrinted
    let data = try encoder.encode(original)

    let decoder = JSONDecoder()
    let decoded = try decoder.decode(ReminderList.self, from: data)

    #expect(decoded == original)
    #expect(decoded.id == "list-3")
    #expect(decoded.title == "Здоровье")
    #expect(decoded.color == "32CD32")
}
