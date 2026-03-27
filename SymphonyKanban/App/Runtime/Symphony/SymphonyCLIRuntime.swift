import Foundation

struct SymphonyCLIRuntime {
    private let controller: SymphonyStartupController

    init(controller: SymphonyStartupController) {
        self.controller = controller
    }

    func run(arguments: [String]) -> Int32 {
        controller.run(
            arguments: arguments,
            currentWorkingDirectoryPath: FileManager.default.currentDirectoryPath
        )
    }
}
