import Foundation

/// Экспортёр в JSON-формат.
///
/// Использует `JSONEncoder` с `dateEncodingStrategy = .iso8601`,
/// `outputFormatting = [.prettyPrinted, .withoutEscapingSlashes]`.
/// Опциональные поля сериализуются через `encodeIfPresent`.
struct JSONExporter: ReminderExporterProtocol {
    func export(_ reminders: [ReminderItem], to url: URL) throws {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        encoder.outputFormatting = [.prettyPrinted, .withoutEscapingSlashes]

        let data = try encoder.encode(reminders)
        try data.write(to: url, options: .atomic)
    }
}
