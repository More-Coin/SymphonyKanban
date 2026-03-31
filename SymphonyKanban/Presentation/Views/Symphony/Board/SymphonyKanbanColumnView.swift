import SwiftUI

// MARK: - SymphonyKanbanColumnView
/// A single Kanban column with a status-colored header, count badge,
/// and a vertically scrollable list of cards. Supports drop targeting
/// for drag-and-drop reordering.

public struct SymphonyKanbanColumnView: View {
    let viewModel: SymphonyKanbanColumnViewModel
    let isDropTarget: Bool
    let onCardSelected: (String) -> Void
    let onCancelIssue: (String) -> Void
    let onDrop: ([SymphonyKanbanCardViewModel]) -> Void

    @State private var appeared = false

    public init(
        viewModel: SymphonyKanbanColumnViewModel,
        isDropTarget: Bool = false,
        onCardSelected: @escaping (String) -> Void = { _ in },
        onCancelIssue: @escaping (String) -> Void = { _ in },
        onDrop: @escaping ([SymphonyKanbanCardViewModel]) -> Void = { _ in }
    ) {
        self.viewModel = viewModel
        self.isDropTarget = isDropTarget
        self.onCardSelected = onCardSelected
        self.onCancelIssue = onCancelIssue
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
                    SymphonyKanbanCardView(
                        viewModel: card,
                        onTap: { onCardSelected(card.identifier) },
                        onCancelIssue: onCancelIssue
                    )
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
    let previewColumn = SymphonyPreviewDI.makeBoardViewModel()
        .sections
        .first?
        .columns
        .first(where: { $0.cards.isEmpty == false })

    SymphonyKanbanColumnView(
        viewModel: previewColumn ?? SymphonyKanbanColumnViewModel(
            id: "empty",
            title: "Preview",
            statusKey: "ready",
            cards: []
        ),
        onCardSelected: { _ in }
    )
    .frame(height: 500)
    .padding()
    .background(SymphonyDesignStyle.Background.secondary)
}
