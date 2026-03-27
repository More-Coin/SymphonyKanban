public struct SymphonyCodexSessionIdentityContract: Equatable, Sendable {
    public let threadID: String
    public let turnID: String

    public var sessionID: String {
        "\(threadID)-\(turnID)"
    }

    public init(
        threadID: String,
        turnID: String
    ) {
        self.threadID = threadID
        self.turnID = turnID
    }
}
