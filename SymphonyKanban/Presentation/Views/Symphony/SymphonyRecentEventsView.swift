import SwiftUI

public struct SymphonyRecentEventsView: View {
    private let title: String
    private let emptyState: String
    private let rows: [SymphonyRecentEventRowViewModel]

    public init(
        title: String,
        emptyState: String,
        rows: [SymphonyRecentEventRowViewModel]
    ) {
        self.title = title
        self.emptyState = emptyState
        self.rows = rows
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text(title)
                .font(.title3.weight(.semibold))

            if rows.isEmpty {
                Text(emptyState)
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            } else {
                VStack(spacing: 12) {
                    ForEach(rows) { row in
                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                Text(row.title)
                                    .font(.headline)
                                Spacer(minLength: 16)
                                Text(row.subtitle)
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                            ForEach(row.detailLines, id: \.self) { detailLine in
                                Text(detailLine)
                                    .font(.footnote)
                                    .foregroundStyle(.secondary)
                            }
                        }
                        .padding(14)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(
                            RoundedRectangle(cornerRadius: 16, style: .continuous)
                                .fill(SymphonyDashboardStyle.surfaceOverlay)
                        )
                    }
                }
            }
        }
        .padding(20)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(SymphonyDashboardStyle.panelBackground)
        .overlay(
            RoundedRectangle(cornerRadius: SymphonyDashboardStyle.panelCornerRadius, style: .continuous)
                .strokeBorder(SymphonyDashboardStyle.surfaceBorder, lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: SymphonyDashboardStyle.panelCornerRadius, style: .continuous))
    }
}

#Preview {
    SymphonyRecentEventsView(
        title: "Recent Events",
        emptyState: "No recent events are available.",
        rows: [
            SymphonyRecentEventRowViewModel(
                title: "tool_call",
                subtitle: "2 minutes ago",
                detailLines: [
                    "Patched dashboard presenter",
                    "file: Presentation/Presenters/Symphony/SymphonyDashboardPresenter.swift"
                ]
            ),
            SymphonyRecentEventRowViewModel(
                title: "lint",
                subtitle: "8 minutes ago",
                detailLines: [
                    "Architecture linter passed"
                ]
            )
        ]
    )
    .padding()
    .background(SymphonyDashboardStyle.pageBackground)
}
