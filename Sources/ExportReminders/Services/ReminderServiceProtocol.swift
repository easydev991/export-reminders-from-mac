/// Контракт сервиса для чтения напоминаний из Apple Reminders.
protocol ReminderServiceProtocol: Sendable {
    /// Возвращает все напоминания из всех доступных списков.
    func fetchAllReminders() async throws -> [ReminderItem]
}
