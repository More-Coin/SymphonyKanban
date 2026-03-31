public protocol SymphonyOrchestratorLogSinkPortProtocol: Sendable {
    func emit(_ event: SymphonyOrchestratorLogEventContract)
}
