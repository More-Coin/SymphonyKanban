public protocol SymphonyCodexCommandResolverPortProtocol {
    func resolveCodexCommand(
        currentWorkingDirectoryPath: String,
        explicitWorkflowPath: String?
    ) -> SymphonyCodexCommandResolutionContract
}
