import Foundation

public struct QuerySymphonyRuntimeIssueDetailSnapshotUseCase {
    private let clockPort: any SymphonyRuntimeClockPortProtocol
    private let runtimeIssueDetailReadPort: any SymphonyRuntimeIssueDetailReadPortProtocol

    public init(
        clockPort: any SymphonyRuntimeClockPortProtocol,
        runtimeIssueDetailReadPort: any SymphonyRuntimeIssueDetailReadPortProtocol
    ) {
        self.clockPort = clockPort
        self.runtimeIssueDetailReadPort = runtimeIssueDetailReadPort
    }

    public func query(
        issueIdentifier: String
    ) -> SymphonyRuntimeIssueDetailSnapshotContract? {
        runtimeIssueDetailReadPort.readRuntimeIssueDetailSnapshot(
            issueIdentifier: issueIdentifier,
            generatedAt: clockPort.now()
        )
    }
}
