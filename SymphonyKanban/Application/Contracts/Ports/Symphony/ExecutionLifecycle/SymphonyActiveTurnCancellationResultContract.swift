public struct SymphonyActiveTurnCancellationResultContract: Equatable, Sendable {
    public enum Disposition: String, Equatable, Sendable {
        case requestAccepted = "request_accepted"
        case alreadyRequested = "already_requested"
        case noActiveTurn = "no_active_turn"
    }

    public let disposition: Disposition

    public init(disposition: Disposition) {
        self.disposition = disposition
    }
}
