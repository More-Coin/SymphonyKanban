import Testing
@testable import SymphonyKanban

struct ResolveSymphonyCodexCommandUseCaseTests {
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
