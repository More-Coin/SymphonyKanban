import Foundation

public struct SymphonyLiveSessionContract: Equatable, Sendable {
    public let sessionID: String
    public let threadID: String
    public let turnID: String
    public let codexAppServerPID: String?
    public let lastCodexEvent: String?
    public let lastCodexTimestamp: Date?
    public let lastCodexMessage: String?
    public let codexInputTokens: Int
    public let codexOutputTokens: Int
    public let codexTotalTokens: Int
    public let lastReportedInputTokens: Int
    public let lastReportedOutputTokens: Int
    public let lastReportedTotalTokens: Int
    public let turnCount: Int

    public init(
        sessionID: String,
        threadID: String,
        turnID: String,
        codexAppServerPID: String?,
        lastCodexEvent: String?,
        lastCodexTimestamp: Date?,
        lastCodexMessage: String?,
        codexInputTokens: Int,
        codexOutputTokens: Int,
        codexTotalTokens: Int,
        lastReportedInputTokens: Int,
        lastReportedOutputTokens: Int,
        lastReportedTotalTokens: Int,
        turnCount: Int
    ) {
        self.sessionID = sessionID
        self.threadID = threadID
        self.turnID = turnID
        self.codexAppServerPID = codexAppServerPID
        self.lastCodexEvent = lastCodexEvent
        self.lastCodexTimestamp = lastCodexTimestamp
        self.lastCodexMessage = lastCodexMessage
        self.codexInputTokens = codexInputTokens
        self.codexOutputTokens = codexOutputTokens
        self.codexTotalTokens = codexTotalTokens
        self.lastReportedInputTokens = lastReportedInputTokens
        self.lastReportedOutputTokens = lastReportedOutputTokens
        self.lastReportedTotalTokens = lastReportedTotalTokens
        self.turnCount = turnCount
    }

    public var lastActivityTimestamp: Date? {
        lastCodexTimestamp
    }
}
