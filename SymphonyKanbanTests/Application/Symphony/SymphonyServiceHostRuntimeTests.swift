import Foundation
import Testing
@testable import SymphonyKanban

@Suite(.serialized)
struct SymphonyServiceHostRuntimeTests {
    @Test
    func hostRuntimeDoesNotStartRuntimeWhenSetupIsRequired() {
        let recorder = HostRuntimeRecorder()
        let workingDirectoryURL = SymphonyStartupFlowTestSupport.temporaryDirectory()
        let runtime = SymphonyStartupFlowTestSupport.makeHostRuntime(
            startRuntime: { _ in
                recorder.markStarted()
            },
            keepRunning: {
                recorder.markKeepRunningCalled()
                return 99
            }
        )

        let (stdoutOutput, exitCode) = SymphonyStartupFlowTestSupport.captureStandardOutput {
            SymphonyStartupFlowTestSupport.withTemporaryCurrentDirectory(workingDirectoryURL.path) {
                runtime.run(arguments: ["symphony"])
            }
        }

        #expect(exitCode == EXIT_FAILURE)
        #expect(!recorder.startedRuntime)
        #expect(!recorder.keepRunningCalled)
        #expect(stdoutOutput.contains("outcome=blocked"))
        #expect(stdoutOutput.contains("startup_state=setupRequired"))
    }

    @Test
    func hostRuntimeStartsRuntimeWhenStartupIsReady() throws {
        let workflowURL = try SymphonyStartupFlowTestSupport.makeWorkflowFile(
            named: "HostRuntimeWorkflow.md",
            contents: """
            ---
            tracker:
              kind: linear
              project_slug: project
            ---
            Prompt body.
            """
        )
        let workingDirectoryURL = SymphonyStartupFlowTestSupport.temporaryDirectory()
        let bindingPort = WorkspaceTrackerBindingPortSpy(
            listedBindings: [SymphonyStartupFlowTestSupport.makeWorkspaceBinding(
                workspacePath: workingDirectoryURL.path
            )]
        )
        let recorder = HostRuntimeRecorder()
        let runtime = SymphonyStartupFlowTestSupport.makeHostRuntime(
            workspaceTrackerBindingPort: bindingPort,
            startRuntime: { bindingContext in
                recorder.recordStart(
                    bindingContext: bindingContext
                )
            },
            keepRunning: {
                77
            }
        )

        let (stdoutOutput, exitCode) = SymphonyStartupFlowTestSupport.captureStandardOutput {
            SymphonyStartupFlowTestSupport.withTemporaryCurrentDirectory(workingDirectoryURL.path) {
                runtime.run(arguments: ["symphony", workflowURL.path])
            }
        }

        #expect(exitCode == 77)
        #expect(stdoutOutput.contains("outcome=completed"))
        #expect(
            normalizedPath(recorder.startedBindingContext?.effectiveWorkspaceLocator.currentWorkingDirectoryPath)
                == normalizedPath(workingDirectoryURL.path)
        )
        #expect(recorder.startedBindingContext?.effectiveWorkspaceLocator.explicitWorkflowPath == workflowURL.path)
        #expect(recorder.startedBindingContext?.workflowConfiguration?.workflowDefinition.resolvedPath == workflowURL.path)
    }
}

private func normalizedPath(_ path: String?) -> String? {
    guard let path else {
        return nil
    }

    return URL(
        fileURLWithPath: NSString(string: path).resolvingSymlinksInPath
    )
    .standardizedFileURL
    .path
}

private final class HostRuntimeRecorder: @unchecked Sendable {
    private let lock = NSLock()
    private(set) var startedRuntime = false
    private(set) var keepRunningCalled = false
    private(set) var startedBindingContext: SymphonyActiveWorkspaceBindingContextContract?

    func markStarted() {
        lock.withLock {
            startedRuntime = true
        }
    }

    func markKeepRunningCalled() {
        lock.withLock {
            keepRunningCalled = true
        }
    }

    func recordStart(bindingContext: SymphonyActiveWorkspaceBindingContextContract) {
        lock.withLock {
            startedRuntime = true
            startedBindingContext = bindingContext
        }
    }
}
