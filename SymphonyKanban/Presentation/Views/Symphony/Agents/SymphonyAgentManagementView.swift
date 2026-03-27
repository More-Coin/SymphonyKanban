import SwiftUI

// MARK: - SymphonyAgentManagementView
/// Agent dashboard showing a grid of agent cards with status, capabilities,
/// current tasks, and quick action stubs. Includes a workload summary bar.

public struct SymphonyAgentManagementView: View {
    @State private var viewModel = SymphonyAgentManagementView.mockViewModel
    @State private var appeared = false
    @State private var hoveredAgentID: String?

    private let columns = [
        GridItem(.adaptive(minimum: 320, maximum: 420), spacing: SymphonyDesignStyle.Spacing.lg)
    ]

    public init() {}

    // MARK: - Computed Metrics

    private var totalAgents: Int { viewModel.agents.count }
    private var runningCount: Int { viewModel.agents.filter { $0.statusKey == "running" }.count }
    private var idleCount: Int { viewModel.agents.filter { $0.statusKey == "idle" }.count }
    private var errorCount: Int { viewModel.agents.filter { $0.statusKey == "error" }.count }

    public var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: SymphonyDesignStyle.Spacing.xl) {
                header
                workloadSummary
                agentGrid
            }
            .padding(SymphonyDesignStyle.Spacing.xl)
        }
        .background(SymphonyDesignStyle.Background.secondary)
        .onAppear {
            withAnimation(SymphonyDesignStyle.Motion.gentle) {
                appeared = true
            }
        }
    }

    // MARK: - Header

    private var header: some View {
        VStack(alignment: .leading, spacing: SymphonyDesignStyle.Spacing.xs) {
            Text("Agent Management")
                .font(SymphonyDesignStyle.Typography.largeTitle)
                .foregroundStyle(SymphonyDesignStyle.Text.primary)

            Text("Monitor, configure, and assign work to your fleet of AI agents.")
                .font(SymphonyDesignStyle.Typography.body)
                .foregroundStyle(SymphonyDesignStyle.Text.secondary)
        }
    }

    // MARK: - Workload Summary

    private var workloadSummary: some View {
        HStack(spacing: SymphonyDesignStyle.Spacing.md) {
            SymphonyMetricTileView(
                value: "\(totalAgents)",
                label: "Total Agents",
                accentColor: SymphonyDesignStyle.Accent.blue
            )
            SymphonyMetricTileView(
                value: "\(runningCount)",
                label: "Running",
                accentColor: SymphonyDesignStyle.Accent.teal
            )
            SymphonyMetricTileView(
                value: "\(idleCount)",
                label: "Idle",
                accentColor: SymphonyDesignStyle.Text.secondary
            )
            SymphonyMetricTileView(
                value: "\(errorCount)",
                label: "Errors",
                accentColor: SymphonyDesignStyle.Accent.coral
            )
        }
        .symphonyStaggerIn(index: 0, isVisible: appeared)
    }

    // MARK: - Agent Grid

    private var agentGrid: some View {
        LazyVGrid(columns: columns, spacing: SymphonyDesignStyle.Spacing.lg) {
            ForEach(Array(viewModel.agents.enumerated()), id: \.element.id) { index, agent in
                agentCard(agent)
                    .symphonyStaggerIn(index: index + 1, isVisible: appeared)
            }
        }
    }

    // MARK: - Agent Card

    private func agentCard(_ agent: SymphonyAgentViewModel) -> some View {
        let isHovered = hoveredAgentID == agent.id

        return VStack(alignment: .leading, spacing: SymphonyDesignStyle.Spacing.md) {
            // Top row: Avatar + Name + Status
            HStack(spacing: SymphonyDesignStyle.Spacing.md) {
                SymphonyAgentAvatarView(
                    name: agent.name,
                    color: agentTypeColor(agent.type),
                    size: 40
                )

                VStack(alignment: .leading, spacing: SymphonyDesignStyle.Spacing.xxs) {
                    Text(agent.name)
                        .font(SymphonyDesignStyle.Typography.headline)
                        .foregroundStyle(SymphonyDesignStyle.Text.primary)

                    Text(agent.type)
                        .font(SymphonyDesignStyle.Typography.caption)
                        .foregroundStyle(SymphonyDesignStyle.Text.secondary)
                }

                Spacer()

                HStack(spacing: SymphonyDesignStyle.Spacing.sm) {
                    if agent.statusKey == "running" {
                        SymphonyPulsingDotView(color: SymphonyDesignStyle.Accent.teal)
                    }
                    SymphonyStatusBadgeView(agent.statusLabel, statusKey: agent.statusKey)
                }
            }

            SymphonyDividerView()

            // Capabilities
            SymphonySectionHeaderView("Capabilities")
            capabilityChips(agent.capabilities)

            // Current Task
            if let taskID = agent.currentTaskIdentifier, let taskTitle = agent.currentTaskTitle {
                SymphonyDividerView()
                SymphonySectionHeaderView("Current Task")
                HStack(spacing: SymphonyDesignStyle.Spacing.sm) {
                    Text(taskID)
                        .font(SymphonyDesignStyle.Typography.callout)
                        .fontWeight(.semibold)
                        .foregroundStyle(SymphonyDesignStyle.Accent.blue)
                    Text(taskTitle)
                        .font(SymphonyDesignStyle.Typography.body)
                        .foregroundStyle(SymphonyDesignStyle.Text.primary)
                        .lineLimit(1)
                }
            }

            SymphonyDividerView()

            // Stats Row
            HStack(spacing: SymphonyDesignStyle.Spacing.lg) {
                statItem(value: "\(agent.completedCount)", label: "Completed")
                if let tokens = agent.tokenUsage {
                    statItem(value: tokens, label: "Tokens")
                }
                Spacer()
                if let lastActive = agent.lastActiveTime {
                    Text(lastActive)
                        .font(SymphonyDesignStyle.Typography.micro)
                        .foregroundStyle(SymphonyDesignStyle.Text.tertiary)
                }
            }

            SymphonyDividerView()

            // Quick Actions
            HStack(spacing: SymphonyDesignStyle.Spacing.sm) {
                actionButton("Assign", icon: "arrow.right.circle", color: SymphonyDesignStyle.Accent.blue)
                actionButton("Pause", icon: "pause.circle", color: SymphonyDesignStyle.Accent.amber)
                actionButton("Configure", icon: "gearshape", color: SymphonyDesignStyle.Text.secondary)
                Spacer()
            }
        }
        .padding(SymphonyDesignStyle.Spacing.lg)
        .symphonyCard(selected: isHovered)
        .scaleEffect(isHovered ? 1.01 : 1.0)
        .animation(SymphonyDesignStyle.Motion.snappy, value: isHovered)
        .onHover { hovered in
            hoveredAgentID = hovered ? agent.id : nil
        }
    }

    // MARK: - Subviews

    private func capabilityChips(_ capabilities: [String]) -> some View {
        FlowLayoutView(spacing: SymphonyDesignStyle.Spacing.xs) {
            ForEach(capabilities, id: \.self) { cap in
                SymphonyLabelChipView(cap, color: SymphonyDesignStyle.Accent.lavender)
            }
        }
    }

    private func statItem(value: String, label: String) -> some View {
        VStack(alignment: .leading, spacing: 1) {
            Text(value)
                .font(SymphonyDesignStyle.Typography.callout)
                .fontWeight(.semibold)
                .foregroundStyle(SymphonyDesignStyle.Text.primary)
            Text(label)
                .font(SymphonyDesignStyle.Typography.micro)
                .foregroundStyle(SymphonyDesignStyle.Text.tertiary)
        }
    }

    private func actionButton(_ title: String, icon: String, color: Color) -> some View {
        Button {} label: {
            Label(title, systemImage: icon)
                .font(SymphonyDesignStyle.Typography.caption)
                .foregroundStyle(color)
                .padding(.horizontal, SymphonyDesignStyle.Spacing.sm)
                .padding(.vertical, SymphonyDesignStyle.Spacing.xs)
                .background(
                    RoundedRectangle(cornerRadius: SymphonyDesignStyle.Radius.sm, style: .continuous)
                        .fill(color.opacity(0.08))
                )
                .overlay(
                    RoundedRectangle(cornerRadius: SymphonyDesignStyle.Radius.sm, style: .continuous)
                        .strokeBorder(color.opacity(0.15), lineWidth: 0.5)
                )
        }
        .buttonStyle(.plain)
    }

    private func agentTypeColor(_ type: String) -> Color {
        switch type {
        case "Code Agent": return SymphonyDesignStyle.Accent.teal
        case "QA Agent": return SymphonyDesignStyle.Accent.lavender
        case "Planner Agent": return SymphonyDesignStyle.Accent.amber
        case "Review Agent": return SymphonyDesignStyle.Accent.blue
        default: return SymphonyDesignStyle.Accent.indigo
        }
    }
}

// MARK: - FlowLayoutView

/// Simple horizontal wrapping layout for capability chips.
private struct FlowLayoutView: Layout {
    let spacing: CGFloat

    init(spacing: CGFloat = 4) {
        self.spacing = spacing
    }

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let result = computeLayout(proposal: proposal, subviews: subviews)
        return result.size
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let result = computeLayout(proposal: proposal, subviews: subviews)
        for (index, subview) in subviews.enumerated() {
            let point = CGPoint(
                x: bounds.minX + result.positions[index].x,
                y: bounds.minY + result.positions[index].y
            )
            subview.place(at: point, anchor: .topLeading, proposal: .unspecified)
        }
    }

    private func computeLayout(
        proposal: ProposedViewSize,
        subviews: Subviews
    ) -> (size: CGSize, positions: [CGPoint]) {
        let maxWidth = proposal.width ?? .infinity
        var positions: [CGPoint] = []
        var currentX: CGFloat = 0
        var currentY: CGFloat = 0
        var lineHeight: CGFloat = 0
        var totalHeight: CGFloat = 0
        var totalWidth: CGFloat = 0

        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            if currentX + size.width > maxWidth, currentX > 0 {
                currentX = 0
                currentY += lineHeight + spacing
                lineHeight = 0
            }
            positions.append(CGPoint(x: currentX, y: currentY))
            lineHeight = max(lineHeight, size.height)
            currentX += size.width + spacing
            totalWidth = max(totalWidth, currentX - spacing)
            totalHeight = currentY + lineHeight
        }

        return (CGSize(width: totalWidth, height: totalHeight), positions)
    }
}

// MARK: - Mock Data

extension SymphonyAgentManagementView {
    static var mockViewModel: SymphonyAgentManagementViewModel {
        SymphonyAgentManagementViewModel(agents: [
            SymphonyAgentViewModel(
                id: "agent-1", name: "Codex Alpha", type: "Code Agent",
                statusKey: "running", statusLabel: "Running",
                capabilities: ["refactor", "implement", "test", "debug"],
                currentTaskIdentifier: "KAN-142",
                currentTaskTitle: "Rebuild Symphony dashboard pipeline",
                completedCount: 12, tokenUsage: "45K",
                lastActiveTime: "Active now"
            ),
            SymphonyAgentViewModel(
                id: "agent-2", name: "Codex Beta", type: "Code Agent",
                statusKey: "running", statusLabel: "Running",
                capabilities: ["implement", "test", "lint"],
                currentTaskIdentifier: "KAN-177",
                currentTaskTitle: "Wire issue detail renderer",
                completedCount: 8, tokenUsage: "32K",
                lastActiveTime: "Active now"
            ),
            SymphonyAgentViewModel(
                id: "agent-3", name: "Review Bot", type: "Review Agent",
                statusKey: "idle", statusLabel: "Idle",
                capabilities: ["review", "analyze", "comment"],
                currentTaskIdentifier: nil,
                currentTaskTitle: nil,
                completedCount: 24, tokenUsage: "61K",
                lastActiveTime: "5 min ago"
            ),
            SymphonyAgentViewModel(
                id: "agent-4", name: "QA Runner", type: "QA Agent",
                statusKey: "idle", statusLabel: "Idle",
                capabilities: ["test", "snapshot", "accessibility"],
                currentTaskIdentifier: nil,
                currentTaskTitle: nil,
                completedCount: 18, tokenUsage: "28K",
                lastActiveTime: "12 min ago"
            ),
            SymphonyAgentViewModel(
                id: "agent-5", name: "Planner One", type: "Planner Agent",
                statusKey: "error", statusLabel: "Error",
                capabilities: ["plan", "estimate", "decompose"],
                currentTaskIdentifier: nil,
                currentTaskTitle: nil,
                completedCount: 6, tokenUsage: "15K",
                lastActiveTime: "1 hr ago"
            )
        ])
    }
}

#Preview {
    SymphonyAgentManagementView()
        .frame(width: 900, height: 800)
        .background(SymphonyDesignStyle.Background.primary)
}
