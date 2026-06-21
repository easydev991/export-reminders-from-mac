@testable import ExportReminders
import Testing

extension ReminderItem: CustomTestStringConvertible {
    public var testDescription: String {
        "ReminderItem(id: \(id), title: \(title), list: \(listName))"
    }
}

extension ReminderList: CustomTestStringConvertible {
    public var testDescription: String {
        "ReminderList(id: \(id), title: \(title))"
    }
}
