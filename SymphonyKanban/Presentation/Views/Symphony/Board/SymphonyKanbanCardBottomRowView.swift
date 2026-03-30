import SwiftUI

// MARK: - SymphonyKanbanCardBottomRowView
/// Bottom row of a Kanban card displaying agent avatar, label chips,
/// token count, and last event information.

public struct SymphonyKanbanCardBottomRowView: View {
    let agentName: String?
    let labels: [String]
    let tokenCount: String?
    let lastEvent: String?

    public init(
        agentName: String?,
        labels: [String],
        tokenCount: String?,
        lastEvent: String?
    ) {
        self.agentName = agentName
        self.labels = labels
        self.tokenCount = tokenCount
        self.lastEvent = lastEvent
    }

    public var body: some View {
        HStack(spacing: SymphonyDesignStyle.Spacing.sm) {
            if let agentName {
                SymphonyAgentAvatarView(name: agentName, size: 20)
            }

            if !labels.isEmpty {
                labelChips
            }

            Spacer()

            if let tokenCount {
                HStack(spacing: SymphonyDesignStyle.Spacing.xxs) {
                    Image(systemName: "number.circle")
                        .font(.system(size: 9, weight: .medium))
                    Text(tokenCount)
                        .font(SymphonyDesignStyle.Typography.micro)
                }
                .foregroundStyle(SymphonyDesignStyle.Text.tertiary)
            }

            if let lastEvent {
                HStack(spacing: SymphonyDesignStyle.Spacing.xxs) {
                    Circle()
                        .fill(SymphonyDesignStyle.Text.tertiary)
                        .frame(width: 3, height: 3)
                    Text(lastEvent)
                        .font(SymphonyDesignStyle.Typography.micro)
                }
                .foregroundStyle(SymphonyDesignStyle.Text.tertiary)
            }
        }
    }

    private var labelChips: some View {
        HStack(spacing: SymphonyDesignStyle.Spacing.xs) {
            ForEach(labels.prefix(3), id: \.self) { label in
                SymphonyLabelChipView(label)
            }
        }
    }
}
