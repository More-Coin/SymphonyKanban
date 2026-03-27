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
        let controller = SymphonyStartupFlowTestSupport.makeController()

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
        #expect(stdoutOutput.contains("workflow_path=\"\(fileURL.path)\""))
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

        let controller = SymphonyStartupFlowTestSupport.makeController()

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
        #expect(stdoutOutput.contains("workflow_path=\"\(fileURL.path)\""))
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
        let controller = SymphonyStartupFlowTestSupport.makeController()

        let (stderrOutput, exitCode) = SymphonyStartupFlowTestSupport.captureStandardError {
            controller.run(
                arguments: ["symphony", fileURL.path],
                currentWorkingDirectoryPath: workingDirectoryPath
            )
        }

        #expect(exitCode == EXIT_FAILURE)
        #expect(
            stderrOutput.contains(
                "component=symphony event=startup_validation outcome=failed"
            )
        )
        #expect(
            stderrOutput.contains(
                """
                error_code=symphony.startup.missing_tracker_project_identifier \
                reason="The workflow configuration is missing the tracker project identifier." \
                retryable=false
                """
            )
        )
        #expect(
            !stderrOutput.contains(
                "Set the tracker project identifier in the workflow configuration."
            )
        )
    }

    @Test
    func startupControllerReturnsTypedFailureWhenDefaultWorkflowFileIsMissing() {
        let workingDirectoryPath = SymphonyStartupFlowTestSupport.temporaryDirectory().path
        let controller = SymphonyStartupFlowTestSupport.makeController()

        let (stderrOutput, exitCode) = SymphonyStartupFlowTestSupport.captureStandardError {
            controller.run(
                arguments: ["symphony"],
                currentWorkingDirectoryPath: workingDirectoryPath
            )
        }

        #expect(exitCode == EXIT_FAILURE)
        #expect(
            stderrOutput.contains(
                "component=symphony event=startup_validation outcome=failed"
            )
        )
        #expect(
            stderrOutput.contains(
                """
                error_code=symphony.workflow.missing_workflow_file \
                reason="The workflow file could not be found or read." \
                retryable=false \
                workflow_path="\(workingDirectoryPath)/WORKFLOW.md"
                """
            )
        )
        #expect(!stderrOutput.contains("Path: \(workingDirectoryPath)/WORKFLOW.md"))
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

        let controller = SymphonyStartupFlowTestSupport.makeController()

        let (stderrOutput, exitCode) = SymphonyStartupFlowTestSupport.captureStandardError {
            controller.run(
                arguments: ["symphony", fileURL.path],
                currentWorkingDirectoryPath: SymphonyStartupFlowTestSupport.temporaryDirectory().path
            )
        }

        #expect(exitCode == EXIT_FAILURE)
        #expect(
            stderrOutput.contains(
                """
                error_code=symphony.workflow.workflow_parse_error \
                reason="The workflow file front matter could not be parsed." \
                retryable=false
                """
            )
        )
        #expect(!stderrOutput.contains("kind: [linear"))
        #expect(!stderrOutput.contains("Prompt body should stay out of logs."))
    }
}
