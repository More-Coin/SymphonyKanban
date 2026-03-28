public struct QuerySymphonyCodexConnectionStatusUseCase: Sendable {
    private let codexConnectionPort: any SymphonyCodexConnectionPortProtocol

    public init(
        codexConnectionPort: any SymphonyCodexConnectionPortProtocol
    ) {
        self.codexConnectionPort = codexConnectionPort
    }

    public func execute(
        using resolution: SymphonyCodexCommandResolutionContract
    ) -> SymphonyCodexConnectionStatusContract {
        codexConnectionPort.queryStatus(using: resolution)
    }
}
