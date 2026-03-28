public struct ResolveSymphonyCodexCommandUseCase {
    private let codexCommandResolverPort: any SymphonyCodexCommandResolverPortProtocol

    public init(
        codexCommandResolverPort: any SymphonyCodexCommandResolverPortProtocol
    ) {
        self.codexCommandResolverPort = codexCommandResolverPort
    }

    public func execute(
        currentWorkingDirectoryPath: String,
        explicitWorkflowPath: String? = nil
    ) -> SymphonyCodexCommandResolutionContract {
        codexCommandResolverPort.resolveCodexCommand(
            currentWorkingDirectoryPath: currentWorkingDirectoryPath,
            explicitWorkflowPath: explicitWorkflowPath
        )
    }
}
