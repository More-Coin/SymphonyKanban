import SwiftUI

// MARK: - SymphonyIssueListFilterBarView
/// Filter bar with search field, status picker, and issue count.

public struct SymphonyIssueListFilterBarView: View {
    @Binding var searchText: String
    @Binding var statusFilter: String
    let statusKeys: [String]
    let issueCount: Int

    public init(
        searchText: Binding<String>,
        statusFilter: Binding<String>,
        statusKeys: [String],
        issueCount: Int
    ) {
        self._searchText = searchText
        self._statusFilter = statusFilter
        self.statusKeys = statusKeys
        self.issueCount = issueCount
    }

    public var body: some View {
        HStack(spacing: SymphonyDesignStyle.Spacing.md) {
            SymphonySearchFieldView(placeholder: "Filter issues...", text: $searchText)
                .frame(maxWidth: 260)

            Picker("Status", selection: $statusFilter) {
                ForEach(statusKeys, id: \.self) { key in
                    Text(key).tag(key)
                }
            }
            .pickerStyle(.menu)
            .frame(width: 140)

            Spacer()

            Text("\(issueCount) issues")
                .font(SymphonyDesignStyle.Typography.caption)
                .foregroundStyle(SymphonyDesignStyle.Text.tertiary)
        }
        .padding(.horizontal, SymphonyDesignStyle.Spacing.lg)
        .padding(.vertical, SymphonyDesignStyle.Spacing.sm)
        .background(SymphonyDesignStyle.Background.tertiary)
    }
}
