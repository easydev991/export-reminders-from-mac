import Foundation

struct TasksOrgBackup: Codable, Equatable {
    let version: Int
    let timestamp: Int64
    let data: TasksOrgData
}

struct TasksOrgData: Codable, Equatable {
    let tasks: [TasksOrgTaskWrapper]
    let caldavAccounts: [CaldavAccount]
    let caldavCalendars: [CaldavCalendar]
    let places: [String]
    let tags: [String]
    let filters: [String]
    let taskListMetadata: [String]
    let taskAttachments: [String]
    let intPrefs: [String: Int]
    let longPrefs: [String: Int64]
    let stringPrefs: [String: String]
    let boolPrefs: [String: Bool]
    let setPrefs: [String: [String]]

    init(
        tasks: [TasksOrgTaskWrapper] = [],
        caldavAccounts: [CaldavAccount] = [],
        caldavCalendars: [CaldavCalendar] = [],
        places: [String] = [],
        tags: [String] = [],
        filters: [String] = [],
        taskListMetadata: [String] = [],
        taskAttachments: [String] = [],
        intPrefs: [String: Int] = [:],
        longPrefs: [String: Int64] = [:],
        stringPrefs: [String: String] = [:],
        boolPrefs: [String: Bool] = [:],
        setPrefs: [String: [String]] = [:]
    ) {
        self.tasks = tasks
        self.caldavAccounts = caldavAccounts
        self.caldavCalendars = caldavCalendars
        self.places = places
        self.tags = tags
        self.filters = filters
        self.taskListMetadata = taskListMetadata
        self.taskAttachments = taskAttachments
        self.intPrefs = intPrefs
        self.longPrefs = longPrefs
        self.stringPrefs = stringPrefs
        self.boolPrefs = boolPrefs
        self.setPrefs = setPrefs
    }
}

struct TasksOrgTaskWrapper: Codable, Equatable {
    let task: TasksOrgTask
    let alarms: [String]
    let geofences: [String]
    let tags: [String]
    let comments: [String]
    let attachments: [String]
    let caldavTasks: [CaldavTask]
}
