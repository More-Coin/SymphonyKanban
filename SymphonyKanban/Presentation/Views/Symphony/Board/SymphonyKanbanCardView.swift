import SwiftUI

// MARK: - SymphonyKanbanCardView
/// Individual Kanban card displaying key issue information with hover
/// effects, priority indicators, and agent avatars.

public struct SymphonyKanbanCardView: View {
    let viewModel: SymphonyKanbanCardViewModel
    let onTap: () -> Void
    let onCancelIssue: (String) -> Void

    @State private var isHovered = false

    public init(
        viewModel: SymphonyKanbanCardViewModel,
        onTap: @escaping () -> Void = {},
        onCancelIssue: @escaping (String) -> Void = { _ in }
    ) {
        self.viewModel = viewModel
        self.onTap = onTap
        self.onCancelIssue = onCancelIssue
    }

    public var body: some View {
        Button(action: onTap) {
            VStack(alignment: .leading, spacing: SymphonyDesignStyle.Spacing.sm) {
                SymphonyKanbanCardTopRowView(
                    identifier: viewModel.identifier,
                    priorityLevel: viewModel.priorityLevel,
                    statusKey: viewModel.statusKey,
                    statusLabel: viewModel.statusLabel,
                    isRunning: viewModel.isRunning
                )
                titleRow
                SymphonyKanbanCardBottomRowView(
                    agentName: viewModel.agentName,
                    labels: viewModel.labels,
                    tokenCount: viewModel.tokenCount,
                    lastEvent: viewModel.lastEvent
                )
            }
            .padding(SymphonyDesignStyle.Spacing.md)
            .frame(maxWidth: .infinity, alignment: .leading)
            .symphonyCard()
        }
        .buttonStyle(.plain)
        .contextMenu {
            if viewModel.canCancel {
                Button(role: .destructive) {
                    onCancelIssue(viewModel.identifier)
                } label: {
                    Label("Cancel", systemImage: "xmark.circle")
                }
            }
        }
        .overlay {
            if viewModel.isUpdating {
                SymphonyKanbanCardUpdatingOverlayView()
            }
        }
        .opacity(viewModel.isUpdating ? 0.6 : (isHovered ? 0.97 : 1.0))
        .disabled(viewModel.isUpdating)
        .scaleEffect(isHovered ? 1.01 : 1.0)
        .onHover { hovering in
            withAnimation(SymphonyDesignStyle.Motion.stiffSnap) {
                isHovered = hovering
            }
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
                SymphonyLabelChipView(scopeName, color: SymphonyDesignStyle.Accent.indigo)
            }
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
            statusLabel: "In Progress",
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
            statusLabel: "Blocked",
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
