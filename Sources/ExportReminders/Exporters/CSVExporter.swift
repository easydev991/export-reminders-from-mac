import Foundation

/// Экспортёр в CSV-формат.
///
/// Заголовки: 12 полей ReminderItem в фиксированном порядке.
/// Значения с запятыми, кавычками или переводами строк экранируются.
/// nil-поля записываются как пустая строка.
/// Даты — ISO 8601 (UTC).
struct CSVExporter: ReminderExporterProtocol {
    private let dateFormatter: ISO8601DateFormatter = {
        let fmt = ISO8601DateFormatter()
        fmt.formatOptions = [.withInternetDateTime]
        return fmt
    }()

    private let headers: [String] = [
        "id", "listName", "title", "notes", "dueDate", "completionDate",
        "creationDate", "modificationDate", "priority", "isCompleted",
        "recurrenceRule", "url",
    ]

    func export(_ reminders: [ReminderItem], to url: URL) throws {
        var lines: [String] = []
        lines.append(headers.map(escapeField).joined(separator: ","))

        for reminder in reminders {
            lines.append(csvRow(for: reminder))
        }

        let content = lines.joined(separator: "\n")
        try content.write(to: url, atomically: true, encoding: .utf8)
    }

    // MARK: - Private

    private func csvRow(for item: ReminderItem) -> String {
        let fields: [String] = [
            item.id,
            item.listName,
            item.title,
            item.notes ?? "",
            item.dueDate.map { dateFormatter.string(from: $0) } ?? "",
            item.completionDate.map { dateFormatter.string(from: $0) } ?? "",
            item.creationDate.map { dateFormatter.string(from: $0) } ?? "",
            item.modificationDate.map { dateFormatter.string(from: $0) } ?? "",
            String(item.priority),
            String(item.isCompleted),
            item.recurrenceRule ?? "",
            item.url ?? "",
        ]
        return fields.map(escapeField).joined(separator: ",")
    }

    private func escapeField(_ value: String) -> String {
        if value.contains(",") || value.contains("\"") || value.contains("\n") {
            let escaped = value.replacingOccurrences(of: "\"", with: "\"\"")
            return "\"\(escaped)\""
        }
        return value
    }
}
