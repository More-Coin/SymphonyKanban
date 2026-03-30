public struct SymphonyStartupResultContract: Equatable, Sendable {
    public let state: SymphonyStartupStateContract
    public let activeBindingCount: Int
    public let readyBindingCount: Int
    public let failedBindingCount: Int

    public init(
        state: SymphonyStartupStateContract,
        activeBindingCount: Int,
        readyBindingCount: Int,
        failedBindingCount: Int
    ) {
        self.state = state
        self.activeBindingCount = activeBindingCount
        self.readyBindingCount = readyBindingCount
        self.failedBindingCount = failedBindingCount
    }
}
