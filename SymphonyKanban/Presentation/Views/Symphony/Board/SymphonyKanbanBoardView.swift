import SwiftUI

// MARK: - SymphonyKanbanBoardView
/// The main Kanban board surface. Renders six status columns in a
/// horizontal scroll view, each containing a vertically scrollable
/// list of issue cards. Supports drag-and-drop between columns and
/// staggered entrance animations.

public struct SymphonyKanbanBoardView: View {
    private let viewModel: SymphonyKanbanBoardViewModel
    private let onCardSelected: (String) -> Void
    private let onBackgroundTapped: () -> Void

    @State private var dropTargetColumnID: String?
    @State private var appeared = false

    public init(
        viewModel: SymphonyKanbanBoardViewModel = Self.mockBoardViewModel,
        onCardSelected: @escaping (String) -> Void = { _ in },
        onBackgroundTapped: @escaping () -> Void = {}
    ) {
        self.viewModel = viewModel
        self.onCardSelected = onCardSelected
        self.onBackgroundTapped = onBackgroundTapped
    }

    public var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(alignment: .top, spacing: SymphonyDesignStyle.Kanban.columnSpacing) {
                ForEach(Array(viewModel.columns.enumerated()), id: \.element.id) { index, column in
                    SymphonyKanbanColumnView(
                        viewModel: column,
                        isDropTarget: dropTargetColumnID == column.id,
                        onCardSelected: onCardSelected,
                        onDrop: { _ in }
                    )
                    .dropDestination(for: String.self) { items, _ in
                        dropTargetColumnID = nil
                        return !items.isEmpty
                    } isTargeted: { targeted in
                        withAnimation(SymphonyDesignStyle.Motion.snappy) {
                            dropTargetColumnID = targeted ? column.id : nil
                        }
                    }
                    .symphonyStaggerIn(index: index, isVisible: appeared)
                }
            }
            .padding(.horizontal, SymphonyDesignStyle.Spacing.xl)
            .padding(.vertical, SymphonyDesignStyle.Spacing.lg)
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
}

// MARK: - Static Mock Data

extension SymphonyKanbanBoardView {
    /// Pre-populated board for previews and demo mode. Includes the 3 real
    /// issues from the static adapter plus 7 additional mock cards spread
    /// across all 6 columns.
    public static let mockBoardViewModel = SymphonyKanbanBoardViewModel(
        columns: [
            // ── Backlog ──────────────────────────────────────────────
            SymphonyKanbanColumnViewModel(
                id: "backlog",
                title: "Backlog",
                statusKey: "backlog",
                cards: [
                    SymphonyKanbanCardViewModel(
                        id: "issue-210",
                        identifier: "KAN-210",
                        title: "Implement workspace snapshot archiver",
                        priorityLevel: 4,
                        statusKey: "backlog",
                        labels: ["infra"]
                    ),
                    SymphonyKanbanCardViewModel(
                        id: "issue-215",
                        identifier: "KAN-215",
                        title: "Add onboarding flow for new workspaces",
                        priorityLevel: 3,
                        statusKey: "backlog",
                        labels: ["feature"]
                    )
                ]
            ),

            // ── Ready ────────────────────────────────────────────────
            SymphonyKanbanColumnViewModel(
                id: "ready",
                title: "Ready",
                statusKey: "ready",
                cards: [
                    SymphonyKanbanCardViewModel(
                        id: "issue-198",
                        identifier: "KAN-198",
                        title: "Wire agent health-check heartbeat endpoint",
                        priorityLevel: 2,
                        statusKey: "ready",
                        agentName: "Codex Agent",
                        labels: ["symphony", "infra"]
                    )
                ]
            ),

            // ── In Progress ──────────────────────────────────────────
            SymphonyKanbanColumnViewModel(
                id: "in_progress",
                title: "In Progress",
                statusKey: "in_progress",
                cards: [
                    // Real issue from adapter
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
                        lastEventTime: "2m ago",
                        isRunning: true
                    ),
                    SymphonyKanbanCardViewModel(
                        id: "issue-205",
                        identifier: "KAN-205",
                        title: "Build Kanban board drag-and-drop support",
                        priorityLevel: 3,
                        statusKey: "in_progress",
                        agentName: "Codex Agent",
                        labels: ["feature"],
                        tokenCount: "8k",
                        lastEvent: "build",
                        lastEventTime: "5m ago",
                        isRunning: true
                    )
                ]
            ),

            // ── Blocked ──────────────────────────────────────────────
            SymphonyKanbanColumnViewModel(
                id: "blocked",
                title: "Blocked",
                statusKey: "blocked",
                cards: [
                    // Real issue from adapter
                    SymphonyKanbanCardViewModel(
                        id: "issue-181",
                        identifier: "KAN-181",
                        title: "Harden refresh route selection handling",
                        priorityLevel: 2,
                        statusKey: "blocked",
                        agentName: "Codex Agent",
                        labels: ["symphony", "refresh"],
                        lastEvent: "retry_scheduled",
                        lastEventTime: "5m ago",
                        isRunning: false
                    )
                ]
            ),

            // ── Review ───────────────────────────────────────────────
            SymphonyKanbanColumnViewModel(
                id: "review",
                title: "Review",
                statusKey: "review",
                cards: [
                    // Real issue from adapter
                    SymphonyKanbanCardViewModel(
                        id: "issue-177",
                        identifier: "KAN-177",
                        title: "Wire issue detail renderer",
                        priorityLevel: 3,
                        statusKey: "review",
                        agentName: "Codex Agent",
                        labels: ["symphony", "detail"],
                        tokenCount: "11.4k",
                        lastEvent: "lint",
                        lastEventTime: "10m ago",
                        isRunning: false
                    ),
                    SymphonyKanbanCardViewModel(
                        id: "issue-192",
                        identifier: "KAN-192",
                        title: "Add token usage breakdown chart",
                        priorityLevel: 3,
                        statusKey: "review",
                        agentName: "Codex Agent",
                        labels: ["dashboard"],
                        tokenCount: "6.2k",
                        isRunning: false
                    )
                ]
            ),

            // ── Done ─────────────────────────────────────────────────
            SymphonyKanbanColumnViewModel(
                id: "done",
                title: "Done",
                statusKey: "done",
                cards: [
                    SymphonyKanbanCardViewModel(
                        id: "issue-130",
                        identifier: "KAN-130",
                        title: "Scaffold clean architecture layer boundaries",
                        priorityLevel: 1,
                        statusKey: "done",
                        labels: ["infra"],
                        isRunning: false
                    ),
                    SymphonyKanbanCardViewModel(
                        id: "issue-135",
                        identifier: "KAN-135",
                        title: "Set up design token system",
                        priorityLevel: 2,
                        statusKey: "done",
                        labels: ["symphony"],
                        isRunning: false
                    )
                ]
            )
        ]
    )
}

// MARK: - Preview

#Preview("Kanban Board") {
    SymphonyKanbanBoardView(
        viewModel: SymphonyKanbanBoardView.mockBoardViewModel,
        onCardSelected: { id in
            print("Selected: \(id)")
        }
    )
    .frame(minWidth: 1200, minHeight: 700)
}
