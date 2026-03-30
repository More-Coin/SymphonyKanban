import Foundation
import Testing
@testable import SymphonyKanban

@Suite
struct SymphonyStartupServiceTests {
    @Test
    func startupServiceReturnsSetupRequiredBeforeWorkflowResolutionWhenBindingMissing() throws {
        let service = SymphonyStartupFlowTestSupport.makeStartupService()

        let result = try service.execute(
            SymphonyWorkspaceLocatorContract(
                currentWorkingDirectoryPath: "/tmp/no-binding",
                explicitWorkflowPath: "/tmp/no-binding/WORKFLOW.md"
            )
        )

        #expect(result.result.state == .setupRequired)
        #expect(result.result.activeBindingCount == 0)
        #expect(result.activeBindings.isEmpty)
    }

    @Test
    func startupServiceResolvesWorkflowAndTrackerWhenBindingExists() throws {
        let fileURL = try SymphonyStartupFlowTestSupport.makeWorkflowFile(
            named: "StartupServiceWorkflow.md",
            contents: """
            ---
            tracker:
              kind: linear
              project_slug: project
            ---
            Prompt body.
            """
        )
        let workspacePath = SymphonyStartupFlowTestSupport.temporaryDirectory().path
        let binding = SymphonyStartupFlowTestSupport.makeWorkspaceBinding(workspacePath: workspacePath)
        let service = SymphonyStartupFlowTestSupport.makeStartupService(
            workspaceTrackerBindingPort: WorkspaceTrackerBindingPortSpy(listedBindings: [binding])
        )

        let result = try service.execute(
            SymphonyWorkspaceLocatorContract(
                currentWorkingDirectoryPath: workspacePath,
                explicitWorkflowPath: fileURL.path
            )
        )

        #expect(result.result.state == .ready)
        #expect(result.result.activeBindingCount == 1)
        #expect(result.result.readyBindingCount == 1)
        #expect(result.result.failedBindingCount == 0)
        #expect(result.activeBindings.count == 1)
        #expect(result.activeBindings.first?.workflowConfiguration?.workflowDefinition.resolvedPath == fileURL.path)
        #expect(result.activeBindings.first?.trackerAuthStatus?.state == .connected)
        #expect(result.activeBindings.first?.workspaceBinding == binding)
    }
}
