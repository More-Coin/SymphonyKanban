import SwiftUI

// MARK: - SymphonyKanbanCardTopRowView
/// Top row of a Kanban card displaying priority dot, identifier,
/// running indicator, and status badge.

public struct SymphonyKanbanCardTopRowView: View {
    let identifier: String
    let priorityLevel: Int
    let statusKey: String
    let statusLabel: String
    let isRunning: Bool

    public init(
        identifier: String,
        priorityLevel: Int,
        statusKey: String,
        statusLabel: String,
        isRunning: Bool
    ) {
        self.identifier = identifier
        self.priorityLevel = priorityLevel
        self.statusKey = statusKey
        self.statusLabel = statusLabel
        self.isRunning = isRunning
    }

    public var body: some View {
        HStack(spacing: SymphonyDesignStyle.Spacing.sm) {
            SymphonyPriorityDotView(level: priorityLevel)

            Text(identifier)
                .font(SymphonyDesignStyle.Typography.micro)
                .foregroundStyle(SymphonyDesignStyle.Text.secondary)

            if isRunning {
                SymphonyPulsingDotView(color: SymphonyDesignStyle.Status.color(for: statusKey))
            }

            Spacer()

            SymphonyStatusBadgeView(
                statusLabel,
                statusKey: statusKey,
                size: .small
            )
        }
    }
}
