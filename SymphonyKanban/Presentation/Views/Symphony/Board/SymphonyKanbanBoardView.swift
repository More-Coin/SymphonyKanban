import SwiftUI

// MARK: - SymphonyKanbanBoardView
/// The main Kanban board surface. Renders six status columns in a
/// horizontal scroll view, each containing a vertically scrollable
/// list of issue cards. Supports drag-and-drop between columns and
/// staggered entrance animations.

public struct SymphonyKanbanBoardView: View {
    private let viewModel: SymphonyKanbanBoardViewModel
    private let onCardSelected: (String) -> Void
    private let onCancelIssue: (String) -> Void
    private let onBackgroundTapped: () -> Void

    @State private var dropTargetColumnID: String?
    @State private var appeared = false

    public init(
        viewModel: SymphonyKanbanBoardViewModel,
        onCardSelected: @escaping (String) -> Void = { _ in },
        onCancelIssue: @escaping (String) -> Void = { _ in },
        onBackgroundTapped: @escaping () -> Void = {}
    ) {
        self.viewModel = viewModel
        self.onCardSelected = onCardSelected
        self.onCancelIssue = onCancelIssue
        self.onBackgroundTapped = onBackgroundTapped
    }

    public var body: some View {
        Group {
            if shouldRenderSections {
                ScrollView(.vertical, showsIndicators: false) {
                    VStack(alignment: .leading, spacing: SymphonyDesignStyle.Spacing.xl) {
                        ForEach(Array(viewModel.sections.enumerated()), id: \.element.id) { index, section in
                            SymphonyKanbanBoardSectionView(
                                section: section,
                                sectionIndex: index,
                                dropTargetColumnID: dropTargetColumnID,
                                appeared: appeared,
                                onCardSelected: onCardSelected,
                                onCancelIssue: onCancelIssue,
                                onDropTargetChanged: { dropTargetColumnID = $0 }
                            )
                        }
                    }
                    .padding(.horizontal, SymphonyDesignStyle.Spacing.xl)
                    .padding(.vertical, SymphonyDesignStyle.Spacing.lg)
                }
            } else {
                SymphonyKanbanColumnsScrollView(
                    columns: viewModel.columns,
                    animationOffset: 0,
                    dropTargetColumnID: dropTargetColumnID,
                    appeared: appeared,
                    onCardSelected: onCardSelected,
                    onCancelIssue: onCancelIssue,
                    onDropTargetChanged: { dropTargetColumnID = $0 }
                )
            }
        }
        .background(SymphonyDesignStyle.Background.secondary.ignoresSafeArea())
        .contentShape(Rectangle())
        .onTapGesture {
            onBackgroundTapped()
        }
        .onAppear {
            withAnimation(SymphonyDesignStyle.Motion.gentle) {
                appeared = true
            }
        }
    }

    private var shouldRenderSections: Bool {
        viewModel.sections.count > 1 || viewModel.sections.contains {
            $0.title != nil || $0.errorMessage != nil
        }
    }
}

// MARK: - Preview

#Preview("Kanban Board") {
    SymphonyKanbanBoardView(
        viewModel: SymphonyPreviewDI.makeBoardViewModel(),
        onCardSelected: { id in
            print("Selected: \(id)")
        }
    )
    .frame(minWidth: 1200, minHeight: 700)
}
