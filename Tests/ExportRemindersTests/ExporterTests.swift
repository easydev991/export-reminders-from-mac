@testable import ExportReminders
import Foundation
import Testing

// MARK: - Shared helper

func makeTempURL(extension ext: String) -> URL {
    FileManager.default.temporaryDirectory
        .appendingPathComponent(UUID().uuidString)
        .appendingPathExtension(ext)
}

// MARK: - JSONExporter

@Test("JSONExporter создаёт валидный JSON с массивом напоминаний")
func jsonExporterMultipleReminders() throws {
    let exporter = JSONExporter()
    let url = makeTempURL(extension: "json")

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
    let url = makeTempURL(extension: "json")

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
    let url = makeTempURL(extension: "json")

    let reminder = ReminderItem(
        id: "minimal",
        listName: "Тест",
        title: "Минимальное",
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

// MARK: - CSVExporter

@Test("CSVExporter создаёт корректную строку заголовков")
func csvExporterHeaders() throws {
    let exporter = CSVExporter()
    let url = makeTempURL(extension: "csv")

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
    let url = makeTempURL(extension: "csv")

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
    let url = makeTempURL(extension: "csv")

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
    let url = makeTempURL(extension: "csv")

    let reminder = ReminderItem(
        id: "1",
        listName: "Покупки",
        title: "Купить хлеб, молоко",
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
    let url = makeTempURL(extension: "csv")

    let reminder = ReminderItem(
        id: "1",
        listName: "Работа",
        title: "Сказать \"Привет\" коллегам",
        isCompleted: false
    )
    try exporter.export([reminder], to: url)
    let data = try Data(contentsOf: url)
    let content = try #require(String(data: data, encoding: .utf8))

    let title = reminder.title
    #expect(content.contains(title) == false)
    #expect(content.contains("\"Сказать \"\"Привет\"\" коллегам\""))

    try FileManager.default.removeItem(at: url)
}

@Test("CSVExporter записывает nil-поля как пустую строку")
func csvExporterNilFields() throws {
    let exporter = CSVExporter()
    let url = makeTempURL(extension: "csv")

    let reminder = ReminderItem(
        id: "1",
        listName: "Тест",
        title: "Без заметки и даты",
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
    let url = makeTempURL(extension: "csv")

    let reminder = ReminderItem(
        id: "1",
        listName: "Заметки",
        title: "Список дел",
        notes: "Купить молоко\nКупить хлеб\nПозвонить врачу",
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
    let url = makeTempURL(extension: "csv")

    try exporter.export([ReminderItem.sample], to: url)
    let data = try Data(contentsOf: url)
    let content = try #require(String(data: data, encoding: .utf8))

    #expect(content.contains("2026-06-25T10:30:00Z"))

    try FileManager.default.removeItem(at: url)
}
