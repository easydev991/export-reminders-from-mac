import Foundation

struct TasksOrgTask: Codable, Equatable {
    let title: String
    let dueDate: Int64?
    let creationDate: Int64?
    let modificationDate: Int64?
    let completionDate: Int64?
    let notes: String?
    let recurrence: String?
    let remoteId: String
}
