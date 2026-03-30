public struct SymphonyStartupStateTransition {
    public init() {}

    public func setupRequired(
        workspaceLocator: SymphonyWorkspaceLocatorContract
    ) -> SymphonyStartupExecutionResultContract {
        SymphonyStartupExecutionResultContract(
            result: SymphonyStartupResultContract(
                state: .setupRequired,
                activeBindingCount: 0,
                readyBindingCount: 0,
                failedBindingCount: 0
            ),
            workspaceLocator: workspaceLocator,
            activeBindings: []
        )
    }

    public func ready(
        workspaceLocator: SymphonyWorkspaceLocatorContract,
        activeBindings: [SymphonyActiveWorkspaceBindingContextContract]
    ) -> SymphonyStartupExecutionResultContract {
        SymphonyStartupExecutionResultContract(
            result: SymphonyStartupResultContract(
                state: .ready,
                activeBindingCount: activeBindings.count,
                readyBindingCount: activeBindings.filter(\.isReady).count,
                failedBindingCount: activeBindings.filter { !$0.isReady }.count
            ),
            workspaceLocator: workspaceLocator,
            activeBindings: activeBindings
        )
    }
}
