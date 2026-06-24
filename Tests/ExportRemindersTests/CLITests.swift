import ArgumentParser
@testable import ExportReminders
import Foundation
import Testing

@Test("CLI вызывает сервис и экспортёр в правильном порядке")
func cliIntegrationCallsServiceAndExporter() async throws {
    let reminders = ReminderItem.samples
    let mockService = MockReminderService(reminders: reminders)
    let mockExporter = MockReminderExporter()
    let url = FileManager.default.temporaryDirectory.appendingPathComponent("test.json")

    let cli = try ExportRemindersCLI.parse(["--format", "json", "--output", url.path])
    try await cli.run(service: mockService, exporter: mockExporter)

    #expect(mockExporter.exportCallCount == 1)
    let exported = try #require(mockExporter.exportedReminders)
    #expect(exported.count == 3)
    #expect(mockExporter.exportURL?.path == url.path)
}

@Test("CLI фильтрует по спискам")
func cliFiltersByList() async throws {
    let reminders = ReminderItem.samples
    let mockService = MockReminderService(reminders: reminders)
    let mockExporter = MockReminderExporter()

    let cli = try ExportRemindersCLI.parse(["--format", "json", "--output", "./test.json", "--list", "Покупки"])
    try await cli.run(service: mockService, exporter: mockExporter)

    let exported = try #require(mockExporter.exportedReminders)
    #expect(exported.count == 1)
    #expect(exported[0].listName == "Покупки")
}

@Test("CLI фильтрует по статусу выполнения")
func cliFiltersByCompleted() async throws {
    let reminders = ReminderItem.samples
    let mockService = MockReminderService(reminders: reminders)
    let mockExporter = MockReminderExporter()

    let cli = try ExportRemindersCLI.parse(["--format", "json", "--output", "./test.json", "--completed", "true"])
    try await cli.run(service: mockService, exporter: mockExporter)

    let exported = try #require(mockExporter.exportedReminders)
    #expect(exported.count == 1)
    #expect(exported[0].isCompleted)
}

@Test("CLI выводит сообщение об ошибке доступа в stderr")
func cliReportsAccessDenied() async {
    let mockService = MockReminderService(
        errorToThrow: EventKitReminderServiceError.accessDenied
    )
    let mockExporter = MockReminderExporter()

    do {
        let cli = try ExportRemindersCLI.parse(["--format", "json", "--output", "./test.json"])
        try await cli.run(service: mockService, exporter: mockExporter)
        Issue.record("expected ExitCode to be thrown")
    } catch is ExitCode {
        // Expected — CLI prints to stderr and exits with code 1
    } catch {
        Issue.record("unexpected error: \(error)")
    }
}

@Test("CLI выводит сообщение об ошибке записи файла в stderr")
func cliReportsWriteError() async {
    let reminders = ReminderItem.samples
    let mockService = MockReminderService(reminders: reminders)
    let mockExporter = MockReminderExporter()
    mockExporter.errorToThrow = NSError(domain: "test", code: 2, userInfo: nil)

    do {
        let cli = try ExportRemindersCLI.parse(["--format", "json", "--output", "/nonexistent/output.json"])
        try await cli.run(service: mockService, exporter: mockExporter)
        Issue.record("expected ExitCode to be thrown")
    } catch is ExitCode {
        // Expected — CLI prints to stderr and exits with code 2
    } catch {
        Issue.record("unexpected error: \(error)")
    }
}
