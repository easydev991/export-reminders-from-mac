import Foundation

/// Модель списка напоминаний (календарь в терминах EventKit).
struct ReminderList: Codable, Equatable {
    let id: String
    let title: String
    let color: String?

    init(id: String, title: String, color: String? = nil) {
        self.id = id
        self.title = title
        self.color = color
    }
}
