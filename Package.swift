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
                "RandomizerApp.swift",
                "Views/ContentView.swift",
                "Views/Components/RatingView.swift",
            ],
            sources: [
                "Models/SessionStateModel.swift",
                "Services/RandomizerService.swift",
                "Utils/TimeHelper.swift",
                "Views/RandomizerView.swift",
            ]
        ),
        .testTarget(
            name: "RandomizerCoreTests",
            dependencies: ["RandomizerCore"],
            path: "RandomizerTests"
        ),
    ]
)
