import SwiftUI

// MARK: - SymphonyKanbanColumnsScrollView
/// A horizontal scroll view containing Kanban columns with staggered
/// entrance animations and drag-and-drop target support.

public struct SymphonyKanbanColumnsScrollView: View {
    private let columns: [SymphonyKanbanColumnViewModel]
    private let animationOffset: Int
    private let dropTargetColumnID: String?
    private let appeared: Bool
    private let onCardSelected: (String) -> Void
    private let onDropTargetChanged: (String?) -> Void

    public init(
        columns: [SymphonyKanbanColumnViewModel],
        animationOffset: Int,
        dropTargetColumnID: String?,
        appeared: Bool,
        onCardSelected: @escaping (String) -> Void,
        onDropTargetChanged: @escaping (String?) -> Void
    ) {
        self.columns = columns
        self.animationOffset = animationOffset
        self.dropTargetColumnID = dropTargetColumnID
        self.appeared = appeared
        self.onCardSelected = onCardSelected
        self.onDropTargetChanged = onDropTargetChanged
    }

    public var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(alignment: .top, spacing: SymphonyDesignStyle.Kanban.columnSpacing) {
                ForEach(Array(columns.enumerated()), id: \.element.id) { index, column in
                    SymphonyKanbanColumnView(
                        viewModel: column,
                        isDropTarget: dropTargetColumnID == column.id,
                        onCardSelected: onCardSelected,
                        onDrop: { _ in }
                    )
                    .dropDestination(for: String.self) { items, _ in
                        onDropTargetChanged(nil)
                        return !items.isEmpty
                    } isTargeted: { targeted in
                        withAnimation(SymphonyDesignStyle.Motion.snappy) {
                            onDropTargetChanged(targeted ? column.id : nil)
                        }
                    }
                    .symphonyStaggerIn(index: animationOffset + index, isVisible: appeared)
                }
            }
        }
    }
}

// MARK: - Preview

#Preview("Columns Scroll View") {
    let boardViewModel = SymphonyPreviewDI.makeBoardViewModel()

    SymphonyKanbanColumnsScrollView(
        columns: boardViewModel.sections.first?.columns ?? [],
        animationOffset: 0,
        dropTargetColumnID: nil,
        appeared: true,
        onCardSelected: { _ in },
        onDropTargetChanged: { _ in }
    )
    .frame(minWidth: 1200, minHeight: 500)
    .background(SymphonyDesignStyle.Background.secondary)
}
