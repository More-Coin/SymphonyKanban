import Foundation
import Testing
@testable import SymphonyKanban

@Suite(.serialized)
struct SymphonyStartupControllerTests {
    @Test
    func startupControllerReturnsSuccessForValidMinimalWorkflow() throws {
        let fileURL = try SymphonyStartupFlowTestSupport.makeWorkflowFile(
            named: "ValidStartupWorkflow.md",
            contents: """
            ---
            tracker:
              kind: linear
              project_slug: project
            ---
            Prompt body.
            """
        )

        let workingDirectoryPath = SymphonyStartupFlowTestSupport.temporaryDirectory().path
        let controller = SymphonyStartupFlowTestSupport.makeController(
            workspaceTrackerBindingPort: WorkspaceTrackerBindingPortSpy(
                listedBindings: [SymphonyStartupFlowTestSupport.makeWorkspaceBinding(
                    workspacePath: workingDirectoryPath
                )]
            )
        )

        let (stdoutOutput, exitCode) = SymphonyStartupFlowTestSupport.captureStandardOutput {
            controller.run(
                arguments: ["symphony", fileURL.path],
                currentWorkingDirectoryPath: workingDirectoryPath
            )
        }

        #expect(exitCode == EXIT_SUCCESS)
        #expect(
            stdoutOutput.contains(
                "component=symphony event=startup_validation outcome=completed"
            )
        )
        #expect(stdoutOutput.contains("active_bindings=1"))
        #expect(stdoutOutput.contains("ready_bindings=1"))
        #expect(stdoutOutput.contains("failed_bindings=0"))
    }

    @Test
    func startupControllerUsesDefaultWorkflowPathFromCurrentWorkingDirectory() throws {
        let workingDirectoryURL = SymphonyStartupFlowTestSupport.temporaryDirectory()
        let fileURL = workingDirectoryURL.appendingPathComponent("WORKFLOW.md")
        try """
        ---
        tracker:
          kind: linear
          project_slug: project
        ---
        Prompt body.
        """.write(to: fileURL, atomically: true, encoding: .utf8)

        let controller = SymphonyStartupFlowTestSupport.makeController(
            workspaceTrackerBindingPort: WorkspaceTrackerBindingPortSpy(
                listedBindings: [SymphonyStartupFlowTestSupport.makeWorkspaceBinding(
                    workspacePath: workingDirectoryURL.path
                )]
            )
        )

        let (stdoutOutput, exitCode) = SymphonyStartupFlowTestSupport.captureStandardOutput {
            controller.run(
                arguments: ["symphony"],
                currentWorkingDirectoryPath: workingDirectoryURL.path
            )
        }

        #expect(exitCode == EXIT_SUCCESS)
        #expect(
            stdoutOutput.contains(
                "component=symphony event=startup_validation outcome=completed"
            )
        )
        #expect(stdoutOutput.contains("active_bindings=1"))
        #expect(stdoutOutput.contains("ready_bindings=1"))
        #expect(stdoutOutput.contains("failed_bindings=0"))
    }

    @Test
    func startupControllerReturnsFailureForInvalidStartupConfig() throws {
        let fileURL = try SymphonyStartupFlowTestSupport.makeWorkflowFile(
            named: "InvalidStartupWorkflow.md",
            contents: """
            ---
            tracker:
              kind: linear
            ---
            Prompt body.
            """
        )

        let workingDirectoryPath = SymphonyStartupFlowTestSupport.temporaryDirectory().path
        let controller = SymphonyStartupFlowTestSupport.makeController(
            workspaceTrackerBindingPort: WorkspaceTrackerBindingPortSpy(
                listedBindings: [SymphonyStartupFlowTestSupport.makeWorkspaceBinding(
                    workspacePath: workingDirectoryPath
                )]
            )
        )

        let (stdoutOutput, exitCode) = SymphonyStartupFlowTestSupport.captureStandardOutput {
            controller.run(
                arguments: ["symphony", fileURL.path],
                currentWorkingDirectoryPath: workingDirectoryPath
            )
        }

        #expect(exitCode == EXIT_SUCCESS)
        #expect(
            stdoutOutput.contains(
                "component=symphony event=startup_validation outcome=completed"
            )
        )
        #expect(stdoutOutput.contains("ready_bindings=0"))
        #expect(stdoutOutput.contains("failed_bindings=1"))
    }

    @Test
    func startupControllerReturnsTypedFailureWhenDefaultWorkflowFileIsMissing() {
        let workingDirectoryPath = SymphonyStartupFlowTestSupport.temporaryDirectory().path
        let controller = SymphonyStartupFlowTestSupport.makeController(
            workspaceTrackerBindingPort: WorkspaceTrackerBindingPortSpy(
                listedBindings: [SymphonyStartupFlowTestSupport.makeWorkspaceBinding(
                    workspacePath: workingDirectoryPath
                )]
            )
        )

        let (stdoutOutput, exitCode) = SymphonyStartupFlowTestSupport.captureStandardOutput {
            controller.run(
                arguments: ["symphony"],
                currentWorkingDirectoryPath: workingDirectoryPath
            )
        }

        #expect(exitCode == EXIT_SUCCESS)
        #expect(
            stdoutOutput.contains(
                "component=symphony event=startup_validation outcome=completed"
            )
        )
        #expect(stdoutOutput.contains("ready_bindings=0"))
        #expect(stdoutOutput.contains("failed_bindings=1"))
    }

    @Test
    func startupControllerReturnsStructuredFailureForInvalidArguments() {
        let controller = SymphonyStartupFlowTestSupport.makeController()

        let (stderrOutput, exitCode) = SymphonyStartupFlowTestSupport.captureStandardError {
            controller.run(
                arguments: ["symphony", "one", "two"],
                currentWorkingDirectoryPath: SymphonyStartupFlowTestSupport.temporaryDirectory().path
            )
        }

        #expect(exitCode == EXIT_FAILURE)
        #expect(
            stderrOutput.contains(
                """
                component=symphony event=startup_validation outcome=failed \
                error_code=symphony.presentation.invalid_arguments \
                reason="Usage: symphony [path-to-WORKFLOW.md]" \
                retryable=false
                """
            )
        )
        #expect(!stderrOutput.contains("Provide zero or one positional workflow path argument."))
    }

    @Test
    func startupControllerDoesNotSurfaceRawYAMLDetailsByDefault() throws {
        let fileURL = try SymphonyStartupFlowTestSupport.makeWorkflowFile(
            named: "InvalidYAMLStartupWorkflow.md",
            contents: """
            ---
            tracker:
              kind: [linear
            ---
            Prompt body should stay out of logs.
            """
        )

        let controller = SymphonyStartupFlowTestSupport.makeController(
            workspaceTrackerBindingPort: WorkspaceTrackerBindingPortSpy(
                listedBindings: [SymphonyStartupFlowTestSupport.makeWorkspaceBinding(
                    workspacePath: SymphonyStartupFlowTestSupport.temporaryDirectory().path
                )]
            )
        )

        let (stdoutOutput, exitCode) = SymphonyStartupFlowTestSupport.captureStandardOutput {
            controller.run(
                arguments: ["symphony", fileURL.path],
                currentWorkingDirectoryPath: SymphonyStartupFlowTestSupport.temporaryDirectory().path
            )
        }

        #expect(exitCode == EXIT_SUCCESS)
        #expect(stdoutOutput.contains("ready_bindings=0"))
        #expect(stdoutOutput.contains("failed_bindings=1"))
    }

    @Test
    func startupControllerReturnsBlockedSetupRequiredWhenBindingMissing() throws {
        let fileURL = try SymphonyStartupFlowTestSupport.makeWorkflowFile(
            named: "StartupWorkflow.md",
            contents: """
            ---
            tracker:
              kind: linear
              project_slug: project
            ---
            Prompt body.
            """
        )

        let controller = SymphonyStartupFlowTestSupport.makeController()
        let workingDirectoryPath = SymphonyStartupFlowTestSupport.temporaryDirectory().path

        let (stdoutOutput, exitCode) = SymphonyStartupFlowTestSupport.captureStandardOutput {
            controller.run(
                arguments: ["symphony", fileURL.path],
                currentWorkingDirectoryPath: workingDirectoryPath
            )
        }

        #expect(exitCode == EXIT_FAILURE)
        #expect(
            stdoutOutput.contains(
                "component=symphony event=startup_validation outcome=blocked"
            )
        )
        #expect(stdoutOutput.contains("startup_state=setupRequired"))
    }
}
