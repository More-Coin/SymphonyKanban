import Foundation

public struct SymphonyTrackerAuthStatusContract: Equatable, Sendable {
    public let trackerKind: String
    public let state: SymphonyTrackerAuthStateContract
    public let statusMessage: String
    public let connectedAt: Date?
    public let expiresAt: Date?
    public let accountLabel: String?

    public init(
        trackerKind: String,
        state: SymphonyTrackerAuthStateContract,
        statusMessage: String,
        connectedAt: Date? = nil,
        expiresAt: Date? = nil,
        accountLabel: String? = nil
    ) {
        self.trackerKind = trackerKind
        self.state = state
        self.statusMessage = statusMessage
        self.connectedAt = connectedAt
        self.expiresAt = expiresAt
        self.accountLabel = accountLabel
    }

    public var isReady: Bool {
        state == .connected
    }
}
