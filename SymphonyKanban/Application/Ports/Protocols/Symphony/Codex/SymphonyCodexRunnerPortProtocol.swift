public protocol SymphonyCodexRunnerPortProtocol: Sendable {
    func startSession(
        using startup: SymphonyCodexSessionStartupContract,
        onEvent: @escaping @Sendable (SymphonyCodexRuntimeEventContract) -> Void
    ) async throws -> SymphonyCodexTurnExecutionResultContract

    func continueTurn(
        using request: SymphonyCodexTurnStartContract,
        onEvent: @escaping @Sendable (SymphonyCodexRuntimeEventContract) -> Void
    ) async throws -> SymphonyCodexTurnExecutionResultContract

    func cancelActiveTurn() -> SymphonyActiveTurnCancellationResultContract
}
