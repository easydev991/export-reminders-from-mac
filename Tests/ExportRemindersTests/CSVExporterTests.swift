@testable import ExportReminders
import Foundation
import Testing

@Test("CSVExporter создаёт корректную строку заголовков")
func csvExporterHeaders() throws {
    let exporter = CSVExporter()
    let url = FileManager.default.temporaryDirectory
        .appendingPathComponent(UUID().uuidString)
        .appendingPathExtension("csv")

    try exporter.export([], to: url)
    let data = try Data(contentsOf: url)
    let content = try #require(String(data: data, encoding: .utf8))
        .trimmingCharacters(in: .whitespacesAndNewlines)

    let expectedHeaders = "id,listName,title,notes,dueDate,completionDate,creationDate,modificationDate,priority,isCompleted,recurrenceRule,url"
    #expect(content == expectedHeaders)

    try FileManager.default.removeItem(at: url)
}

@Test("CSVExporter записывает одно напоминание")
func csvExporterSingleReminder() throws {
    let exporter = CSVExporter()
    let url = FileManager.default.temporaryDirectory
        .appendingPathComponent(UUID().uuidString)
        .appendingPathExtension("csv")

    try exporter.export([ReminderItem.sample], to: url)
    let data = try Data(contentsOf: url)
    let content = try #require(String(data: data, encoding: .utf8))
    let lines = content.split(separator: "\n", omittingEmptySubsequences: false)

    #expect(lines.count == 2) // header + 1 row

    try FileManager.default.removeItem(at: url)
}

@Test("CSVExporter записывает несколько напоминаний")
func csvExporterMultipleReminders() throws {
    let exporter = CSVExporter()
    let url = FileManager.default.temporaryDirectory
        .appendingPathComponent(UUID().uuidString)
        .appendingPathExtension("csv")

    try exporter.export(ReminderItem.samples, to: url)
    let data = try Data(contentsOf: url)
    let content = try #require(String(data: data, encoding: .utf8))
    let lines = content.split(separator: "\n", omittingEmptySubsequences: false)

    #expect(lines.count == 4) // header + 3 rows

    try FileManager.default.removeItem(at: url)
}

@Test("CSVExporter экранирует запятые в значениях")
func csvExporterEscapesCommas() throws {
    let exporter = CSVExporter()
    let url = FileManager.default.temporaryDirectory
        .appendingPathComponent(UUID().uuidString)
        .appendingPathExtension("csv")

    let reminder = ReminderItem(
        id: "1",
        listName: "Покупки",
        title: "Купить хлеб, молоко",
        priority: 0,
        isCompleted: false
    )
    try exporter.export([reminder], to: url)
    let data = try Data(contentsOf: url)
    let content = try #require(String(data: data, encoding: .utf8))

    #expect(content.contains("\"Купить хлеб, молоко\""))

    try FileManager.default.removeItem(at: url)
}

@Test("CSVExporter удваивает кавычки внутри значений")
func csvExporterEscapesQuotes() throws {
    let exporter = CSVExporter()
    let url = FileManager.default.temporaryDirectory
        .appendingPathComponent(UUID().uuidString)
        .appendingPathExtension("csv")

    let reminder = ReminderItem(
        id: "1",
        listName: "Работа",
        title: "Сказать \"Привет\" коллегам",
        priority: 0,
        isCompleted: false
    )
    try exporter.export([reminder], to: url)
    let data = try Data(contentsOf: url)
    let content = try #require(String(data: data, encoding: .utf8))

    #expect(content.contains("\"\"Привет\"\""))

    try FileManager.default.removeItem(at: url)
}

@Test("CSVExporter записывает nil-поля как пустую строку")
func csvExporterNilFields() throws {
    let exporter = CSVExporter()
    let url = FileManager.default.temporaryDirectory
        .appendingPathComponent(UUID().uuidString)
        .appendingPathExtension("csv")

    let reminder = ReminderItem(
        id: "1",
        listName: "Тест",
        title: "Без заметки и даты",
        priority: 0,
        isCompleted: false
    )
    try exporter.export([reminder], to: url)
    let data = try Data(contentsOf: url)
    let content = try #require(String(data: data, encoding: .utf8))
    let lines = content.split(separator: "\n")

    // Header: 12 cols, Data: 12 cols with some empty
    let dataLine = lines[1]
    let columns = dataLine.split(separator: ",", omittingEmptySubsequences: false)
    // notes (index 3), dueDate (4), completionDate (5), creationDate (6),
    // modificationDate (7), recurrenceRule (10), url (11) are empty
    #expect(columns.count == 12)

    try FileManager.default.removeItem(at: url)
}

@Test("CSVExporter экранирует переводы строк в значениях")
func csvExporterEscapesNewlines() throws {
    let exporter = CSVExporter()
    let url = FileManager.default.temporaryDirectory
        .appendingPathComponent(UUID().uuidString)
        .appendingPathExtension("csv")

    let reminder = ReminderItem(
        id: "1",
        listName: "Заметки",
        title: "Список дел",
        notes: "Купить молоко\nКупить хлеб\nПозвонить врачу",
        priority: 0,
        isCompleted: false
    )
    try exporter.export([reminder], to: url)
    let data = try Data(contentsOf: url)
    let content = try #require(String(data: data, encoding: .utf8))

    #expect(content.contains("\"Купить молоко\nКупить хлеб\nПозвонить врачу\""))

    try FileManager.default.removeItem(at: url)
}

@Test("CSVExporter форматирует даты в ISO 8601")
func csvExporterDateFormat() throws {
    let exporter = CSVExporter()
    let url = FileManager.default.temporaryDirectory
        .appendingPathComponent(UUID().uuidString)
        .appendingPathExtension("csv")

    try exporter.export([ReminderItem.sample], to: url)
    let data = try Data(contentsOf: url)
    let content = try #require(String(data: data, encoding: .utf8))

    #expect(content.contains("2026-06-25T10:30:00Z"))

    try FileManager.default.removeItem(at: url)
}
