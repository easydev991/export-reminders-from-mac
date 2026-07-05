import Foundation

/// Модель одного напоминания.
///
/// Содержит все поля, доступные через EventKit.
/// Опциональные поля сериализуются через `encodeIfPresent` —
/// если значение `nil`, ключ в JSON отсутствует.
struct ReminderItem: Codable, Equatable {
    let id: String
    let listName: String
    let title: String
    let notes: String?
    let dueDate: Date?
    let startDate: Date?
    let completionDate: Date?
    let creationDate: Date?
    let modificationDate: Date?
    let priority: Int
    let isCompleted: Bool
    let recurrenceRule: String?
    let url: String?
    init(
        id: String,
        listName: String,
        title: String,
        notes: String? = nil,
        dueDate: Date? = nil,
        startDate: Date? = nil,
        completionDate: Date? = nil,
        creationDate: Date? = nil,
        modificationDate: Date? = nil,
        priority: Int = 0,
        isCompleted: Bool,
        recurrenceRule: String? = nil,
        url: String? = nil
    ) {
        self.id = id
        self.listName = listName
        self.title = title
        self.notes = notes
        self.dueDate = dueDate
        self.startDate = startDate
        self.completionDate = completionDate
        self.creationDate = creationDate
        self.modificationDate = modificationDate
        self.priority = priority
        self.isCompleted = isCompleted
        self.recurrenceRule = recurrenceRule
        self.url = url
    }
}
