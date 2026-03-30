import Testing
@testable import SymphonyKanban

struct SymphonyIssueDetailPresenterTests {
    @Test
    func presentUsesIssueMetadataWhenRuntimeSnapshotIsMissing() {
        let presenter = SymphonyIssueDetailPresenter()

        let viewModel = presenter.present(
            SymphonyRuntimeIssueDetailQueryResultContract(
                issueIdentifier: "KAN-142",
                snapshot: nil,
                isEmpty: true,
                hasRunningDetail: false,
                hasRetryDetail: false,
                hasRecentEvents: false,
                hasLastError: false,
                hasLogs: false
            ),
            issue: SymphonyIssue(
                id: "issue-142",
                identifier: "KAN-142",
                title: "Rebuild Symphony dashboard pipeline",
                description: "Issue metadata should still render.",
                priority: 2,
                state: "Doing",
                stateType: "started",
                branchName: "feature/dashboard-pipeline",
                url: "https://linear.app/example/KAN-142",
                labels: ["symphony", "dashboard"],
                blockedBy: [],
                createdAt: nil,
                updatedAt: nil
            )
        )

        #expect(viewModel.isEmptyState == false)
        #expect(viewModel.title == "Rebuild Symphony dashboard pipeline")
        #expect(viewModel.stateLabel == "Doing")
        #expect(viewModel.runtimeStatusLabel == "Idle")
        #expect(viewModel.metadataLines.contains { $0.contains("feature/dashboard-pipeline") })
    }
}
