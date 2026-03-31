public protocol SymphonyWorkflowWritePortProtocol {
    func defaultDefinitionPath(
        forWorkspacePath workspacePath: String
    ) -> String

    @discardableResult
    func ensureDefinitionExists(
        contents: String,
        atPath path: String
    ) throws -> Bool
}
