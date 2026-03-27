import SwiftUI

// MARK: - SymphonyActivityTimelineView
/// Full-page activity timeline for the "Activity" tab.
/// Shows all agent activity across all issues in a vertical timeline.
/// Called from SymphonyContentRouterView with no parameters.

public struct SymphonyActivityTimelineView: View {
    @State private var selectedFilter: TimelineFilterView = .all
    @State private var isVisible = false

    public init() {}

    public var body: some View {
        VStack(spacing: 0) {
            // Filter bar
            filterBar
                .padding(.horizontal, SymphonyDesignStyle.Spacing.xl)
                .padding(.top, SymphonyDesignStyle.Spacing.lg)
                .padding(.bottom, SymphonyDesignStyle.Spacing.md)

            // Timeline content
            ScrollView(.vertical, showsIndicators: true) {
                LazyVStack(spacing: 0) {
                    let filtered = filteredEntries
                    if filtered.isEmpty {
                        emptyTimeline
                    } else {
                        ForEach(Array(filtered.enumerated()), id: \.element.id) { index, entry in
                            timelineRow(entry: entry, index: index, isLast: index == filtered.count - 1)
                                .symphonyStaggerIn(index: index, isVisible: isVisible)
                        }
                    }
                }
                .padding(.horizontal, SymphonyDesignStyle.Spacing.xl)
                .padding(.bottom, SymphonyDesignStyle.Spacing.xxxl)
            }
        }
        .background(SymphonyDesignStyle.Background.secondary)
        .onAppear {
            withAnimation(SymphonyDesignStyle.Motion.gentle) {
                isVisible = true
            }
        }
    }

    // MARK: - Filter Bar

    private var filterBar: some View {
        HStack(spacing: SymphonyDesignStyle.Spacing.sm) {
            Text("Activity")
                .font(SymphonyDesignStyle.Typography.title)
                .foregroundStyle(SymphonyDesignStyle.Text.primary)

            Spacer()

            HStack(spacing: SymphonyDesignStyle.Spacing.xxs) {
                ForEach(TimelineFilterView.allCases, id: \.self) { filter in
                    filterChip(filter)
                }
            }
        }
    }

    private func filterChip(_ filter: TimelineFilterView) -> some View {
        let isActive = selectedFilter == filter
        return Button {
            withAnimation(SymphonyDesignStyle.Motion.snappy) {
                selectedFilter = filter
            }
        } label: {
            Text(filter.label)
                .font(SymphonyDesignStyle.Typography.caption)
                .fontWeight(isActive ? .semibold : .medium)
                .foregroundStyle(isActive ? filter.color : SymphonyDesignStyle.Text.tertiary)
                .padding(.horizontal, SymphonyDesignStyle.Spacing.md)
                .padding(.vertical, SymphonyDesignStyle.Spacing.xs + 2)
                .background(
                    Capsule(style: .continuous)
                        .fill(isActive ? filter.color.opacity(0.12) : Color.clear)
                )
                .overlay(
                    Capsule(style: .continuous)
                        .strokeBorder(
                            isActive ? filter.color.opacity(0.20) : SymphonyDesignStyle.Border.subtle,
                            lineWidth: 0.5
                        )
                )
        }
        .buttonStyle(.plain)
    }

    // MARK: - Timeline Row

    private func timelineRow(entry: SymphonyTimelineEntryViewModel, index: Int, isLast: Bool) -> some View {
        HStack(alignment: .top, spacing: SymphonyDesignStyle.Spacing.lg) {
            // Timestamp column
            VStack(alignment: .trailing, spacing: SymphonyDesignStyle.Spacing.xxs) {
                Text(entry.timestamp)
                    .font(SymphonyDesignStyle.Typography.micro)
                    .foregroundStyle(SymphonyDesignStyle.Text.tertiary)
                    .frame(width: 70, alignment: .trailing)
            }
            .padding(.top, 6)

            // Timeline spine
            VStack(spacing: 0) {
                statusDot(for: entry)
                    .padding(.top, 4)

                if !isLast {
                    Rectangle()
                        .fill(
                            LinearGradient(
                                colors: [
                                    SymphonyDesignStyle.Status.color(for: entry.statusKey).opacity(0.3),
                                    SymphonyDesignStyle.Border.default
                                ],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                        .frame(width: 1)
                        .frame(maxHeight: .infinity)
                }
            }
            .frame(width: 20)

            // Entry card
            entryCard(entry)
                .padding(.bottom, isLast ? 0 : SymphonyDesignStyle.Spacing.md)
        }
    }

    @ViewBuilder
    private func statusDot(for entry: SymphonyTimelineEntryViewModel) -> some View {
        let color = SymphonyDesignStyle.Status.color(for: entry.statusKey)
        let isRunning = entry.statusKey.lowercased() == "running"
            || entry.statusKey.lowercased() == "in_progress"

        if isRunning {
            SymphonyPulsingDotView(color: color)
        } else {
            ZStack {
                Circle()
                    .fill(color.opacity(0.2))
                    .frame(width: 14, height: 14)

                Circle()
                    .fill(color)
                    .frame(width: 8, height: 8)
            }
        }
    }

    private func entryCard(_ entry: SymphonyTimelineEntryViewModel) -> some View {
        VStack(alignment: .leading, spacing: SymphonyDesignStyle.Spacing.sm) {
            // Top row: event type badge + issue identifier
            HStack(alignment: .center, spacing: SymphonyDesignStyle.Spacing.sm) {
                eventTypeBadge(entry.eventType)

                if let issueId = entry.issueIdentifier {
                    Text(issueId)
                        .font(SymphonyDesignStyle.Typography.micro)
                        .fontWeight(.bold)
                        .foregroundStyle(SymphonyDesignStyle.Accent.blue)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(
                            RoundedRectangle(cornerRadius: SymphonyDesignStyle.Radius.xs, style: .continuous)
                                .fill(SymphonyDesignStyle.Accent.blue.opacity(0.08))
                        )
                }

                Spacer()

                if let agentName = entry.agentName {
                    SymphonyAgentAvatarView(name: agentName, size: 20)
                }
            }

            // Message
            Text(entry.message)
                .font(SymphonyDesignStyle.Typography.body)
                .foregroundStyle(SymphonyDesignStyle.Text.primary)
                .lineLimit(3)

            // Detail lines
            if !entry.detailLines.isEmpty {
                VStack(alignment: .leading, spacing: SymphonyDesignStyle.Spacing.xxs) {
                    ForEach(entry.detailLines, id: \.self) { line in
                        Text(line)
                            .font(SymphonyDesignStyle.Typography.code)
                            .foregroundStyle(SymphonyDesignStyle.Text.tertiary)
                            .lineLimit(1)
                            .truncationMode(.middle)
                    }
                }
            }
        }
        .padding(SymphonyDesignStyle.Spacing.md)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: SymphonyDesignStyle.Radius.md, style: .continuous)
                .fill(SymphonyDesignStyle.Background.tertiary)
        )
        .overlay(
            RoundedRectangle(cornerRadius: SymphonyDesignStyle.Radius.md, style: .continuous)
                .strokeBorder(
                    SymphonyDesignStyle.Status.color(for: entry.statusKey).opacity(0.10),
                    lineWidth: 0.5
                )
        )
    }

    private func eventTypeBadge(_ eventType: String) -> some View {
        let color = eventColor(for: eventType)
        let icon = eventIcon(for: eventType)

        return HStack(spacing: SymphonyDesignStyle.Spacing.xxs) {
            Image(systemName: icon)
                .font(.system(size: 8, weight: .bold))

            Text(eventType)
                .font(SymphonyDesignStyle.Typography.micro)
                .fontWeight(.bold)
                .textCase(.uppercase)
        }
        .foregroundStyle(color)
        .padding(.horizontal, 8)
        .padding(.vertical, 3)
        .background(
            Capsule(style: .continuous)
                .fill(color.opacity(0.12))
        )
        .overlay(
            Capsule(style: .continuous)
                .strokeBorder(color.opacity(0.20), lineWidth: 0.5)
        )
    }

    // MARK: - Empty State

    private var emptyTimeline: some View {
        SymphonyEmptyStateView(
            icon: "clock.arrow.circlepath",
            title: "No Activity",
            message: "No timeline entries match the current filter. Agent activity will appear here as issues are processed."
        )
        .padding(.top, SymphonyDesignStyle.Spacing.xxxl)
    }

    // MARK: - Filter Logic

    private var filteredEntries: [SymphonyTimelineEntryViewModel] {
        switch selectedFilter {
        case .all:
            return Self.mockEntries
        case .running:
            return Self.mockEntries.filter {
                $0.statusKey.lowercased() == "running"
                || $0.statusKey.lowercased() == "in_progress"
                || $0.statusKey.lowercased() == "doing"
            }
        case .errors:
            return Self.mockEntries.filter {
                $0.statusKey.lowercased() == "blocked"
                || $0.eventType.lowercased() == "error"
            }
        case .completed:
            return Self.mockEntries.filter {
                $0.statusKey.lowercased() == "done"
                || $0.statusKey.lowercased() == "completed"
                || $0.eventType.lowercased() == "completed"
            }
        }
    }

    // MARK: - Helpers

    private func eventColor(for type: String) -> Color {
        switch type.lowercased() {
        case "tool_call": return SymphonyDesignStyle.Accent.blue
        case "build": return SymphonyDesignStyle.Accent.green
        case "lint": return SymphonyDesignStyle.Accent.lavender
        case "error": return SymphonyDesignStyle.Accent.coral
        case "retry": return SymphonyDesignStyle.Accent.amber
        case "completed": return SymphonyDesignStyle.Accent.green
        default: return SymphonyDesignStyle.Accent.teal
        }
    }

    private func eventIcon(for type: String) -> String {
        switch type.lowercased() {
        case "tool_call": return "wrench"
        case "build": return "hammer"
        case "lint": return "checkmark.shield"
        case "error": return "exclamationmark.triangle"
        case "retry": return "arrow.clockwise"
        case "completed": return "checkmark.circle"
        default: return "bolt"
        }
    }
}

// MARK: - TimelineFilterView

private enum TimelineFilterView: CaseIterable {
    case all, running, errors, completed

    var label: String {
        switch self {
        case .all: return "All"
        case .running: return "Running"
        case .errors: return "Errors"
        case .completed: return "Completed"
        }
    }

    var color: Color {
        switch self {
        case .all: return SymphonyDesignStyle.Accent.blue
        case .running: return SymphonyDesignStyle.Accent.teal
        case .errors: return SymphonyDesignStyle.Accent.coral
        case .completed: return SymphonyDesignStyle.Accent.green
        }
    }
}

// MARK: - Mock Data

extension SymphonyActivityTimelineView {
    static let mockEntries: [SymphonyTimelineEntryViewModel] = [
        SymphonyTimelineEntryViewModel(
            id: "tl-1",
            timestamp: "09:42 AM",
            issueIdentifier: "KAN-142",
            eventType: "tool_call",
            message: "Agent started working on dashboard pipeline rebuild",
            detailLines: ["Analyzing SymphonyDashboardPresenter.swift"],
            agentName: "Codex Alpha",
            statusKey: "running"
        ),
        SymphonyTimelineEntryViewModel(
            id: "tl-2",
            timestamp: "09:38 AM",
            issueIdentifier: "KAN-145",
            eventType: "completed",
            message: "Generated pull request for authentication flow",
            detailLines: [
                "PR #312 opened",
                "Branch: feature/auth-flow"
            ],
            agentName: "Codex Beta",
            statusKey: "done"
        ),
        SymphonyTimelineEntryViewModel(
            id: "tl-3",
            timestamp: "09:35 AM",
            issueIdentifier: "KAN-142",
            eventType: "build",
            message: "Build succeeded after presenter refactor",
            detailLines: ["Build time: 34s", "0 warnings"],
            agentName: "Codex Alpha",
            statusKey: "running"
        ),
        SymphonyTimelineEntryViewModel(
            id: "tl-4",
            timestamp: "09:31 AM",
            issueIdentifier: "KAN-139",
            eventType: "error",
            message: "Blocked due to unresolved merge conflict in KanbanBoardView",
            detailLines: [
                "File: SymphonyKanbanBoardView.swift:88",
                "Conflict between main and feature/board-dnd"
            ],
            agentName: "Codex Gamma",
            statusKey: "blocked"
        ),
        SymphonyTimelineEntryViewModel(
            id: "tl-5",
            timestamp: "09:27 AM",
            issueIdentifier: "KAN-142",
            eventType: "lint",
            message: "Architecture linter passed on presentation layer",
            detailLines: ["All 14 files conform to clean architecture boundaries"],
            agentName: "Codex Alpha",
            statusKey: "running"
        ),
        SymphonyTimelineEntryViewModel(
            id: "tl-6",
            timestamp: "09:22 AM",
            issueIdentifier: "KAN-150",
            eventType: "retry",
            message: "Retrying after transient API timeout",
            detailLines: [
                "Attempt 2 of 3",
                "Previous error: HTTP 504 Gateway Timeout"
            ],
            agentName: "Codex Delta",
            statusKey: "retrying"
        ),
        SymphonyTimelineEntryViewModel(
            id: "tl-7",
            timestamp: "09:18 AM",
            issueIdentifier: "KAN-145",
            eventType: "tool_call",
            message: "Generated authentication middleware and route guards",
            detailLines: [
                "Created: AuthMiddleware.swift",
                "Created: RouteGuard.swift"
            ],
            agentName: "Codex Beta",
            statusKey: "done"
        ),
        SymphonyTimelineEntryViewModel(
            id: "tl-8",
            timestamp: "09:14 AM",
            issueIdentifier: "KAN-151",
            eventType: "completed",
            message: "Issue resolved — unit tests added for retry logic",
            detailLines: [
                "12 tests passing",
                "Coverage: 94%"
            ],
            agentName: "Codex Alpha",
            statusKey: "completed"
        ),
        SymphonyTimelineEntryViewModel(
            id: "tl-9",
            timestamp: "09:10 AM",
            issueIdentifier: "KAN-139",
            eventType: "tool_call",
            message: "Attempted auto-merge resolution",
            detailLines: ["Strategy: ours — preserving feature branch changes"],
            agentName: "Codex Gamma",
            statusKey: "blocked"
        ),
        SymphonyTimelineEntryViewModel(
            id: "tl-10",
            timestamp: "09:05 AM",
            issueIdentifier: nil,
            eventType: "build",
            message: "Full workspace build completed across all active issues",
            detailLines: [
                "4 targets built",
                "Total time: 1m 12s"
            ],
            agentName: nil,
            statusKey: "done"
        )
    ]
}

// MARK: - Previews

#Preview("Activity Timeline") {
    SymphonyActivityTimelineView()
        .frame(width: 700, height: 800)
}

#Preview("Activity Timeline — Narrow") {
    SymphonyActivityTimelineView()
        .frame(width: 420, height: 700)
}
