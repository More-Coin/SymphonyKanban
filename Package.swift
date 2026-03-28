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
        ),
        .executable(
            name: "kanban-architecture-linter",
            targets: ["KanbanArchitectureLinterCLI"]
        )
    ],
    dependencies: [
        .package(url: "https://github.com/swiftlang/swift-syntax.git", exact: "603.0.0")
    ],
    targets: [
        .target(
            name: "SymphonyKanban",
            dependencies: [
                .product(name: "SwiftParser", package: "swift-syntax"),
                .product(name: "SwiftSyntax", package: "swift-syntax")
            ],
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
        .executableTarget(
            name: "KanbanArchitectureLinterCLI",
            dependencies: ["SymphonyKanban"],
            path: "Executables/KanbanArchitectureLinterCLI"
        ),
        .testTarget(
            name: "SymphonyKanbanTests",
            dependencies: ["SymphonyKanban"],
            path: "SymphonyKanbanTests"
        )
    ]
)
