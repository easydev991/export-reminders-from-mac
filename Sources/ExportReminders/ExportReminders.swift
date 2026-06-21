import ArgumentParser
import Foundation

// MARK: - Stderr TextOutputStream

struct StderrOutputStream: TextOutputStream {
    let handle: UnsafeMutablePointer<FILE>

    init(_ handle: UnsafeMutablePointer<FILE>) {
        self.handle = handle
    }

    func write(_ string: String) {
        fputs(string, handle)
    }
}

var standardError = StderrOutputStream(Darwin.stderr)

// MARK: - Test Dependencies

enum TestDependencies {
    static var service: ReminderServiceProtocol?
    static var exporter: ReminderExporterProtocol?
}

// MARK: - CLI

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
        let activeService = TestDependencies.service ?? EventKitReminderService()
        let activeExporter = TestDependencies.exporter ?? makeExporter(for: format)

        do {
            let allReminders = try await activeService.fetchAllReminders()
            let filtered = applyFilters(to: allReminders)
            let url = URL(fileURLWithPath: output)
            try activeExporter.export(filtered, to: url)
            print("Экспортировано \(filtered.count) напоминаний в \(output)")
        } catch EventKitReminderServiceError.accessDenied {
            print("Ошибка: доступ к напоминаниям запрещён.", to: &standardError)
            throw ExitCode(1)
        } catch {
            print("Ошибка: \(error.localizedDescription)", to: &standardError)
            throw ExitCode(2)
        }
    }

    // MARK: - Private

    private func makeExporter(for format: Format) -> ReminderExporterProtocol {
        switch format {
        case .json:
            return JSONExporter()
        case .csv:
            return CSVExporter()
        }
    }

    private func applyFilters(to reminders: [ReminderItem]) -> [ReminderItem] {
        var result = reminders

        if !list.isEmpty {
            let lowercasedLists = list.map { $0.lowercased() }
            result = result.filter { reminder in
                lowercasedLists.contains(reminder.listName.lowercased())
            }
        }

        if let completed {
            result = result.filter { $0.isCompleted == completed }
        }

        return result
    }
}
