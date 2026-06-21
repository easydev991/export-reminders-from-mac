@testable import ExportReminders
import Foundation

/// Мок-экспортёр, записывающий вызов `export` с параметрами.
final class MockReminderExporter: ReminderExporterProtocol {
    private(set) var exportedReminders: [ReminderItem]?
    private(set) var exportURL: URL?
    private(set) var exportCallCount = 0
    var errorToThrow: Error?

    func export(_ reminders: [ReminderItem], to url: URL) throws {
        exportCallCount += 1
        exportedReminders = reminders
        exportURL = url
        if let error = errorToThrow {
            throw error
        }
    }
}
