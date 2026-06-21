@testable import ExportReminders
import Testing

extension ReminderItem: CustomTestStringConvertible {
    public var testDescription: String {
        "ReminderItem(id: \(id), title: \(title), list: \(listName))"
    }
}
