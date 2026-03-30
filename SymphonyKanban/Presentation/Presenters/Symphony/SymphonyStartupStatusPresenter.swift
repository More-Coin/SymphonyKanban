import Foundation

public struct SymphonyStartupStatusPresenter {
    public init() {}

    public func present(
        _ executionResult: SymphonyStartupExecutionResultContract
    ) -> SymphonyStartupStatusViewModel {
        switch executionResult.result.state {
        case .ready:
            return SymphonyStartupStatusViewModel(
                state: .ready,
                title: "Workspaces Ready",
                message: readyMessage(for: executionResult),
                currentWorkingDirectoryPath: executionResult.workspaceLocator.currentWorkingDirectoryPath,
                explicitWorkflowPath: executionResult.workspaceLocator.explicitWorkflowPath,
                activeBindingCount: executionResult.result.activeBindingCount,
                readyBindingCount: executionResult.result.readyBindingCount,
                failedBindingCount: executionResult.result.failedBindingCount,
                boundScopeNames: executionResult.activeBindings.map(\.workspaceBinding.scopeName),
                resolvedWorkflowPaths: executionResult.activeBindings.compactMap {
                    $0.workflowConfiguration?.workflowDefinition.resolvedPath
                },
                trackerStatusLabels: executionResult.activeBindings.compactMap {
                    $0.trackerAuthStatus?.statusMessage
                }
            )
        case .setupRequired:
            return SymphonyStartupStatusViewModel(
                state: .setupRequired,
                title: "Workspace Setup Required",
                message: "This workspace is not linked to a tracker scope yet. Create or choose a saved binding before Symphony starts loading live issue data.",
                currentWorkingDirectoryPath: executionResult.workspaceLocator.currentWorkingDirectoryPath,
                explicitWorkflowPath: executionResult.workspaceLocator.explicitWorkflowPath,
                activeBindingCount: 0,
                readyBindingCount: 0,
                failedBindingCount: 0,
                boundScopeNames: [],
                resolvedWorkflowPaths: [],
                trackerStatusLabels: []
            )
        }
    }

    public func presentError(
        _ error: any Error,
        workspaceLocator: SymphonyWorkspaceLocatorContract
    ) -> SymphonyStartupStatusViewModel {
        SymphonyStartupStatusViewModel(
            state: .failed,
            title: "Startup Failed",
            message: structuredMessage(for: error),
            currentWorkingDirectoryPath: workspaceLocator.currentWorkingDirectoryPath,
            explicitWorkflowPath: workspaceLocator.explicitWorkflowPath,
            activeBindingCount: 0,
            readyBindingCount: 0,
            failedBindingCount: 0,
            boundScopeNames: [],
            resolvedWorkflowPaths: [],
            trackerStatusLabels: []
        )
    }

    private func readyMessage(
        for executionResult: SymphonyStartupExecutionResultContract
    ) -> String {
        var parts: [String] = []

        if executionResult.result.activeBindingCount > 0 {
            parts.append(
                "Loaded \(executionResult.result.readyBindingCount) of \(executionResult.result.activeBindingCount) bindings."
            )
        }

        let scopeNames = executionResult.activeBindings
            .map(\.workspaceBinding.scopeName)
            .filter { $0.isEmpty == false }
        if scopeNames.isEmpty == false {
            parts.append("Scopes: \(scopeNames.joined(separator: ", ")).")
        }

        let failedScopeNames = executionResult.activeBindings
            .filter { !$0.isReady }
            .map(\.workspaceBinding.scopeName)
            .filter { $0.isEmpty == false }
        if failedScopeNames.isEmpty == false {
            parts.append("Degraded: \(failedScopeNames.joined(separator: ", ")).")
        }

        if parts.isEmpty {
            return "Startup validation completed successfully."
        }

        return parts.joined(separator: " ")
    }

    private func structuredMessage(
        for error: any Error
    ) -> String {
        if let structuredError = error as? any StructuredErrorProtocol {
            guard let details = structuredError.details,
                  details.isEmpty == false else {
                return structuredError.message
            }

            return "\(structuredError.message) \(details)"
        }

        return error.localizedDescription
    }
}
