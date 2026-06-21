@testable import ExportReminders
import Foundation

extension ReminderItem {
    /// Одно напоминание со всеми заполненными полями для тестов.
    static let sample = ReminderItem(
        id: "sample-1",
        listName: "Покупки",
        title: "Купить молоко",
        notes: "Лучше безлактозное",
        dueDate: ISO8601DateFormatter().date(from: "2026-06-25T10:30:00Z"),
        completionDate: ISO8601DateFormatter().date(from: "2026-06-25T12:00:00Z"),
        creationDate: ISO8601DateFormatter().date(from: "2026-06-20T08:00:00Z"),
        modificationDate: ISO8601DateFormatter().date(from: "2026-06-21T15:00:00Z"),
        priority: 5,
        isCompleted: false,
        recurrenceRule: "FREQ=DAILY",
        url: "https://example.com"
    )

    /// Набор из трёх напоминаний для комплексных тестов.
    static let samples: [ReminderItem] = [
        sample,
        ReminderItem(
            id: "sample-2",
            listName: "Работа",
            title: "Отчёт",
            priority: 0,
            isCompleted: true
        ),
        ReminderItem(
            id: "sample-3",
            listName: "Здоровье",
            title: "Купить витамины",
            notes: "Витамин D",
            priority: 3,
            isCompleted: false
        ),
    ]
}
