import Dispatch
import SwiftUI

@MainActor
public struct SymphonyDashboardRoutes: View {
    private let dashboardController: SymphonyDashboardController
    private let issueDetailController: SymphonyIssueDetailController
    private let refreshController: SymphonyRefreshController

    @State private var selectedIssueIdentifier: String?
    @State private var lastRefreshedAt: Date?
    @State private var isRefreshing = false
    @State private var refreshNote: String?

    public init(
        dashboardController: SymphonyDashboardController,
        issueDetailController: SymphonyIssueDetailController,
        refreshController: SymphonyRefreshController,
        initialSelectedIssueIdentifier: String? = nil,
        initialLastRefreshedAt: Date? = Date.now.addingTimeInterval(-300)
    ) {
        self.dashboardController = dashboardController
        self.issueDetailController = issueDetailController
        self.refreshController = refreshController
        _selectedIssueIdentifier = State(initialValue: initialSelectedIssueIdentifier)
        _lastRefreshedAt = State(initialValue: initialLastRefreshedAt)
    }

    public var body: some View {
        HSplitView {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    refreshController.run(
                        source: "dashboard",
                        lastRefreshedAt: lastRefreshedAt,
                        isRefreshing: isRefreshing,
                        note: refreshNote,
                        onRefreshTapped: handleRefresh
                    )
                    dashboardController.run(
                        selectedIssueIdentifier: selectedIssueIdentifier,
                        onIssueSelected: handleIssueSelected
                    )
                }
                .padding(SymphonyDashboardStyle.pagePadding)
            }
            .frame(minWidth: 420, idealWidth: 480)

            ScrollView {
                issueDetailController.run(issueIdentifier: selectedIssueIdentifier)
                    .padding(SymphonyDashboardStyle.pagePadding)
            }
            .frame(minWidth: 520, idealWidth: 700)
        }
        .background(SymphonyDashboardStyle.pageBackground.ignoresSafeArea())
    }

    private func handleIssueSelected(_ issueIdentifier: String) {
        selectedIssueIdentifier = issueIdentifier
    }

    private func handleRefresh() {
        isRefreshing = true
        refreshNote = "Preview snapshot refreshed."
        let refreshedAt = Date.now
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.65) {
            lastRefreshedAt = refreshedAt
            isRefreshing = false
            if let selectedIssueIdentifier {
                refreshNote = "Focused \(selectedIssueIdentifier) after refresh."
            }
        }
    }
}

#Preview {
    SymphonyUIDI.makeDashboardRoutes()
}
