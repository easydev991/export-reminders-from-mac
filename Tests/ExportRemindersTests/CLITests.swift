import ArgumentParser
@testable import ExportReminders
import Foundation
import Testing

// MARK: - Argument Parsing

@Test("CLI парсит аргумент --format json")
func cliParsesFormatJson() throws {
    let cli = try ExportRemindersCLI.parse(["--format", "json"])
    #expect(cli.format == .json)
}

@Test("CLI парсит аргумент --format csv")
func cliParsesFormatCsv() throws {
    let cli = try ExportRemindersCLI.parse(["--format", "csv"])
    #expect(cli.format == .csv)
}

@Test("CLI использует формат json по умолчанию")
func cliDefaultFormat() throws {
    let cli = try ExportRemindersCLI.parse([])
    #expect(cli.format == .json)
}

@Test("CLI парсит аргумент --output с пользовательским путём")
func cliParsesOutput() throws {
    let cli = try ExportRemindersCLI.parse(["--output", "./out/backup.json"])
    #expect(cli.output == "./out/backup.json")
}

@Test("CLI использует дефолтный путь для --output")
func cliDefaultOutput() throws {
    let cli = try ExportRemindersCLI.parse([])
    #expect(cli.output == "./reminders_export.json")
}

@Test("CLI фильтрует по одному списку")
func cliParsesSingleList() throws {
    let cli = try ExportRemindersCLI.parse(["--list", "Покупки"])
    #expect(cli.list == ["Покупки"])
}

@Test("CLI фильтрует по нескольким спискам")
func cliParsesMultipleLists() throws {
    let cli = try ExportRemindersCLI.parse(["--list", "Покупки", "--list", "Работа"])
    #expect(cli.list == ["Покупки", "Работа"])
}

@Test("CLI фильтрует только выполненные напоминания")
func cliParsesCompletedTrue() throws {
    let cli = try ExportRemindersCLI.parse(["--completed", "true"])
    #expect(cli.completed == true)
}

@Test("CLI фильтрует только невыполненные напоминания")
func cliParsesCompletedFalse() throws {
    let cli = try ExportRemindersCLI.parse(["--completed", "false"])
    #expect(cli.completed == false)
}

@Test("CLI не фильтрует по завершённости по умолчанию")
func cliParsesCompletedNil() throws {
    let cli = try ExportRemindersCLI.parse([])
    #expect(cli.completed == nil)
}

// MARK: - Integration with Mocks

@Test("CLI вызывает сервис и экспортёр в правильном порядке")
func cliIntegrationCallsServiceAndExporter() async throws {
    let reminders = ReminderItem.samples
    let mockService = MockReminderService(reminders: reminders)
    let mockExporter = MockReminderExporter()
    let url = FileManager.default.temporaryDirectory.appendingPathComponent("test.json")

    let cli = ExportRemindersCLI(
        format: .json,
        output: url.path,
        list: [],
        completed: nil,
        service: mockService,
        exporter: mockExporter
    )

    try await cli.runWithMocks()

    #expect(mockExporter.exportCallCount == 1)
    #expect(mockExporter.exportedReminders?.count == 3)
    #expect(mockExporter.exportURL?.path == url.path)
}

@Test("CLI фильтрует по спискам")
func cliFiltersByList() async throws {
    let reminders = ReminderItem.samples
    let mockService = MockReminderService(reminders: reminders)
    let mockExporter = MockReminderExporter()

    let cli = ExportRemindersCLI(
        format: .json,
        output: "./test.json",
        list: ["Покупки"],
        completed: nil,
        service: mockService,
        exporter: mockExporter
    )

    try await cli.runWithMocks()

    let exported = try #require(mockExporter.exportedReminders)
    #expect(exported.count == 1)
    #expect(exported[0].listName == "Покупки")
}

@Test("CLI фильтрует по статусу выполнения")
func cliFiltersByCompleted() async throws {
    let reminders = ReminderItem.samples
    let mockService = MockReminderService(reminders: reminders)
    let mockExporter = MockReminderExporter()

    let cli = ExportRemindersCLI(
        format: .json,
        output: "./test.json",
        list: [],
        completed: true,
        service: mockService,
        exporter: mockExporter
    )

    try await cli.runWithMocks()

    let exported = try #require(mockExporter.exportedReminders)
    #expect(exported.count == 1)
    #expect(exported[0].isCompleted == true)
}

@Test("CLI выводит сообщение об ошибке доступа в stderr")
func cliReportsAccessDenied() async throws {
    let mockService = MockReminderService(
        errorToThrow: EventKitReminderServiceError.accessDenied
    )
    let mockExporter = MockReminderExporter()

    let cli = ExportRemindersCLI(
        format: .json,
        output: "./test.json",
        list: [],
        completed: nil,
        service: mockService,
        exporter: mockExporter
    )

    // run() for the CLI should print to stderr and return
    try await cli.runWithMocks()
}

@Test("CLI выводит сообщение об ошибке записи файла в stderr")
func cliReportsWriteError() async throws {
    let reminders = ReminderItem.samples
    let mockService = MockReminderService(reminders: reminders)
    let mockExporter = MockReminderExporter()
    mockExporter.errorToThrow = NSError(domain: "test", code: 2, userInfo: nil)

    let cli = ExportRemindersCLI(
        format: .json,
        output: "/nonexistent/output.json",
        list: [],
        completed: nil,
        service: mockService,
        exporter: mockExporter
    )

    try await cli.runWithMocks()
}
