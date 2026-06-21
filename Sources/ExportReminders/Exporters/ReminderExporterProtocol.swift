import Foundation

/// Контракт экспортёра напоминаний.
protocol ReminderExporterProtocol {
    /// Экспортирует массив напоминаний в файл по указанному URL.
    func export(_ reminders: [ReminderItem], to url: URL) throws
}
