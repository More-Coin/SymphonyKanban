import Foundation

public struct SymphonyStartupController {
    private let startupService: SymphonyStartupService
    private let renderer: SymphonyStartupRenderer

    public init(
        startupService: SymphonyStartupService,
        renderer: SymphonyStartupRenderer
    ) {
        self.startupService = startupService
        self.renderer = renderer
    }

    public func run(
        arguments: [String],
        currentWorkingDirectoryPath: String
    ) -> Int32 {
        do {
            let command = try SymphonyStartupCommandDTO(
                arguments: arguments,
                currentWorkingDirectoryPath: currentWorkingDirectoryPath
            )
            let result = try startupService.execute(command.workspaceLocatorContract())
            return renderer.render(result)
        } catch {
            return renderer.renderError(error)
        }
    }
}
