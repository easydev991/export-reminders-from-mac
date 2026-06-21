// swift-tools-version: 5.9

import PackageDescription

let package = Package(
    name: "export-reminders",
    platforms: [
        .macOS(.v14),
    ],
    dependencies: [
        .package(url: "https://github.com/apple/swift-argument-parser", from: "1.2.0"),
    ],
    targets: [
        .executableTarget(
            name: "ExportReminders",
            dependencies: [
                .product(name: "ArgumentParser", package: "swift-argument-parser"),
            ],
            linkerSettings: [
                .linkedFramework("EventKit"),
            ]
        ),
        .testTarget(
            name: "ExportRemindersTests",
            dependencies: [
                .target(name: "ExportReminders"),
            ]
        ),
    ]
)
