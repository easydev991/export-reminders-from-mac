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
        self.completionDate = completionDate
        self.creationDate = creationDate
        self.modificationDate = modificationDate
        self.priority = priority
        self.isCompleted = isCompleted
        self.recurrenceRule = recurrenceRule
        self.url = url
    }

    enum CodingKeys: String, CodingKey {
        case id, listName, title, notes, dueDate, completionDate
        case creationDate, modificationDate, priority, isCompleted
        case recurrenceRule, url
    }

    func encode(to encoder: any Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(listName, forKey: .listName)
        try container.encode(title, forKey: .title)
        try container.encodeIfPresent(notes, forKey: .notes)
        try container.encodeIfPresent(dueDate, forKey: .dueDate)
        try container.encodeIfPresent(completionDate, forKey: .completionDate)
        try container.encodeIfPresent(creationDate, forKey: .creationDate)
        try container.encodeIfPresent(modificationDate, forKey: .modificationDate)
        try container.encode(priority, forKey: .priority)
        try container.encode(isCompleted, forKey: .isCompleted)
        try container.encodeIfPresent(recurrenceRule, forKey: .recurrenceRule)
        try container.encodeIfPresent(url, forKey: .url)
    }
}
