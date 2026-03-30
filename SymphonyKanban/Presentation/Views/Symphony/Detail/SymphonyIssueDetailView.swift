import SwiftUI

// MARK: - SymphonyIssueDetailView
/// Mission control inspector panel for a single issue.
/// Shows header, progressive-disclosure sections, and embedded sub-views.

public struct SymphonyIssueDetailView: View {
    private let viewModel: SymphonyIssueDetailViewModel

    // Section expansion states
    @State private var overviewExpanded = true
    @State private var agentControlExpanded = true
    @State private var runtimeExpanded = false
    @State private var workspaceExpanded = false
    @State private var activityExpanded = true
    @State private var logsExpanded = false
    @State private var errorExpanded = true
    @State private var trackedFieldsExpanded = false

    public init(viewModel: SymphonyIssueDetailViewModel) {
        self.viewModel = viewModel
    }

    public var body: some View {
        if viewModel.isEmptyState {
            emptyState
        } else {
            ScrollView(.vertical, showsIndicators: true) {
                VStack(alignment: .leading, spacing: SymphonyDesignStyle.Spacing.lg) {
                    header

                    overviewSection

                    agentControlSection

                    if viewModel.runtimeViewModel != nil {
                        runtimeSection
                    }

                    if viewModel.workspaceViewModel != nil {
                        workspaceSection
                    }

                    activityLogSection

                    logsSection

                    if viewModel.lastErrorTitle != nil {
                        errorSection
                    }

                    trackedFieldsSection
                }
                .padding(SymphonyDesignStyle.Spacing.xl)
            }
            .background(SymphonyDesignStyle.Background.secondary)
        }
    }

    // MARK: - Header

    private var header: some View {
        VStack(alignment: .leading, spacing: SymphonyDesignStyle.Spacing.sm) {
            // Issue identifier
            if !viewModel.issueIdentifier.isEmpty {
                Text(viewModel.issueIdentifier)
                    .font(SymphonyDesignStyle.Typography.micro)
                    .foregroundStyle(SymphonyDesignStyle.Text.tertiary)
                    .tracking(1.0)
                    .textCase(.uppercase)
            }

            // Title row
            HStack(alignment: .top, spacing: SymphonyDesignStyle.Spacing.md) {
                Text(viewModel.title)
                    .font(SymphonyDesignStyle.Typography.title)
                    .foregroundStyle(SymphonyDesignStyle.Text.primary)
                    .lineLimit(3)

                Spacer(minLength: SymphonyDesignStyle.Spacing.sm)

                VStack(alignment: .trailing, spacing: SymphonyDesignStyle.Spacing.xs) {
                    SymphonyStatusBadgeView(
                        viewModel.stateLabel,
                        statusKey: viewModel.stateKey
                    )

                    if let priorityLabel = viewModel.priorityLabel {
                        priorityIndicator(priorityLabel)
                    }
                }
            }

            // Subtitle / timestamps
            HStack(spacing: SymphonyDesignStyle.Spacing.md) {
                Text(viewModel.attemptsLabel)
                    .font(SymphonyDesignStyle.Typography.micro)
                    .foregroundStyle(SymphonyDesignStyle.Text.tertiary)

                Text("·")
                    .foregroundStyle(SymphonyDesignStyle.Text.tertiary)

                Text(viewModel.generatedAtLabel)
                    .font(SymphonyDesignStyle.Typography.micro)
                    .foregroundStyle(SymphonyDesignStyle.Text.tertiary)
            }
        }
    }

    private func priorityIndicator(_ label: String) -> some View {
        HStack(spacing: SymphonyDesignStyle.Spacing.xs) {
            SymphonyPriorityDotView(level: priorityLevel(from: label), showLabel: true)
        }
    }

    private func priorityLevel(from label: String) -> Int {
        let lowered = label.lowercased()
        if lowered.contains("urgent") { return 1 }
        if lowered.contains("high") { return 2 }
        if lowered.contains("medium") { return 3 }
        if lowered.contains("low") { return 4 }
        return 0
    }

    // MARK: - Overview Section

    private var overviewSection: some View {
        CollapsibleSectionView(
            title: "Overview",
            icon: "doc.text.magnifyingglass",
            isExpanded: $overviewExpanded
        ) {
            VStack(alignment: .leading, spacing: SymphonyDesignStyle.Spacing.md) {
                // Description
                if let descriptionText = viewModel.descriptionText {
                    Text(descriptionText)
                        .font(SymphonyDesignStyle.Typography.body)
                        .foregroundStyle(SymphonyDesignStyle.Text.secondary)
                        .lineSpacing(3)
                }

                // Labels
                if !viewModel.labels.isEmpty {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: SymphonyDesignStyle.Spacing.xs) {
                            ForEach(viewModel.labels, id: \.self) { label in
                                SymphonyLabelChipView(label)
                            }
                        }
                    }
                }

                // Metadata lines
                if !viewModel.metadataLines.isEmpty {
                    SymphonyDividerView()
                    VStack(alignment: .leading, spacing: SymphonyDesignStyle.Spacing.xs) {
                        ForEach(viewModel.metadataLines, id: \.self) { line in
                            metadataRow(line)
                        }
                    }
                }
            }
        }
    }

    private func metadataRow(_ text: String) -> some View {
        HStack(spacing: SymphonyDesignStyle.Spacing.sm) {
            Circle()
                .fill(SymphonyDesignStyle.Text.tertiary)
                .frame(width: 4, height: 4)

            Text(text)
                .font(SymphonyDesignStyle.Typography.caption)
                .foregroundStyle(SymphonyDesignStyle.Text.secondary)
        }
    }

    // MARK: - Agent Control Panel

    private var agentControlSection: some View {
        CollapsibleSectionView(
            title: "Agent Control",
            icon: "cpu",
            isExpanded: $agentControlExpanded,
            accentColor: SymphonyDesignStyle.Accent.teal
        ) {
            VStack(alignment: .leading, spacing: SymphonyDesignStyle.Spacing.md) {
                // Status row
                HStack(spacing: SymphonyDesignStyle.Spacing.md) {
                    if viewModel.runtimeStatusLabel.lowercased() == "running"
                        || viewModel.runtimeStatusLabel.lowercased() == "in_progress" {
                        SymphonyPulsingDotView(color: SymphonyDesignStyle.Accent.teal)
                    }

                    Text("Status: \(viewModel.runtimeStatusLabel)")
                        .font(SymphonyDesignStyle.Typography.headline)
                        .foregroundStyle(SymphonyDesignStyle.Text.primary)

                    Spacer()
                }

                // Agent assignment
                Text(viewModel.subtitle)
                    .font(SymphonyDesignStyle.Typography.caption)
                    .foregroundStyle(SymphonyDesignStyle.Text.tertiary)

                SymphonyDividerView()

                // Action buttons
                HStack(spacing: SymphonyDesignStyle.Spacing.md) {
                    agentActionButton(
                        label: "Run Agent",
                        icon: "play.fill",
                        color: SymphonyDesignStyle.Accent.green
                    )

                    agentActionButton(
                        label: "Stop Agent",
                        icon: "stop.fill",
                        color: SymphonyDesignStyle.Accent.coral
                    )

                    Spacer()
                }
            }
        }
    }

    private func agentActionButton(label: String, icon: String, color: Color) -> some View {
        Button {
            // Stub action
        } label: {
            HStack(spacing: SymphonyDesignStyle.Spacing.xs) {
                Image(systemName: icon)
                    .font(.system(size: 10, weight: .bold))

                Text(label)
                    .font(SymphonyDesignStyle.Typography.caption)
                    .fontWeight(.semibold)
            }
            .foregroundStyle(color)
            .padding(.horizontal, SymphonyDesignStyle.Spacing.md)
            .padding(.vertical, SymphonyDesignStyle.Spacing.sm)
            .background(
                RoundedRectangle(cornerRadius: SymphonyDesignStyle.Radius.sm, style: .continuous)
                    .fill(color.opacity(0.10))
            )
            .overlay(
                RoundedRectangle(cornerRadius: SymphonyDesignStyle.Radius.sm, style: .continuous)
                    .strokeBorder(color.opacity(0.25), lineWidth: 0.5)
            )
        }
        .buttonStyle(.plain)
    }

    // MARK: - Runtime Section

    private var runtimeSection: some View {
        CollapsibleSectionView(
            title: "Runtime",
            icon: "gauge.with.dots.needle.33percent",
            isExpanded: $runtimeExpanded,
            accentColor: SymphonyDesignStyle.Accent.blue
        ) {
            if let runtimeVM = viewModel.runtimeViewModel {
                SymphonyIssueRuntimeView(viewModel: runtimeVM)
            }
        }
    }

    // MARK: - Workspace Section

    private var workspaceSection: some View {
        CollapsibleSectionView(
            title: "Workspace",
            icon: "folder.badge.gearshape",
            isExpanded: $workspaceExpanded,
            accentColor: SymphonyDesignStyle.Accent.green
        ) {
            if let workspaceVM = viewModel.workspaceViewModel {
                SymphonyWorkspaceView(viewModel: workspaceVM)
            }
        }
    }

    // MARK: - Activity Log Section

    private var activityLogSection: some View {
        CollapsibleSectionView(
            title: viewModel.recentEventsSectionTitle,
            icon: "clock.arrow.circlepath",
            isExpanded: $activityExpanded,
            accentColor: SymphonyDesignStyle.Accent.lavender
        ) {
            SymphonyRecentEventsView(
                title: viewModel.recentEventsSectionTitle,
                emptyState: viewModel.recentEventsEmptyState,
                rows: viewModel.recentEventRows
            )
        }
    }

    // MARK: - Logs Section

    private var logsSection: some View {
        CollapsibleSectionView(
            title: "Logs",
            icon: "doc.text",
            isExpanded: $logsExpanded,
            accentColor: SymphonyDesignStyle.Accent.amber
        ) {
            SymphonyLogsView(viewModel: viewModel.logsViewModel)
        }
    }

    // MARK: - Error Section

    private var errorSection: some View {
        Group {
            if let errorTitle = viewModel.lastErrorTitle,
               let errorMessage = viewModel.lastErrorMessage {
                CollapsibleSectionView(
                    title: errorTitle,
                    icon: "exclamationmark.triangle.fill",
                    isExpanded: $errorExpanded,
                    accentColor: SymphonyDesignStyle.Accent.coral
                ) {
                    VStack(alignment: .leading, spacing: SymphonyDesignStyle.Spacing.sm) {
                        Text(errorMessage)
                            .font(SymphonyDesignStyle.Typography.body)
                            .foregroundStyle(SymphonyDesignStyle.Accent.coral)
                            .lineSpacing(2)

                        if !viewModel.lastErrorDetailLines.isEmpty {
                            SymphonyDividerView(opacity: 0.08)
                            ForEach(viewModel.lastErrorDetailLines, id: \.self) { line in
                                Text(line)
                                    .font(SymphonyDesignStyle.Typography.code)
                                    .foregroundStyle(SymphonyDesignStyle.Text.secondary)
                            }
                        }
                    }
                    .padding(SymphonyDesignStyle.Spacing.md)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(
                        RoundedRectangle(cornerRadius: SymphonyDesignStyle.Radius.md, style: .continuous)
                            .fill(SymphonyDesignStyle.Accent.coral.opacity(0.06))
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: SymphonyDesignStyle.Radius.md, style: .continuous)
                            .strokeBorder(SymphonyDesignStyle.Accent.coral.opacity(0.15), lineWidth: 0.5)
                    )
                }
            }
        }
    }

    // MARK: - Tracked Fields Section

    private var trackedFieldsSection: some View {
        CollapsibleSectionView(
            title: viewModel.trackedSectionTitle,
            icon: "list.bullet.rectangle",
            isExpanded: $trackedFieldsExpanded
        ) {
            VStack(alignment: .leading, spacing: SymphonyDesignStyle.Spacing.sm) {
                if viewModel.trackedFieldLines.isEmpty {
                    HStack(spacing: SymphonyDesignStyle.Spacing.sm) {
                        Image(systemName: "tray")
                            .font(.system(size: 11))
                            .foregroundStyle(SymphonyDesignStyle.Text.tertiary)
                        Text("No tracked fields are available.")
                            .font(SymphonyDesignStyle.Typography.caption)
                            .foregroundStyle(SymphonyDesignStyle.Text.tertiary)
                    }
                } else {
                    ForEach(viewModel.trackedFieldLines, id: \.self) { line in
                        trackedFieldRow(line)
                    }
                }
            }
        }
    }

    private func trackedFieldRow(_ line: String) -> some View {
        let parts = line.split(separator: ":", maxSplits: 1)
        let key = parts.first.map(String.init) ?? line
        let value = parts.count > 1 ? String(parts[1]).trimmingCharacters(in: .whitespaces) : ""

        return HStack(spacing: SymphonyDesignStyle.Spacing.sm) {
            Text(key)
                .font(SymphonyDesignStyle.Typography.code)
                .foregroundStyle(SymphonyDesignStyle.Text.tertiary)

            if !value.isEmpty {
                Text(value)
                    .font(SymphonyDesignStyle.Typography.code)
                    .foregroundStyle(SymphonyDesignStyle.Accent.blue.opacity(0.8))
            }
        }
        .padding(.vertical, SymphonyDesignStyle.Spacing.xxs)
    }

    // MARK: - Empty State

    private var emptyState: some View {
        VStack {
            Spacer()
            SymphonyEmptyStateView(
                icon: "square.stack.3d.up",
                title: viewModel.emptyStateTitle ?? "Issue Detail",
                message: viewModel.emptyStateMessage ?? "Select an issue to view its mission control panel."
            )
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(SymphonyDesignStyle.Background.secondary)
    }
}

// MARK: - CollapsibleSectionView

/// Reusable collapsible section container with animated expand/collapse.
private struct CollapsibleSectionView<Content: View>: View {
    let title: String
    let icon: String
    @Binding var isExpanded: Bool
    let accentColor: Color
    @ViewBuilder let content: () -> Content

    init(
        title: String,
        icon: String,
        isExpanded: Binding<Bool>,
        accentColor: Color = SymphonyDesignStyle.Text.secondary,
        @ViewBuilder content: @escaping () -> Content
    ) {
        self.title = title
        self.icon = icon
        self._isExpanded = isExpanded
        self.accentColor = accentColor
        self.content = content
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Section header button
            Button {
                withAnimation(SymphonyDesignStyle.Motion.snappy) {
                    isExpanded.toggle()
                }
            } label: {
                HStack(spacing: SymphonyDesignStyle.Spacing.sm) {
                    Image(systemName: icon)
                        .font(.system(size: 12, weight: .medium))
                        .foregroundStyle(accentColor)
                        .frame(width: 18, alignment: .center)

                    Text(title)
                        .font(SymphonyDesignStyle.Typography.caption)
                        .fontWeight(.semibold)
                        .foregroundStyle(SymphonyDesignStyle.Text.secondary)
                        .textCase(.uppercase)
                        .tracking(0.6)

                    Spacer()

                    Image(systemName: "chevron.right")
                        .font(.system(size: 10, weight: .semibold))
                        .foregroundStyle(SymphonyDesignStyle.Text.tertiary)
                        .rotationEffect(.degrees(isExpanded ? 90 : 0))
                }
                .padding(.horizontal, SymphonyDesignStyle.Spacing.md)
                .padding(.vertical, SymphonyDesignStyle.Spacing.md)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)

            // Collapsible content
            if isExpanded {
                VStack(alignment: .leading, spacing: 0) {
                    SymphonyDividerView()
                        .padding(.horizontal, SymphonyDesignStyle.Spacing.md)

                    content()
                        .padding(.horizontal, SymphonyDesignStyle.Spacing.xs)
                        .padding(.top, SymphonyDesignStyle.Spacing.md)
                        .padding(.bottom, SymphonyDesignStyle.Spacing.md)
                }
                .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
        .background(
            RoundedRectangle(cornerRadius: SymphonyDesignStyle.Radius.md, style: .continuous)
                .fill(SymphonyDesignStyle.Background.tertiary)
        )
        .overlay(
            RoundedRectangle(cornerRadius: SymphonyDesignStyle.Radius.md, style: .continuous)
                .strokeBorder(
                    isExpanded ? accentColor.opacity(0.12) : SymphonyDesignStyle.Border.subtle,
                    lineWidth: 0.5
                )
        )
        .clipShape(RoundedRectangle(cornerRadius: SymphonyDesignStyle.Radius.md, style: .continuous))
    }
}

// MARK: - Previews

#Preview("Issue Detail — Mission Control") {
    SymphonyIssueDetailView(
        viewModel: SymphonyPreviewDI.makeIssueDetailViewModel(.missionControl)
    )
    .frame(width: 380, height: 900)
    .background(SymphonyDesignStyle.Background.secondary)
}

#Preview("Empty Detail") {
    SymphonyIssueDetailView(
        viewModel: SymphonyPreviewDI.makeIssueDetailViewModel(.empty)
    )
    .frame(width: 380, height: 600)
    .background(SymphonyDesignStyle.Background.secondary)
}
