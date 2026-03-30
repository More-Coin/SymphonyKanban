import SwiftUI

// MARK: - SymphonyKanbanCardView
/// Individual Kanban card displaying key issue information with hover
/// effects, priority indicators, and agent avatars.

public struct SymphonyKanbanCardView: View {
    let viewModel: SymphonyKanbanCardViewModel
    let onTap: () -> Void

    @State private var isHovered = false

    public init(
        viewModel: SymphonyKanbanCardViewModel,
        onTap: @escaping () -> Void = {}
    ) {
        self.viewModel = viewModel
        self.onTap = onTap
    }

    public var body: some View {
        Button(action: onTap) {
            VStack(alignment: .leading, spacing: SymphonyDesignStyle.Spacing.sm) {
                topRow
                titleRow
                bottomRow
            }
            .padding(SymphonyDesignStyle.Spacing.md)
            .frame(maxWidth: .infinity, alignment: .leading)
            .symphonyCard()
        }
        .buttonStyle(.plain)
        .scaleEffect(isHovered ? 1.015 : 1.0)
        .shadow(
            color: .black.opacity(isHovered ? 0.35 : 0),
            radius: isHovered ? 12 : 0,
            x: 0,
            y: isHovered ? 6 : 0
        )
        .onHover { hovering in
            withAnimation(SymphonyDesignStyle.Motion.stiffSnap) {
                isHovered = hovering
            }
        }
    }

    // MARK: - Top Row: Priority + Identifier + Running + Status Badge

    private var topRow: some View {
        HStack(spacing: SymphonyDesignStyle.Spacing.sm) {
            SymphonyPriorityDotView(level: viewModel.priorityLevel)

            Text(viewModel.identifier)
                .font(SymphonyDesignStyle.Typography.micro)
                .foregroundStyle(SymphonyDesignStyle.Text.secondary)

            if viewModel.isRunning {
                SymphonyPulsingDotView(color: SymphonyDesignStyle.Status.color(for: viewModel.statusKey))
            }

            Spacer()

            SymphonyStatusBadgeView(
                statusLabel(for: viewModel.statusKey),
                statusKey: viewModel.statusKey,
                size: .small
            )
        }
    }

    // MARK: - Title

    private var titleRow: some View {
        VStack(alignment: .leading, spacing: SymphonyDesignStyle.Spacing.xxs) {
            Text(viewModel.title)
                .font(SymphonyDesignStyle.Typography.headline)
                .foregroundStyle(SymphonyDesignStyle.Text.primary)
                .lineLimit(2)
                .fixedSize(horizontal: false, vertical: true)

            if let scopeName = viewModel.scopeName,
               scopeName.isEmpty == false {
                Text(scopeName)
                    .font(SymphonyDesignStyle.Typography.micro)
                    .foregroundStyle(SymphonyDesignStyle.Text.tertiary)
                    .lineLimit(1)
            }
        }
    }

    // MARK: - Bottom Row: Agent + Labels + Token Count

    private var bottomRow: some View {
        HStack(spacing: SymphonyDesignStyle.Spacing.sm) {
            if let agentName = viewModel.agentName {
                SymphonyAgentAvatarView(name: agentName, size: 20)
            }

            if !viewModel.labels.isEmpty {
                labelChips
            }

            Spacer()

            if let tokenCount = viewModel.tokenCount {
                HStack(spacing: SymphonyDesignStyle.Spacing.xxs) {
                    Image(systemName: "number.circle")
                        .font(.system(size: 9, weight: .medium))
                    Text(tokenCount)
                        .font(SymphonyDesignStyle.Typography.micro)
                }
                .foregroundStyle(SymphonyDesignStyle.Text.tertiary)
            }

            if let lastEvent = viewModel.lastEvent {
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
            ForEach(viewModel.labels.prefix(3), id: \.self) { label in
                SymphonyLabelChipView(label, color: chipColor(for: label))
            }
        }
    }

    // MARK: - Helpers

    private func statusLabel(for key: String) -> String {
        switch key.lowercased() {
        case "backlog": return "Backlog"
        case "ready", "claimed": return "Ready"
        case "in_progress", "inprogress", "doing", "running": return "In Progress"
        case "blocked", "retry_queued", "retryqueued": return "Blocked"
        case "review": return "Review"
        case "done", "completed": return "Done"
        default: return key.capitalized
        }
    }

    private func chipColor(for label: String) -> Color {
        switch label.lowercased() {
        case "symphony": return SymphonyDesignStyle.Accent.teal
        case "dashboard": return SymphonyDesignStyle.Accent.blue
        case "detail": return SymphonyDesignStyle.Accent.lavender
        case "refresh": return SymphonyDesignStyle.Accent.amber
        case "bug", "fix": return SymphonyDesignStyle.Accent.coral
        case "feature": return SymphonyDesignStyle.Accent.green
        case "infra": return SymphonyDesignStyle.Accent.indigo
        default: return SymphonyDesignStyle.Accent.blue
        }
    }
}

// MARK: - Preview

#Preview("Kanban Card - Running") {
    SymphonyKanbanCardView(
        viewModel: SymphonyKanbanCardViewModel(
            id: "issue-142",
            identifier: "KAN-142",
            title: "Rebuild Symphony dashboard pipeline",
            priorityLevel: 2,
            statusKey: "in_progress",
            agentName: "Codex Agent",
            labels: ["symphony", "dashboard"],
            tokenCount: "16k",
            lastEvent: "tool_call",
            lastEventTime: "2m ago",
            isRunning: true
        )
    )
    .frame(width: 300)
    .padding()
    .background(SymphonyDesignStyle.Background.secondary)
}

#Preview("Kanban Card - Blocked") {
    SymphonyKanbanCardView(
        viewModel: SymphonyKanbanCardViewModel(
            id: "issue-181",
            identifier: "KAN-181",
            title: "Harden refresh route selection handling",
            priorityLevel: 2,
            statusKey: "blocked",
            agentName: "Codex Agent",
            labels: ["symphony", "refresh"],
            tokenCount: nil,
            lastEvent: "retry_scheduled",
            lastEventTime: "5m ago",
            isRunning: false
        )
    )
    .frame(width: 300)
    .padding()
    .background(SymphonyDesignStyle.Background.secondary)
}
