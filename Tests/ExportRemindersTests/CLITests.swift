import ArgumentParser
@testable import ExportReminders
import Foundation
import Testing

@Suite(.serialized) struct CLITestSuite {}
// Сериализован из-за общего состояния TestDependencies (static vars).
// Рефакторинг: передавать зависимости через конструктор — отдельная задача.

extension CLITestSuite {
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

    @Test("CLI выдаёт ошибку при неверном --format")
    func cliRejectsInvalidFormat() throws {
        #expect(throws: (any Error).self) {
            try ExportRemindersCLI.parse(["--format", "xml"])
        }
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

        TestDependencies.service = mockService
        TestDependencies.exporter = mockExporter
        defer {
            TestDependencies.service = nil
            TestDependencies.exporter = nil
        }

        var cli = try ExportRemindersCLI.parse(["--format", "json", "--output", url.path])
        try await cli.run()

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

        TestDependencies.service = mockService
        TestDependencies.exporter = mockExporter
        defer {
            TestDependencies.service = nil
            TestDependencies.exporter = nil
        }

        var cli = try ExportRemindersCLI.parse(["--format", "json", "--output", "./test.json", "--list", "Покупки"])
        try await cli.run()

        let exported = try #require(mockExporter.exportedReminders)
        #expect(exported.count == 1)
        #expect(exported[0].listName == "Покупки")
    }

    @Test("CLI фильтрует по статусу выполнения")
    func cliFiltersByCompleted() async throws {
        let reminders = ReminderItem.samples
        let mockService = MockReminderService(reminders: reminders)
        let mockExporter = MockReminderExporter()

        TestDependencies.service = mockService
        TestDependencies.exporter = mockExporter
        defer {
            TestDependencies.service = nil
            TestDependencies.exporter = nil
        }

        var cli = try ExportRemindersCLI.parse(["--format", "json", "--output", "./test.json", "--completed", "true"])
        try await cli.run()

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

        TestDependencies.service = mockService
        TestDependencies.exporter = mockExporter
        defer {
            TestDependencies.service = nil
            TestDependencies.exporter = nil
        }

        do {
            var cli = try ExportRemindersCLI.parse(["--format", "json", "--output", "./test.json"])
            try await cli.run()
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

        TestDependencies.service = mockService
        TestDependencies.exporter = mockExporter
        defer {
            TestDependencies.service = nil
            TestDependencies.exporter = nil
        }

        do {
            var cli = try ExportRemindersCLI.parse(["--format", "json", "--output", "/nonexistent/output.json"])
            try await cli.run()
            Issue.record("expected ExitCode to be thrown")
        } catch is ExitCode {
            // Expected — CLI prints to stderr and exits with code 2
        } catch {
            Issue.record("unexpected error: \(error)")
        }
    }
}
