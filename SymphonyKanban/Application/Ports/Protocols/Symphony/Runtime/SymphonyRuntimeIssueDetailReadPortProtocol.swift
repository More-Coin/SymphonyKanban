import Foundation

public protocol SymphonyRuntimeIssueDetailReadPortProtocol: Sendable {
    func readRuntimeIssueDetailSnapshot(
        issueIdentifier: String,
        generatedAt: Date
    ) -> SymphonyRuntimeIssueDetailSnapshotContract?
}
