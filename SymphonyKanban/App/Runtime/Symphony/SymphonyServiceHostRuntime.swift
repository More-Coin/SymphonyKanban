import Foundation

struct SymphonyServiceHostRuntime {
    typealias StartRuntime = @Sendable (
        SymphonyWorkspaceLocatorContract,
        SymphonyWorkflowConfigurationResultContract
    ) -> Void
    typealias KeepRunning = @Sendable () -> Int32

    private let resolveWorkflowConfigurationUseCase: ResolveSymphonyWorkflowConfigurationUseCase
    private let validateStartupConfigurationUseCase: ValidateSymphonyStartupConfigurationUseCase
    private let validateTrackerConnectionUseCase: ValidateSymphonyTrackerConnectionReadinessUseCase
    private let renderer: SymphonyStartupRenderer
    private let startRuntime: StartRuntime
    private let keepRunning: KeepRunning

    init(
        resolveWorkflowConfigurationUseCase: ResolveSymphonyWorkflowConfigurationUseCase,
        validateStartupConfigurationUseCase: ValidateSymphonyStartupConfigurationUseCase,
        validateTrackerConnectionUseCase: ValidateSymphonyTrackerConnectionReadinessUseCase,
        renderer: SymphonyStartupRenderer,
        startRuntime: @escaping StartRuntime,
        keepRunning: @escaping KeepRunning
    ) {
        self.resolveWorkflowConfigurationUseCase = resolveWorkflowConfigurationUseCase
        self.validateStartupConfigurationUseCase = validateStartupConfigurationUseCase
        self.validateTrackerConnectionUseCase = validateTrackerConnectionUseCase
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
            let workspaceLocator = command.workspaceLocatorContract()

            let workflowConfiguration = try resolveWorkflowConfigurationUseCase.resolveValidated(
                workspaceLocator,
                validateStartupConfigurationUseCase: validateStartupConfigurationUseCase
            )
            let trackerAuthStatus = try validateTrackerConnectionUseCase.validate(
                workflowConfiguration.serviceConfig.tracker
            )
            let startupResult = SymphonyStartupResultContract(
                resolvedWorkflowPath: workflowConfiguration.workflowDefinition.resolvedPath,
                trackerAuthStatus: trackerAuthStatus
            )

            _ = renderer.render(startupResult)
            startRuntime(workspaceLocator, workflowConfiguration)
            return keepRunning()
        } catch {
            return renderer.renderError(error)
        }
    }
}
