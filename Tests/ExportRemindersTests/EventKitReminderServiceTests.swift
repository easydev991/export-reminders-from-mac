import EventKit
@testable import ExportReminders
import Foundation
import Testing

@Test("Маппинг EKReminder → ReminderItem с заполненными полями")
func mappingEKReminderToReminderItem() throws {
    let store = EKEventStore()
    let ekReminder = EKReminder(eventStore: store)
    ekReminder.title = "Купить молоко"
    ekReminder.notes = "Лучше безлактозное"

    let calendar = try #require(store.defaultCalendarForNewReminders())
    ekReminder.calendar = calendar

    var dueComponents = DateComponents()
    dueComponents.year = 2026
    dueComponents.month = 6
    dueComponents.day = 25
    dueComponents.hour = 10
    dueComponents.minute = 30
    dueComponents.timeZone = TimeZone(secondsFromGMT: 0)
    ekReminder.dueDateComponents = dueComponents
    ekReminder.priority = 5
    ekReminder.isCompleted = false
    ekReminder.url = URL(string: "https://example.com")

    let rule = EKRecurrenceRule(
        recurrenceWith: .daily,
        interval: 1,
        end: nil
    )
    ekReminder.recurrenceRules = [rule]

    let service = EventKitReminderService(store: store)
    let item = service.mapToReminderItem(ekReminder)

    #expect(item.title == "Купить молоко")
    #expect(item.notes == "Лучше безлактозное")
    #expect(item.listName == calendar.title)
    #expect(item.priority == 5)
    #expect(!item.isCompleted)
    #expect(item.url == "https://example.com")
    #expect(item.recurrenceRule != nil)
    #expect(item.dueDate != nil)
}

@Test("Маппинг EKReminder → ReminderItem с минимальными полями")
func mappingEKReminderMinimal() throws {
    let store = EKEventStore()
    let ekReminder = EKReminder(eventStore: store)
    ekReminder.title = "Простая задача"
    let calendar2 = try #require(store.defaultCalendarForNewReminders())
    ekReminder.calendar = calendar2
    ekReminder.isCompleted = false
    ekReminder.priority = 0

    let service = EventKitReminderService(store: store)
    let item = service.mapToReminderItem(ekReminder)

    #expect(item.title == "Простая задача")
    #expect(item.notes == nil)
    #expect(item.dueDate == nil)
    #expect(item.completionDate == nil)
    #expect(item.url == nil)
    #expect(item.recurrenceRule == nil)
}

@Test("Маппинг EKCalendar → ReminderList")
func mappingEKCalendarToReminderList() throws {
    let store = EKEventStore()
    let calendar = try #require(store.defaultCalendarForNewReminders())

    let service = EventKitReminderService(store: store)
    let list = service.mapToReminderList(calendar)

    #expect(list.title == calendar.title)
    #expect(list.color != nil)
}
