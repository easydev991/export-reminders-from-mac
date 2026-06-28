/// Ошибки, возникающие при работе с EventKit.
enum EventKitReminderServiceError: Error, Equatable {
    /// Пользователь запретил доступ к напоминаниям.
    case accessDenied
    /// Ошибка при загрузке данных из EventKit.
    case fetchFailed(Error)

    static func == (lhs: EventKitReminderServiceError, rhs: EventKitReminderServiceError) -> Bool {
        switch (lhs, rhs) {
        case (.accessDenied, .accessDenied): true
        case (.fetchFailed, .fetchFailed): true
        default: false
        }
    }
}
