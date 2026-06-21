@testable import ExportReminders
import Foundation
import Testing

@Test("JSONExporter создаёт валидный JSON с массивом напоминаний")
func jsonExporterMultipleReminders() throws {
    let exporter = JSONExporter()
    let url = FileManager.default.temporaryDirectory
        .appendingPathComponent(UUID().uuidString)
        .appendingPathExtension("json")

    try exporter.export(ReminderItem.samples, to: url)
    let data = try Data(contentsOf: url)
    let decoder = JSONDecoder()
    decoder.dateDecodingStrategy = .iso8601
    let decoded = try decoder.decode([ReminderItem].self, from: data)

    #expect(decoded.count == 3)
    #expect(decoded[0].id == "sample-1")
    #expect(decoded[1].id == "sample-2")
    #expect(decoded[2].id == "sample-3")

    try FileManager.default.removeItem(at: url)
}

@Test("JSONExporter создаёт [] для пустого массива")
func jsonExporterEmptyArray() throws {
    let exporter = JSONExporter()
    let url = FileManager.default.temporaryDirectory
        .appendingPathComponent(UUID().uuidString)
        .appendingPathExtension("json")

    try exporter.export([], to: url)
    let data = try Data(contentsOf: url)
    let content = try #require(String(data: data, encoding: .utf8))

    // Pretty-printed empty array is "[\n\n]" with newlines
    #expect(content.contains("["))
    #expect(content.contains("]"))

    try FileManager.default.removeItem(at: url)
}

@Test("JSONExporter не включает nil-поля в вывод")
func jsonExporterOmitsNilFields() throws {
    let exporter = JSONExporter()
    let url = FileManager.default.temporaryDirectory
        .appendingPathComponent(UUID().uuidString)
        .appendingPathExtension("json")

    let reminder = ReminderItem(
        id: "minimal",
        listName: "Тест",
        title: "Минимальное",
        priority: 0,
        isCompleted: false
    )
    try exporter.export([reminder], to: url)
    let data = try Data(contentsOf: url)
    let content = try #require(String(data: data, encoding: .utf8))

    #expect(!content.contains("\"notes\""))
    #expect(!content.contains("\"dueDate\""))
    #expect(!content.contains("\"url\""))

    try FileManager.default.removeItem(at: url)
}

@Test("JSONExporter выбрасывает ошибку при недоступной директории")
func jsonExporterWriteError() {
    let exporter = JSONExporter()
    let url = URL(fileURLWithPath: "/nonexistent/path/output.json")

    #expect(throws: (any Error).self) {
        try exporter.export(ReminderItem.samples, to: url)
    }
}
