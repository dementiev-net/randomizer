// swift-tools-version: 6.0

import PackageDescription

let package = Package(
    name: "RandomizerCore",
    platforms: [
        .macOS(.v14),
    ],
    products: [
        .library(
            name: "RandomizerCore",
            targets: ["RandomizerCore"]
        ),
    ],
    targets: [
        .target(
            name: "RandomizerCore",
            path: "Randomizer",
            exclude: [
                "Assets.xcassets",
                "AppWindowID.swift",
                "RandomizerApp.swift",
                "Views/Shared",
                "Views/Main",
                "Views/Journal",
            ],
            sources: [
                "Models/BankrollSettingsFileModel.swift",
                "Models/SessionStateModel.swift",
                "Models/ShotJournalEntry.swift",
                "Services/NotificationService.swift",
                "Services/RandomizerService.swift",
                "Utils/TimeHelper.swift",
                "ViewModels/RandomizerView.swift",
            ]
        ),
        .testTarget(
            name: "RandomizerCoreTests",
            dependencies: ["RandomizerCore"],
            path: "RandomizerTests"
        ),
    ]
)
