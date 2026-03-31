// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "SymphonyKanban",
    platforms: [
        .macOS(.v14)
    ],
    products: [
        .library(
            name: "SymphonyKanban",
            targets: ["SymphonyKanban"]
        ),
        .executable(
            name: "symphony",
            targets: ["SymphonyCLI"]
        )
    ],
    dependencies: [
        .package(
            url: "ssh://git@github.com/More-Coin/KanbanArchitectureLinter.git",
            from: "0.1.0"
        )
    ],
    targets: [
        .target(
            name: "SymphonyKanban",
            dependencies: [],
            path: "SymphonyKanban",
            exclude: [
                "App/README_App.md",
                "App/Entrypoints/UI",
                "Application/README_Application.md",
                "Assets.xcassets",
                "Documentation",
                "Domain/README_Domain.md",
                "Infrastructure/README_Infrastructure.md",
                "Presentation/README_Presentation.md",
                "SymphonyKanban.entitlements"
            ]
        ),
        .executableTarget(
            name: "SymphonyCLI",
            dependencies: ["SymphonyKanban"],
            path: "Executables/SymphonyCLI"
        ),
        .testTarget(
            name: "SymphonyKanbanTests",
            dependencies: [
                "SymphonyKanban"
            ],
            path: "SymphonyKanbanTests"
        )
    ]
)
