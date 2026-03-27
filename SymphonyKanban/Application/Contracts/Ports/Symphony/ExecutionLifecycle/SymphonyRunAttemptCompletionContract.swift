public struct SymphonyRunAttemptCompletionContract: Equatable, Sendable {
    public let workspacePath: String

    public init(workspacePath: String) {
        self.workspacePath = workspacePath
    }
}
