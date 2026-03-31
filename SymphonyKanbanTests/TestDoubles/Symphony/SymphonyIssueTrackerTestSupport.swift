import Foundation
@testable import SymphonyKanban

final class SymphonyIssueTrackerReadPortSpy: @unchecked Sendable, SymphonyIssueTrackerReadPortProtocol {
    private let lock = NSLock()
    private var fetchIssuesResponses: [[SymphonyIssue]]
    private let fetchIssuesError: Error?
    private var fetchIssuesCalls = 0
    private var updateIssueCalls = 0

    init(
        fetchIssuesResponses: [[SymphonyIssue]] = [],
        fetchIssuesError: Error? = nil
    ) {
        self.fetchIssuesResponses = fetchIssuesResponses
        self.fetchIssuesError = fetchIssuesError
    }

    func fetchCandidateIssues(
        using _: SymphonyServiceConfigContract.Tracker
    ) async throws -> [SymphonyIssue] {
        []
    }

    func fetchIssues(
        byStateTypes _: [String],
        using _: SymphonyServiceConfigContract.Tracker
    ) async throws -> [SymphonyIssue] {
        try lock.withLock {
            fetchIssuesCalls += 1
            if let fetchIssuesError {
                throw fetchIssuesError
            }

            guard fetchIssuesResponses.isEmpty == false else {
                return []
            }

            return fetchIssuesResponses.removeFirst()
        }
    }

    func fetchIssueStates(
        byIDs _: [String],
        using _: SymphonyServiceConfigContract.Tracker
    ) async throws -> [SymphonyIssue] {
        []
    }

    func updateIssue(
        _: SymphonyIssueUpdateRequestContract,
        currentIssue: SymphonyIssue,
        using _: SymphonyServiceConfigContract.Tracker
    ) async throws -> SymphonyIssueUpdateResultContract {
        lock.withLock {
            updateIssueCalls += 1
        }

        return SymphonyIssueUpdateResultContract(
            issueID: currentIssue.id,
            issueIdentifier: currentIssue.identifier,
            appliedStateID: "spy-state"
        )
    }

    func fetchIssuesCallCount() -> Int {
        lock.withLock { fetchIssuesCalls }
    }

    func updateIssueCallCount() -> Int {
        lock.withLock { updateIssueCalls }
    }
}
