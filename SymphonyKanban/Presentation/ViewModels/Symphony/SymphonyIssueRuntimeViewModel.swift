public struct SymphonyIssueRuntimeViewModel: Equatable, Sendable {
    public let title: String
    public let stateLabel: String
    public let sessionIDLabel: String
    public let threadIDLabel: String
    public let turnIDLabel: String
    public let processLabel: String?
    public let turnCountLabel: String
    public let startedAtLabel: String
    public let lastEventLabel: String?
    public let lastMessageLabel: String?
    public let tokenLabel: String

    public init(
        title: String,
        stateLabel: String,
        sessionIDLabel: String,
        threadIDLabel: String,
        turnIDLabel: String,
        processLabel: String?,
        turnCountLabel: String,
        startedAtLabel: String,
        lastEventLabel: String?,
        lastMessageLabel: String?,
        tokenLabel: String
    ) {
        self.title = title
        self.stateLabel = stateLabel
        self.sessionIDLabel = sessionIDLabel
        self.threadIDLabel = threadIDLabel
        self.turnIDLabel = turnIDLabel
        self.processLabel = processLabel
        self.turnCountLabel = turnCountLabel
        self.startedAtLabel = startedAtLabel
        self.lastEventLabel = lastEventLabel
        self.lastMessageLabel = lastMessageLabel
        self.tokenLabel = tokenLabel
    }
}
