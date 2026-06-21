import ArgumentParser

@main
struct ExportRemindersCLI: ParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "export-reminders",
        abstract: "Export reminders from Apple Reminders to a file."
    )

    func run() throws {
        print("ExportReminders CLI — placeholder. Will be implemented in stage 5.")
    }
}
