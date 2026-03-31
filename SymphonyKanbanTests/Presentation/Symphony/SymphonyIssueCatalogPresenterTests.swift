import Foundation
import Testing
@testable import SymphonyKanban

struct SymphonyIssueCatalogPresenterTests {
    @Test
    func presentOrdersBoardBacklogByPriorityAndPlacesUnprioritizedLast() {
        let presenter = SymphonyIssueCatalogPresenter()

        let viewModel = presenter.present(
            SymphonyIssueCollectionContract(
                issues: [
                    makeIssue(id: "issue-none-nil", identifier: "KAN-105", priority: nil, createdAt: date(day: 6)),
                    makeIssue(id: "issue-low", identifier: "KAN-104", priority: 4, createdAt: date(day: 5)),
                    makeIssue(id: "issue-none-zero", identifier: "KAN-106", priority: 0, createdAt: date(day: 4)),
                    makeIssue(id: "issue-high", identifier: "KAN-102", priority: 2, createdAt: date(day: 3)),
                    makeIssue(id: "issue-urgent", identifier: "KAN-101", priority: 1, createdAt: date(day: 2)),
                    makeIssue(id: "issue-medium", identifier: "KAN-103", priority: 3, createdAt: date(day: 1))
                ]
            ),
            displayMode: .mergedWithBadges,
            selectedIssueIdentifier: nil
        )

        let backlogIdentifiers = viewModel.boardViewModel.columns
            .first(where: { $0.id == "backlog" })?
            .cards
            .map(\.identifier)

        #expect(backlogIdentifiers == ["KAN-101", "KAN-102", "KAN-103", "KAN-104", "KAN-106", "KAN-105"])
    }

    @Test
    func presentOrdersBoardUsingCreatedAtThenIdentifierWithinPriorityBucket() {
        let presenter = SymphonyIssueCatalogPresenter()

        let viewModel = presenter.present(
            SymphonyIssueCollectionContract(
                issues: [
                    makeIssue(id: "issue-z", identifier: "KAN-101", priority: 2, createdAt: date(day: 4)),
                    makeIssue(id: "issue-c", identifier: "KAN-100", priority: 2, createdAt: date(day: 2)),
                    makeIssue(id: "issue-b", identifier: "KAN-098", priority: 2, createdAt: date(day: 2)),
                    makeIssue(id: "issue-a", identifier: "KAN-099", priority: 2, createdAt: date(day: 1))
                ]
            ),
            displayMode: .mergedWithBadges,
            selectedIssueIdentifier: nil
        )

        let backlogCardIDs = viewModel.boardViewModel.columns
            .first(where: { $0.id == "backlog" })?
            .cards
            .map(\.id)

        #expect(backlogCardIDs == ["issue-a", "issue-b", "issue-c", "issue-z"])
    }

    @Test
    func presentAppliesPriorityBoardOrderingAcrossMultipleColumns() {
        let presenter = SymphonyIssueCatalogPresenter()

        let viewModel = presenter.present(
            SymphonyIssueCollectionContract(
                issues: [
                    makeIssue(id: "issue-progress-low", identifier: "KAN-201", priority: 4, state: "Doing", stateType: "started", createdAt: date(day: 4)),
                    makeIssue(id: "issue-progress-urgent", identifier: "KAN-202", priority: 1, state: "Doing", stateType: "started", createdAt: date(day: 3)),
                    makeIssue(id: "issue-done-none", identifier: "KAN-203", priority: nil, state: "Completed", stateType: "completed", createdAt: date(day: 2)),
                    makeIssue(id: "issue-done-high", identifier: "KAN-204", priority: 2, state: "Completed", stateType: "completed", createdAt: date(day: 1))
                ]
            ),
            displayMode: .mergedWithBadges,
            selectedIssueIdentifier: nil
        )

        let columnsByID = Dictionary(uniqueKeysWithValues: viewModel.boardViewModel.columns.map { ($0.id, $0) })

        #expect(columnsByID["in_progress"]?.cards.map(\.identifier) == ["KAN-202", "KAN-201"])
        #expect(columnsByID["done"]?.cards.map(\.identifier) == ["KAN-204", "KAN-203"])
    }

    @Test
    func presentKeepsListDefaultOrderingUnchanged() {
        let presenter = SymphonyIssueCatalogPresenter()

        let viewModel = presenter.present(
            SymphonyIssueCollectionContract(
                issues: [
                    makeIssue(id: "issue-none-nil", identifier: "KAN-303", priority: nil, createdAt: date(day: 3)),
                    makeIssue(id: "issue-urgent", identifier: "KAN-302", priority: 1, createdAt: date(day: 2)),
                    makeIssue(id: "issue-none-zero", identifier: "KAN-301", priority: 0, createdAt: date(day: 1))
                ]
            ),
            displayMode: .mergedWithBadges,
            selectedIssueIdentifier: nil
        )

        let backlogIdentifiers = viewModel.boardViewModel.columns
            .first(where: { $0.id == "backlog" })?
            .cards
            .map(\.identifier)
        let listIdentifiers = viewModel.listViewModel.rows.map(\.identifier)

        #expect(backlogIdentifiers == ["KAN-302", "KAN-301", "KAN-303"])
        #expect(listIdentifiers == ["KAN-301", "KAN-302", "KAN-303"])
    }

    private func makeIssue(
        id: String,
        identifier: String,
        priority: Int?,
        state: String = "Backlog",
        stateType: String = "backlog",
        createdAt: Date?
    ) -> SymphonyIssue {
        SymphonyIssue(
            id: id,
            identifier: identifier,
            title: "Issue \(identifier)",
            description: nil,
            priority: priority,
            state: state,
            stateType: stateType,
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
