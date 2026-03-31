import Foundation
import Testing
@testable import SymphonyKanban

struct SymphonyIssueDispatchOrderingPolicyTests {
    @Test
    func orderedUsesCreatedAtThenIdentifierThenIDAsTieBreakers() {
        let policy = SymphonyIssueDispatchOrderingPolicy()

        let ordered = policy.ordered([
            makeIssue(id: "issue-z", identifier: "KAN-101", createdAt: date(day: 4)),
            makeIssue(id: "issue-d", identifier: "KAN-100", createdAt: date(day: 2)),
            makeIssue(id: "issue-b", identifier: "KAN-100", createdAt: date(day: 2)),
            makeIssue(id: "issue-a", identifier: "KAN-099", createdAt: date(day: 1))
        ])

        #expect(ordered.map(\.id) == ["issue-a", "issue-b", "issue-d", "issue-z"])
    }

    private func makeIssue(
        id: String,
        identifier: String,
        createdAt: Date?
    ) -> SymphonyIssue {
        SymphonyIssue(
            id: id,
            identifier: identifier,
            title: "Issue \(identifier)",
            description: nil,
            priority: 2,
            state: "Backlog",
            stateType: "backlog",
            branchName: nil,
            url: nil,
            labels: [],
            blockedBy: [],
            createdAt: createdAt,
            updatedAt: createdAt
        )
    }

    private func date(day: Int) -> Date {
        Calendar(identifier: .gregorian).date(
            from: DateComponents(
                timeZone: TimeZone(secondsFromGMT: 0),
                year: 2026,
                month: 1,
                day: day
            )
        )!
    }
}
