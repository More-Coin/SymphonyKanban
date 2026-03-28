import Testing
@testable import SymphonyKanban

struct ResolveSymphonyCodexCommandUseCaseTests {
    @Test
    func executeDelegatesToCodexCommandResolverPort() {
        let port = CodexCommandResolverPortSpy(
            resolution: SymphonyCodexCommandResolutionContract(
                configuredCommand: "codex app-server --listen stdio://",
                effectiveCommand: "/opt/homebrew/bin/codex app-server --listen stdio://",
                executableName: "codex",
                executablePath: "/opt/homebrew/bin/codex",
                detailMessage: "resolved"
            )
        )
        let useCase = ResolveSymphonyCodexCommandUseCase(
            codexCommandResolverPort: port
        )

        let result = useCase.execute(
            currentWorkingDirectoryPath: "/tmp/project",
            explicitWorkflowPath: "/tmp/project/WORKFLOW.md"
        )

        #expect(port.recordedCurrentWorkingDirectoryPath == "/tmp/project")
        #expect(port.recordedExplicitWorkflowPath == "/tmp/project/WORKFLOW.md")
        #expect(result.configuredCommand == "codex app-server --listen stdio://")
        #expect(result.effectiveCommand == "/opt/homebrew/bin/codex app-server --listen stdio://")
        #expect(result.executablePath == "/opt/homebrew/bin/codex")
        #expect(result.detailMessage == "resolved")
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
