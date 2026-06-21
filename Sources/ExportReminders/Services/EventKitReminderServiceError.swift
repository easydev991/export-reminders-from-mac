/// Ошибки, возникающие при работе с EventKit.
enum EventKitReminderServiceError: Error, Equatable {
    /// Пользователь запретил доступ к напоминаниям.
    case accessDenied
    /// Ошибка при загрузке данных из EventKit.
    case fetchFailed(Error)
    /// Неизвестная ошибка.
    case unknown

    static func == (lhs: EventKitReminderServiceError, rhs: EventKitReminderServiceError) -> Bool {
        switch (lhs, rhs) {
        case (.accessDenied, .accessDenied): return true
        case (.unknown, .unknown): return true
        case (.fetchFailed, .fetchFailed): return true
        default: return false
        }
    }
}
