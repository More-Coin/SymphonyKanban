import Testing
@testable import SymphonyKanban

struct SymphonyCodexConnectionServiceTests {
    @Test
    func queryStatusPassesResolvedCommandResolutionToConnectionStatusQuery() {
        let commandPort = CodexCommandResolverPortSpy(
            resolution: SymphonyCodexCommandResolutionContract(
                configuredCommand: "codex app-server --listen stdio://",
                effectiveCommand: "/opt/homebrew/bin/codex app-server --listen stdio://",
                executableName: "codex",
                executablePath: "/opt/homebrew/bin/codex",
                detailMessage: nil
            )
        )
        let statusPort = CodexConnectionPortSpy()
        let service = SymphonyCodexConnectionService(
            resolveCodexCommandUseCase: ResolveSymphonyCodexCommandUseCase(
                codexCommandResolverPort: commandPort
            ),
            queryCodexConnectionStatusUseCase: QuerySymphonyCodexConnectionStatusUseCase(
                codexConnectionPort: statusPort
            )
        )

        let status = service.queryStatus(
            currentWorkingDirectoryPath: "/tmp/project"
        )

        #expect(commandPort.recordedCurrentWorkingDirectoryPath == "/tmp/project")
        #expect(statusPort.recordedResolution?.configuredCommand == "codex app-server --listen stdio://")
        #expect(statusPort.recordedResolution?.effectiveCommand == "/opt/homebrew/bin/codex app-server --listen stdio://")
        #expect(status.detailMessage == nil)
    }

    @Test
    func queryStatusAppendsResolutionNoteToReturnedStatusDetail() {
        let commandPort = CodexCommandResolverPortSpy(
            resolution: SymphonyCodexCommandResolutionContract(
                configuredCommand: "codex app-server",
                effectiveCommand: "codex app-server",
                executableName: "codex",
                executablePath: nil,
                detailMessage: "Workflow config could not be resolved, so Symphony used the default command `codex app-server`."
            )
        )
        let statusPort = CodexConnectionPortSpy(
            detailMessage: "Codex CLI is authenticated."
        )
        let service = SymphonyCodexConnectionService(
            resolveCodexCommandUseCase: ResolveSymphonyCodexCommandUseCase(
                codexCommandResolverPort: commandPort
            ),
            queryCodexConnectionStatusUseCase: QuerySymphonyCodexConnectionStatusUseCase(
                codexConnectionPort: statusPort
            )
        )

        let status = service.queryStatus(
            currentWorkingDirectoryPath: "/tmp/project",
            explicitWorkflowPath: "/tmp/project/WORKFLOW.md"
        )

        #expect(commandPort.recordedExplicitWorkflowPath == "/tmp/project/WORKFLOW.md")
        #expect(statusPort.recordedResolution?.effectiveCommand == "codex app-server")
        #expect(status.detailMessage == "Codex CLI is authenticated.\n\nWorkflow config could not be resolved, so Symphony used the default command `codex app-server`.")
    }
}

private final class CodexCommandResolverPortSpy: SymphonyCodexCommandResolverPortProtocol, @unchecked Sendable {
    let resolution: SymphonyCodexCommandResolutionContract
    private(set) var recordedCurrentWorkingDirectoryPath: String?
    private(set) var recordedExplicitWorkflowPath: String?

    init(resolution: SymphonyCodexCommandResolutionContract) {
        self.resolution = resolution
    }

    func resolveCodexCommand(
        currentWorkingDirectoryPath: String,
        explicitWorkflowPath: String?
    ) -> SymphonyCodexCommandResolutionContract {
        recordedCurrentWorkingDirectoryPath = currentWorkingDirectoryPath
        recordedExplicitWorkflowPath = explicitWorkflowPath
        return resolution
    }
}

private final class CodexConnectionPortSpy: SymphonyCodexConnectionPortProtocol, @unchecked Sendable {
    let detailMessage: String?
    private(set) var recordedResolution: SymphonyCodexCommandResolutionContract?

    init(detailMessage: String? = nil) {
        self.detailMessage = detailMessage
    }

    func queryStatus(
        using resolution: SymphonyCodexCommandResolutionContract
    ) -> SymphonyCodexConnectionStatusContract {
        recordedResolution = resolution
        return SymphonyCodexConnectionStatusContract(
            state: .connected,
            command: resolution.effectiveCommand,
            executableName: resolution.executableName,
            executablePath: resolution.executablePath,
            statusMessage: "Codex is installed, authenticated, and ready for Symphony.",
            detailMessage: detailMessage
        )
    }
}
