public enum SymphonyCodexConnectionStateContract: String, Equatable, Sendable {
    case connected
    case cliUnavailable
    case notAuthenticated
    case appServerUnavailable
}

public struct SymphonyCodexConnectionStatusContract: Equatable, Sendable {
    public let state: SymphonyCodexConnectionStateContract
    public let command: String
    public let executableName: String
    public let executablePath: String?
    public let statusMessage: String
    public let detailMessage: String?

    public init(
        state: SymphonyCodexConnectionStateContract,
        command: String,
        executableName: String,
        executablePath: String? = nil,
        statusMessage: String,
        detailMessage: String? = nil
    ) {
        self.state = state
        self.command = command
        self.executableName = executableName
        self.executablePath = executablePath
        self.statusMessage = statusMessage
        self.detailMessage = detailMessage
    }

    public var isReady: Bool {
        state == .connected
    }
}
