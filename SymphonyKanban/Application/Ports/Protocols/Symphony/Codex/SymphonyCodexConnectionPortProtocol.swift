public protocol SymphonyCodexConnectionPortProtocol: Sendable {
    func queryStatus(
        using resolution: SymphonyCodexCommandResolutionContract
    ) -> SymphonyCodexConnectionStatusContract
}
