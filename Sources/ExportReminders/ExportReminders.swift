import ArgumentParser
import Foundation

@main
struct ExportRemindersCLI: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "export-reminders",
        abstract: "Export reminders from Apple Reminders to a file."
    )

    @Option(name: .long, help: "Output format: json or csv (default: json)")
    var format: Format = .json

    @Option(name: .long, help: "Output file path (default: ./reminders_export.json)")
    var output: String = "./reminders_export.json"

    @Option(name: .long, help: "Filter by list name (can be specified multiple times)")
    var list: [String] = []

    @Option(name: .long, help: "Filter by completion status: true or false")
    var completed: Bool?

    mutating func run() async throws {
        try await run(
            service: EventKitReminderService(),
            exporter: makeExporter(for: format)
        )
    }

    // MARK: - Internal

    func run(service: ReminderServiceProtocol, exporter: ReminderExporterProtocol) async throws {
        do {
            let allReminders = try await service.fetchAllReminders()
            let filtered = applyFilters(to: allReminders)
            let outputPath = resolvedOutputPath()
            let url = URL(fileURLWithPath: outputPath)
            try exporter.export(filtered, to: url)
            print("Экспортировано \(filtered.count) напоминаний в \(outputPath)")
        } catch EventKitReminderServiceError.accessDenied {
            fputs("Ошибка: доступ к напоминаниям запрещён.\n", stderr)
            throw ExitCode(1)
        } catch {
            fputs("Ошибка: \(error.localizedDescription)\n", stderr)
            throw ExitCode(2)
        }
    }

    private func resolvedOutputPath() -> String {
        let defaultPath = "./reminders_export.json"
        guard output == defaultPath, format == .tasksOrg else { return output }
        return "./reminders_export_tasks_org.json"
    }

    // MARK: - Private

    private func makeExporter(for format: Format) -> ReminderExporterProtocol {
        switch format {
        case .json:
            return JSONExporter()
        case .csv:
            return CSVExporter()
        case .tasksOrg:
            return TasksOrgConverter()
        }
    }

    private func applyFilters(to reminders: [ReminderItem]) -> [ReminderItem] {
        let lowercasedLists = list.map { $0.lowercased() }
        return reminders
            .filter { reminder in
                list.isEmpty || lowercasedLists.contains(reminder.listName.lowercased())
            }
            .filter { reminder in
                completed == nil || reminder.isCompleted == completed
            }
    }
}
