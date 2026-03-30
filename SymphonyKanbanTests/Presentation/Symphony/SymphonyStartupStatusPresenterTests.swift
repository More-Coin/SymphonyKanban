import Foundation
import Testing
@testable import SymphonyKanban

@Suite
struct SymphonyStartupStatusPresenterTests {
    @Test
    func startupStatusPresenterMapsReadyExecutionResult() {
        let presenter = SymphonyStartupStatusPresenter()
        let activeBinding = SymphonyActiveWorkspaceBindingContextContract(
            workspaceBinding: SymphonyWorkspaceTrackerBindingContract(
                workspacePath: "/tmp/nara-ios",
                explicitWorkflowPath: "/tmp/nara-ios/WORKFLOW.md",
                trackerKind: "linear",
                scopeKind: "team",
                scopeIdentifier: "team-1",
                scopeName: "Nara IOS"
            ),
            effectiveWorkspaceLocator: SymphonyWorkspaceLocatorContract(
                currentWorkingDirectoryPath: "/tmp/nara-ios",
                explicitWorkflowPath: "/tmp/nara-ios/WORKFLOW.md"
            ),
            workflowConfiguration: SymphonyOrchestratorRuntimeTestSupport.makeWorkflowConfiguration(),
            trackerAuthStatus: SymphonyTrackerAuthStatusContract(
                trackerKind: "linear",
                state: .connected,
                statusMessage: "Connected to Linear."
            )
        )
        let executionResult = SymphonyStartupExecutionResultContract(
            result: SymphonyStartupResultContract(
                state: .ready,
                activeBindingCount: 1,
                readyBindingCount: 1,
                failedBindingCount: 0
            ),
            workspaceLocator: SymphonyWorkspaceLocatorContract(
                currentWorkingDirectoryPath: "/tmp/nara-ios",
                explicitWorkflowPath: "/tmp/nara-ios/WORKFLOW.md"
            ),
            activeBindings: [activeBinding]
        )

        let viewModel = presenter.present(executionResult)

        #expect(viewModel.state == SymphonyStartupStatusViewModel.State.ready)
        #expect(viewModel.title == "Workspaces Ready")
        #expect(viewModel.currentWorkingDirectoryPath == "/tmp/nara-ios")
        #expect(viewModel.explicitWorkflowPath == "/tmp/nara-ios/WORKFLOW.md")
        #expect(viewModel.activeBindingCount == 1)
        #expect(viewModel.readyBindingCount == 1)
        #expect(viewModel.failedBindingCount == 0)
        #expect(viewModel.boundScopeNames == ["Nara IOS"])
        #expect(viewModel.trackerStatusLabels == ["Connected to Linear."])
        #expect(viewModel.message.contains("Loaded 1 of 1 bindings."))
    }

    @Test
    func startupStatusPresenterMapsSetupRequiredExecutionResult() {
        let presenter = SymphonyStartupStatusPresenter()
        let executionResult = SymphonyStartupExecutionResultContract(
            result: SymphonyStartupResultContract(
                state: .setupRequired,
                activeBindingCount: 0,
                readyBindingCount: 0,
                failedBindingCount: 0
            ),
            workspaceLocator: SymphonyWorkspaceLocatorContract(
                currentWorkingDirectoryPath: "/tmp/nara-server",
                explicitWorkflowPath: nil
            ),
            activeBindings: []
        )

        let viewModel = presenter.present(executionResult)

        #expect(viewModel.state == .setupRequired)
        #expect(viewModel.title == "Workspace Setup Required")
        #expect(viewModel.currentWorkingDirectoryPath == "/tmp/nara-server")
        #expect(viewModel.explicitWorkflowPath == nil)
        #expect(viewModel.boundScopeNames.isEmpty)
        #expect(viewModel.trackerStatusLabels.isEmpty)
    }

    @Test
    func startupStatusPresenterMapsErrorsToFailedViewModel() {
        let presenter = SymphonyStartupStatusPresenter()
        let workspaceLocator = SymphonyWorkspaceLocatorContract(
            currentWorkingDirectoryPath: "/tmp/nara-ios",
            explicitWorkflowPath: "/tmp/nara-ios/WORKFLOW.md"
        )

        let viewModel = presenter.presentError(
            SymphonyStartupApplicationError.missingTrackerProjectIdentifier,
            workspaceLocator: workspaceLocator
        )

        #expect(viewModel.state == .failed)
        #expect(viewModel.title == "Startup Failed")
        #expect(
            viewModel.message == "The workflow configuration is missing the tracker project identifier. Set the tracker project identifier in the workflow configuration."
        )
        #expect(viewModel.currentWorkingDirectoryPath == "/tmp/nara-ios")
        #expect(viewModel.explicitWorkflowPath == "/tmp/nara-ios/WORKFLOW.md")
    }
}
