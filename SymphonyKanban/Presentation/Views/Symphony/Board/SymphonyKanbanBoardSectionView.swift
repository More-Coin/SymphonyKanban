import SwiftUI

// MARK: - SymphonyKanbanBoardSectionView
/// Renders a single grouped section of the Kanban board with an optional
/// title/subtitle header, an error banner, and the horizontal columns
/// scroll view.

public struct SymphonyKanbanBoardSectionView: View {
    private let section: SymphonyKanbanBoardSectionViewModel
    private let sectionIndex: Int
    private let dropTargetColumnID: String?
    private let appeared: Bool
    private let onCardSelected: (String) -> Void
    private let onDropTargetChanged: (String?) -> Void

    public init(
        section: SymphonyKanbanBoardSectionViewModel,
        sectionIndex: Int,
        dropTargetColumnID: String?,
        appeared: Bool,
        onCardSelected: @escaping (String) -> Void,
        onDropTargetChanged: @escaping (String?) -> Void
    ) {
        self.section = section
        self.sectionIndex = sectionIndex
        self.dropTargetColumnID = dropTargetColumnID
        self.appeared = appeared
        self.onCardSelected = onCardSelected
        self.onDropTargetChanged = onDropTargetChanged
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: SymphonyDesignStyle.Spacing.md) {
            if let title = section.title {
                VStack(alignment: .leading, spacing: SymphonyDesignStyle.Spacing.xs) {
                    Text(title)
                        .font(SymphonyDesignStyle.Typography.title3)
                        .foregroundStyle(SymphonyDesignStyle.Text.primary)

                    if let subtitle = section.subtitle,
                       subtitle.isEmpty == false {
                        Text(subtitle)
                            .font(SymphonyDesignStyle.Typography.caption)
                            .foregroundStyle(SymphonyDesignStyle.Text.tertiary)
                    }
                }
            }

            if let errorMessage = section.errorMessage,
               errorMessage.isEmpty == false {
                SymphonyKanbanSectionErrorView(message: errorMessage)
            }

            SymphonyKanbanColumnsScrollView(
                columns: section.columns,
                animationOffset: sectionIndex * 10,
                dropTargetColumnID: dropTargetColumnID,
                appeared: appeared,
                onCardSelected: onCardSelected,
                onDropTargetChanged: onDropTargetChanged
            )
        }
    }
}

// MARK: - SymphonyKanbanSectionErrorView
/// An error banner displayed within a board section when an issue
/// prevents normal rendering of that section's data.

public struct SymphonyKanbanSectionErrorView: View {
    private let message: String

    public init(message: String) {
        self.message = message
    }

    public var body: some View {
        HStack(spacing: SymphonyDesignStyle.Spacing.sm) {
            Image(systemName: "exclamationmark.triangle.fill")
                .foregroundStyle(SymphonyDesignStyle.Accent.coral)
            Text(message)
                .font(SymphonyDesignStyle.Typography.caption)
                .foregroundStyle(SymphonyDesignStyle.Text.secondary)
        }
        .padding(.horizontal, SymphonyDesignStyle.Spacing.md)
        .padding(.vertical, SymphonyDesignStyle.Spacing.sm)
        .background(SymphonyDesignStyle.Background.tertiary)
        .clipShape(
            RoundedRectangle(
                cornerRadius: SymphonyDesignStyle.Radius.lg,
                style: .continuous
            )
        )
    }
}

// MARK: - Preview

#Preview("Board Section") {
    let boardViewModel = SymphonyPreviewDI.makeBoardViewModel()

    SymphonyKanbanBoardSectionView(
        section: boardViewModel.sections.first ?? SymphonyKanbanBoardSectionViewModel(
            id: "preview",
            title: nil,
            subtitle: nil,
            errorMessage: nil,
            columns: []
        ),
        sectionIndex: 0,
        dropTargetColumnID: nil,
        appeared: true,
        onCardSelected: { _ in },
        onDropTargetChanged: { _ in }
    )
    .frame(minWidth: 1200, minHeight: 500)
    .background(SymphonyDesignStyle.Background.secondary)
}
