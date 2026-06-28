import ArgumentParser

/// Поддерживаемые форматы экспорта.
enum Format: String, ExpressibleByArgument {
    case json
    case csv
    case tasksOrg = "tasks-org"
}
