import ArgumentParser

/// Поддерживаемые форматы экспорта.
enum Format: String, ExpressibleByArgument, CaseIterable {
    case json
    case csv
}
