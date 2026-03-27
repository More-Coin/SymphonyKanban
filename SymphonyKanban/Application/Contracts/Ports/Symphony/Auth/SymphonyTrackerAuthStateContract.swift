public enum SymphonyTrackerAuthStateContract: String, Equatable, Sendable {
    case disconnected
    case connecting
    case connected
    case staleSession
}
