public struct SymphonyCodexConnectionViewModel: Equatable, Sendable {
    public let isConnected: Bool
    public let title: String
    public let message: String

    public init(
        isConnected: Bool,
        title: String,
        message: String
    ) {
        self.isConnected = isConnected
        self.title = title
        self.message = message
    }
}
