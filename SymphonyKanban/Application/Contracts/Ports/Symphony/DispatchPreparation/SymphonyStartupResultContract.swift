public struct SymphonyStartupResultContract: Equatable, Sendable {
    public let resolvedWorkflowPath: String

    public init(resolvedWorkflowPath: String) {
        self.resolvedWorkflowPath = resolvedWorkflowPath
    }
}
