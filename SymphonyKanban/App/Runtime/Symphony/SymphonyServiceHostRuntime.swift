import Foundation

struct SymphonyServiceHostRuntime {
    typealias StartRuntime = @Sendable (
        SymphonyActiveWorkspaceBindingContextContract
    ) -> Void
    typealias KeepRunning = @Sendable () -> Int32

    private let startupService: SymphonyStartupService
    private let renderer: SymphonyStartupRenderer
    private let startRuntime: StartRuntime
    private let keepRunning: KeepRunning

    init(
        startupService: SymphonyStartupService,
        renderer: SymphonyStartupRenderer,
        startRuntime: @escaping StartRuntime,
        keepRunning: @escaping KeepRunning
    ) {
        self.startupService = startupService
        self.renderer = renderer
        self.startRuntime = startRuntime
        self.keepRunning = keepRunning
    }

    func run(arguments: [String]) -> Int32 {
        do {
            let command = try SymphonyStartupCommandDTO(
                arguments: arguments,
                currentWorkingDirectoryPath: FileManager.default.currentDirectoryPath
            )
            let executionResult = try startupService.execute(command.workspaceLocatorContract())
            let exitCode = renderer.render(executionResult.result)

            guard executionResult.result.state == .ready else {
                return exitCode
            }

            guard let primaryBindingContext = primaryBindingContext(
                from: executionResult.activeBindings,
                matching: command.workspaceLocatorContract().currentWorkingDirectoryPath
            ) else {
                return EXIT_FAILURE
            }

            startRuntime(primaryBindingContext)
            return keepRunning()
        } catch {
            return renderer.renderError(error)
        }
    }

    private func primaryBindingContext(
        from activeBindings: [SymphonyActiveWorkspaceBindingContextContract],
        matching workspacePath: String
    ) -> SymphonyActiveWorkspaceBindingContextContract? {
        let normalizedWorkspacePath = normalizedPath(from: workspacePath)

        return activeBindings.first {
            $0.isReady
                && normalizedPath(from: $0.workspaceBinding.workspacePath) == normalizedWorkspacePath
        }
    }

    private func normalizedPath(
        from rawPath: String
    ) -> String {
        let trimmedPath = rawPath.trimmingCharacters(in: .whitespacesAndNewlines)
        let homeExpandedPath = NSString(string: trimmedPath).expandingTildeInPath
        return URL(fileURLWithPath: homeExpandedPath)
            .resolvingSymlinksInPath()
            .standardizedFileURL
            .path
    }
}
