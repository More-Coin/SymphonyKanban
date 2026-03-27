public struct CancelSymphonyActiveTurnUseCase {
    private let runnerPort: any SymphonyCodexRunnerPortProtocol

    public init(runnerPort: any SymphonyCodexRunnerPortProtocol) {
        self.runnerPort = runnerPort
    }

    public func cancelActiveTurn() -> SymphonyActiveTurnCancellationResultContract {
        runnerPort.cancelActiveTurn()
    }
}
