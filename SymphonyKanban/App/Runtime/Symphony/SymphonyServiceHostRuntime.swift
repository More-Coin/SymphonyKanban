import Foundation

struct SymphonyServiceHostRuntime {
    typealias StartRuntime = @Sendable (
        SymphonyStartupCommandContract,
        SymphonyWorkflowConfigurationResultContract
    ) -> Void
    typealias KeepRunning = @Sendable () -> Int32

    private let resolveWorkflowConfigurationUseCase: ResolveSymphonyWorkflowConfigurationUseCase
    private let validateStartupConfigurationUseCase: ValidateSymphonyStartupConfigurationUseCase
    private let renderer: SymphonyStartupRenderer
    private let startRuntime: StartRuntime
    private let keepRunning: KeepRunning

    init(
        resolveWorkflowConfigurationUseCase: ResolveSymphonyWorkflowConfigurationUseCase,
        validateStartupConfigurationUseCase: ValidateSymphonyStartupConfigurationUseCase,
        renderer: SymphonyStartupRenderer,
        startRuntime: @escaping StartRuntime,
        keepRunning: @escaping KeepRunning
    ) {
        self.resolveWorkflowConfigurationUseCase = resolveWorkflowConfigurationUseCase
        self.validateStartupConfigurationUseCase = validateStartupConfigurationUseCase
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
            let startupCommand = command.commandContract()

            let workflowConfiguration = try resolveWorkflowConfigurationUseCase.resolveValidated(
                SymphonyWorkflowConfigurationRequestContract(
                    explicitWorkflowPath: startupCommand.explicitWorkflowPath,
                    currentWorkingDirectoryPath: startupCommand.currentWorkingDirectoryPath
                ),
                validateStartupConfigurationUseCase: validateStartupConfigurationUseCase
            )
            let startupResult = SymphonyStartupResultContract(
                resolvedWorkflowPath: workflowConfiguration.workflowDefinition.resolvedPath
            )

            _ = renderer.render(startupResult)
            startRuntime(startupCommand, workflowConfiguration)
            return keepRunning()
        } catch {
            return renderer.renderError(error)
        }
    }
}
