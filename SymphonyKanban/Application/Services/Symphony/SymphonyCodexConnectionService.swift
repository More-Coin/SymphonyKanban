public struct SymphonyCodexConnectionService {
    private let resolveCodexCommandUseCase: ResolveSymphonyCodexCommandUseCase
    private let queryCodexConnectionStatusUseCase: QuerySymphonyCodexConnectionStatusUseCase

    public init(
        resolveCodexCommandUseCase: ResolveSymphonyCodexCommandUseCase,
        queryCodexConnectionStatusUseCase: QuerySymphonyCodexConnectionStatusUseCase
    ) {
        self.resolveCodexCommandUseCase = resolveCodexCommandUseCase
        self.queryCodexConnectionStatusUseCase = queryCodexConnectionStatusUseCase
    }

    public func queryStatus(
        currentWorkingDirectoryPath: String,
        explicitWorkflowPath: String? = nil
    ) -> SymphonyCodexConnectionStatusContract {
        let resolution = resolveCodexCommandUseCase.execute(
            currentWorkingDirectoryPath: currentWorkingDirectoryPath,
            explicitWorkflowPath: explicitWorkflowPath
        )
        let status = queryCodexConnectionStatusUseCase.execute(using: resolution)

        guard let resolutionNote = resolution.detailMessage else {
            return status
        }

        return SymphonyCodexConnectionStatusContract(
            state: status.state,
            command: status.command,
            executableName: status.executableName,
            executablePath: status.executablePath,
            statusMessage: status.statusMessage,
            detailMessage: mergedDetailMessage(
                status.detailMessage,
                resolutionNote
            )
        )
    }

    private func mergedDetailMessage(
        _ existing: String?,
        _ note: String
    ) -> String {
        guard let existing,
              existing.isEmpty == false else {
            return note
        }

        return "\(existing)\n\n\(note)"
    }
}
