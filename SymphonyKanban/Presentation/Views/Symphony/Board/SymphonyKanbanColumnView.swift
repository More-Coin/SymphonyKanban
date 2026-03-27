import SwiftUI

// MARK: - SymphonyKanbanColumnView
/// A single Kanban column with a status-colored header, count badge,
/// and a vertically scrollable list of cards. Supports drop targeting
/// for drag-and-drop reordering.

public struct SymphonyKanbanColumnView: View {
    let viewModel: SymphonyKanbanColumnViewModel
    let isDropTarget: Bool
    let onCardSelected: (String) -> Void
    let onDrop: ([SymphonyKanbanCardViewModel]) -> Void

    @State private var appeared = false

    public init(
        viewModel: SymphonyKanbanColumnViewModel,
        isDropTarget: Bool = false,
        onCardSelected: @escaping (String) -> Void = { _ in },
        onDrop: @escaping ([SymphonyKanbanCardViewModel]) -> Void = { _ in }
    ) {
        self.viewModel = viewModel
        self.isDropTarget = isDropTarget
        self.onCardSelected = onCardSelected
        self.onDrop = onDrop
    }

    public var body: some View {
        VStack(spacing: 0) {
            columnHeader
                .padding(.horizontal, SymphonyDesignStyle.Spacing.md)
                .padding(.top, SymphonyDesignStyle.Spacing.md)
                .padding(.bottom, SymphonyDesignStyle.Spacing.sm)

            SymphonyDividerView(opacity: 0.04)
                .padding(.horizontal, SymphonyDesignStyle.Spacing.md)

            cardList
        }
        .frame(
            minWidth: SymphonyDesignStyle.Kanban.columnMinWidth,
            maxWidth: SymphonyDesignStyle.Kanban.columnMaxWidth
        )
        .symphonyColumnWell()
        .overlay(
            RoundedRectangle(cornerRadius: SymphonyDesignStyle.Radius.xl, style: .continuous)
                .strokeBorder(
                    statusColor.opacity(isDropTarget ? 0.4 : 0),
                    lineWidth: 2
                )
        )
        .animation(SymphonyDesignStyle.Motion.snappy, value: isDropTarget)
        .onAppear {
            withAnimation(SymphonyDesignStyle.Motion.gentle) {
                appeared = true
            }
        }
    }

    // MARK: - Column Header

    private var columnHeader: some View {
        HStack(spacing: SymphonyDesignStyle.Spacing.sm) {
            // Status accent bar
            RoundedRectangle(cornerRadius: 2, style: .continuous)
                .fill(statusColor)
                .frame(width: 3, height: 16)

            SymphonySectionHeaderView(
                viewModel.title,
                count: viewModel.count,
                accentColor: statusColor
            )
        }
    }

    // MARK: - Card List

    private var cardList: some View {
        ScrollView(.vertical, showsIndicators: false) {
            LazyVStack(spacing: SymphonyDesignStyle.Kanban.cardSpacing) {
                ForEach(Array(viewModel.cards.enumerated()), id: \.element.id) { index, card in
                    SymphonyKanbanCardView(viewModel: card) {
                        onCardSelected(card.identifier)
                    }
                    .draggable(card.identifier)
                    .symphonyStaggerIn(index: index, isVisible: appeared)
                }
            }
            .padding(.horizontal, SymphonyDesignStyle.Spacing.sm)
            .padding(.top, SymphonyDesignStyle.Spacing.sm)
            .padding(.bottom, SymphonyDesignStyle.Spacing.md)
        }
        .dropDestination(for: String.self) { items, _ in
            // Accept the drop -- the board view handles actual card movement
            return !items.isEmpty
        } isTargeted: { targeted in
            // Handled by parent via isDropTarget binding
        }
    }

    // MARK: - Helpers

    private var statusColor: Color {
        SymphonyDesignStyle.Status.color(for: viewModel.statusKey)
    }
}

// MARK: - Preview

#Preview("Kanban Column") {
    SymphonyKanbanColumnView(
        viewModel: SymphonyKanbanColumnViewModel(
            id: "in_progress",
            title: "In Progress",
            statusKey: "in_progress",
            cards: [
                SymphonyKanbanCardViewModel(
                    id: "issue-142",
                    identifier: "KAN-142",
                    title: "Rebuild Symphony dashboard pipeline",
                    priorityLevel: 2,
                    statusKey: "in_progress",
                    agentName: "Codex Agent",
                    labels: ["symphony", "dashboard"],
                    tokenCount: "16k",
                    lastEvent: "tool_call",
                    isRunning: true
                ),
                SymphonyKanbanCardViewModel(
                    id: "issue-205",
                    identifier: "KAN-205",
                    title: "Add drag-and-drop to Kanban board",
                    priorityLevel: 3,
                    statusKey: "in_progress",
                    agentName: "Codex Agent",
                    labels: ["feature"],
                    isRunning: true
                )
            ]
        ),
        onCardSelected: { _ in }
    )
    .frame(height: 500)
    .padding()
    .background(SymphonyDesignStyle.Background.secondary)
}
