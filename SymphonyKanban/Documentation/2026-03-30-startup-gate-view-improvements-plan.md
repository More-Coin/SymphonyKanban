# Startup Gate & View Improvements Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Split oversized view files, align views with the design system, add a root startup gate with loading/setup/ready/failed states, and build the workspace binding setup flow.

**Architecture:** Extract sub-views from board/list files into focused single-responsibility files. Align styling with SymphonyDesignStyle tokens and modifiers. Add a startup gate view above the navigation routes that branches on SymphonyStartupStatusViewModel state. Build a multi-step setup wizard for workspace binding creation.

**Tech Stack:** SwiftUI, macOS, Clean Architecture (Controller → Presenter → ViewModel → View)

---

### Task 1: Extract SymphonyKanbanBoardSectionView

**Files:**
- Create: `SymphonyKanban/Presentation/Views/Symphony/Board/SymphonyKanbanBoardSectionView.swift`
- Modify: `SymphonyKanban/Presentation/Views/Symphony/Board/SymphonyKanbanBoardView.swift:64-142`

**Step 1: Create SymphonyKanbanBoardSectionView.swift**

```swift
import SwiftUI

// MARK: - SymphonyKanbanBoardSectionView
/// Renders a single grouped section of the Kanban board, including an
/// optional title/subtitle header, error banner, and the horizontal
/// columns scroll view for that section's issues.

public struct SymphonyKanbanBoardSectionView: View {
    let section: SymphonyKanbanBoardSectionViewModel
    let sectionIndex: Int
    let dropTargetColumnID: String?
    let appeared: Bool
    let onCardSelected: (String) -> Void
    let onDropTargetChanged: (String?) -> Void

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

public struct SymphonyKanbanSectionErrorView: View {
    let message: String

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
```

**Step 2: Update SymphonyKanbanBoardView to use the extracted views**

Remove `boardSection()` and `sectionErrorView()` methods (lines 64-142). Replace inline calls with the new views. The board view body should now reference `SymphonyKanbanBoardSectionView` and `SymphonyKanbanColumnsScrollView` (created in Task 2).

After this and Task 2, the board view body becomes:

```swift
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
                            onDropTargetChanged: { newTarget in
                                dropTargetColumnID = newTarget
                            }
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
                onDropTargetChanged: { newTarget in
                    dropTargetColumnID = newTarget
                }
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
```

**Step 3: Verify previews render**

Build the project and confirm the Kanban Board preview renders.

**Step 4: Commit**

```
feat: extract board section and error views into dedicated files
```

---

### Task 2: Extract SymphonyKanbanColumnsScrollView

**Files:**
- Create: `SymphonyKanban/Presentation/Views/Symphony/Board/SymphonyKanbanColumnsScrollView.swift`
- Modify: `SymphonyKanban/Presentation/Views/Symphony/Board/SymphonyKanbanBoardView.swift:96-121`

**Step 1: Create SymphonyKanbanColumnsScrollView.swift**

```swift
import SwiftUI

// MARK: - SymphonyKanbanColumnsScrollView
/// Horizontal scroll view containing Kanban columns with staggered
/// entrance animations and drop-target support.

public struct SymphonyKanbanColumnsScrollView: View {
    let columns: [SymphonyKanbanColumnViewModel]
    let animationOffset: Int
    let dropTargetColumnID: String?
    let appeared: Bool
    let onCardSelected: (String) -> Void
    let onDropTargetChanged: (String?) -> Void

    public init(
        columns: [SymphonyKanbanColumnViewModel],
        animationOffset: Int = 0,
        dropTargetColumnID: String? = nil,
        appeared: Bool = true,
        onCardSelected: @escaping (String) -> Void = { _ in },
        onDropTargetChanged: @escaping (String?) -> Void = { _ in }
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

#Preview("Columns Scroll") {
    SymphonyKanbanColumnsScrollView(
        columns: SymphonyKanbanBoardView.mockBoardViewModel.columns,
        onCardSelected: { _ in }
    )
    .frame(minWidth: 1200, minHeight: 400)
    .background(SymphonyDesignStyle.Background.secondary)
}
```

**Step 2: Remove `columnsScrollView()` from SymphonyKanbanBoardView**

Remove the private method at lines 96-121 — it is now replaced by `SymphonyKanbanColumnsScrollView`.

**Step 3: Build and verify previews**

**Step 4: Commit**

```
feat: extract columns scroll view into dedicated file
```

---

### Task 3: Extract SymphonyKanbanCardTopRowView and SymphonyKanbanCardBottomRowView

**Files:**
- Create: `SymphonyKanban/Presentation/Views/Symphony/Board/SymphonyKanbanCardTopRowView.swift`
- Create: `SymphonyKanban/Presentation/Views/Symphony/Board/SymphonyKanbanCardBottomRowView.swift`
- Modify: `SymphonyKanban/Presentation/Views/Symphony/Board/SymphonyKanbanCardView.swift:49-134`

**Step 1: Create SymphonyKanbanCardTopRowView.swift**

```swift
import SwiftUI

// MARK: - SymphonyKanbanCardTopRowView
/// Top row of a Kanban card: priority dot, identifier, running indicator,
/// and status badge.

public struct SymphonyKanbanCardTopRowView: View {
    let identifier: String
    let priorityLevel: Int
    let statusKey: String
    let statusLabel: String
    let isRunning: Bool

    public init(
        identifier: String,
        priorityLevel: Int,
        statusKey: String,
        statusLabel: String,
        isRunning: Bool
    ) {
        self.identifier = identifier
        self.priorityLevel = priorityLevel
        self.statusKey = statusKey
        self.statusLabel = statusLabel
        self.isRunning = isRunning
    }

    public var body: some View {
        HStack(spacing: SymphonyDesignStyle.Spacing.sm) {
            SymphonyPriorityDotView(level: priorityLevel)

            Text(identifier)
                .font(SymphonyDesignStyle.Typography.micro)
                .foregroundStyle(SymphonyDesignStyle.Text.secondary)

            if isRunning {
                SymphonyPulsingDotView(color: SymphonyDesignStyle.Status.color(for: statusKey))
            }

            Spacer()

            SymphonyStatusBadgeView(
                statusLabel,
                statusKey: statusKey,
                size: .small
            )
        }
    }
}
```

Note: `statusLabel` is now a parameter passed from the view model instead of computed in the view. The card view model already carries `statusKey`; the presenter already computes `statusLabel` for list rows. We will add `statusLabel` to `SymphonyKanbanCardViewModel` in the design alignment task (Task 7).

**Step 2: Create SymphonyKanbanCardBottomRowView.swift**

```swift
import SwiftUI

// MARK: - SymphonyKanbanCardBottomRowView
/// Bottom row of a Kanban card: agent avatar, label chips, token count,
/// and last event indicator.

public struct SymphonyKanbanCardBottomRowView: View {
    let agentName: String?
    let labels: [String]
    let tokenCount: String?
    let lastEvent: String?

    public init(
        agentName: String? = nil,
        labels: [String] = [],
        tokenCount: String? = nil,
        lastEvent: String? = nil
    ) {
        self.agentName = agentName
        self.labels = labels
        self.tokenCount = tokenCount
        self.lastEvent = lastEvent
    }

    public var body: some View {
        HStack(spacing: SymphonyDesignStyle.Spacing.sm) {
            if let agentName {
                SymphonyAgentAvatarView(name: agentName, size: 20)
            }

            if !labels.isEmpty {
                labelChips
            }

            Spacer()

            if let tokenCount {
                HStack(spacing: SymphonyDesignStyle.Spacing.xxs) {
                    Image(systemName: "number.circle")
                        .font(.system(size: 9, weight: .medium))
                    Text(tokenCount)
                        .font(SymphonyDesignStyle.Typography.micro)
                }
                .foregroundStyle(SymphonyDesignStyle.Text.tertiary)
            }

            if let lastEvent {
                HStack(spacing: SymphonyDesignStyle.Spacing.xxs) {
                    Circle()
                        .fill(SymphonyDesignStyle.Text.tertiary)
                        .frame(width: 3, height: 3)
                    Text(lastEvent)
                        .font(SymphonyDesignStyle.Typography.micro)
                }
                .foregroundStyle(SymphonyDesignStyle.Text.tertiary)
            }
        }
    }

    private var labelChips: some View {
        HStack(spacing: SymphonyDesignStyle.Spacing.xs) {
            ForEach(labels.prefix(3), id: \.self) { label in
                SymphonyLabelChipView(label)
            }
        }
    }
}
```

Note: `chipColor(for:)` is removed — labels now use the default `SymphonyLabelChipView` color. Label coloring will be handled by the presenter in Task 7.

**Step 3: Update SymphonyKanbanCardView**

Replace `topRow`, `bottomRow`, `labelChips`, `statusLabel(for:)`, and `chipColor(for:)` with the new extracted views. The card view body becomes:

```swift
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
    .scaleEffect(isHovered ? 1.015 : 1.0)
    .shadow(
        color: .black.opacity(isHovered ? 0.35 : 0),
        radius: isHovered ? 12 : 0,
        x: 0,
        y: isHovered ? 6 : 0
    )
    .onHover { hovering in
        withAnimation(SymphonyDesignStyle.Motion.stiffSnap) {
            isHovered = hovering
        }
    }
}
```

The `titleRow` computed property stays in the card view since it's lightweight.

**Step 4: Build and verify previews**

**Step 5: Commit**

```
feat: extract card top row and bottom row into dedicated files
```

---

### Task 4: Extract SymphonyIssueListFilterBarView

**Files:**
- Create: `SymphonyKanban/Presentation/Views/Symphony/Issues/SymphonyIssueListFilterBarView.swift`
- Modify: `SymphonyKanban/Presentation/Views/Symphony/Issues/SymphonyIssueListView.swift:74-96`

**Step 1: Create SymphonyIssueListFilterBarView.swift**

```swift
import SwiftUI

// MARK: - SymphonyIssueListFilterBarView
/// Filter bar with search field, status picker, and issue count.

public struct SymphonyIssueListFilterBarView: View {
    @Binding var searchText: String
    @Binding var statusFilter: String
    let statusKeys: [String]
    let issueCount: Int

    public init(
        searchText: Binding<String>,
        statusFilter: Binding<String>,
        statusKeys: [String],
        issueCount: Int
    ) {
        self._searchText = searchText
        self._statusFilter = statusFilter
        self.statusKeys = statusKeys
        self.issueCount = issueCount
    }

    public var body: some View {
        HStack(spacing: SymphonyDesignStyle.Spacing.md) {
            SymphonySearchFieldView(placeholder: "Filter issues...", text: $searchText)
                .frame(maxWidth: 260)

            Picker("Status", selection: $statusFilter) {
                ForEach(statusKeys, id: \.self) { key in
                    Text(key).tag(key)
                }
            }
            .pickerStyle(.menu)
            .frame(width: 140)

            Spacer()

            Text("\(issueCount) issues")
                .font(SymphonyDesignStyle.Typography.caption)
                .foregroundStyle(SymphonyDesignStyle.Text.tertiary)
        }
        .padding(.horizontal, SymphonyDesignStyle.Spacing.lg)
        .padding(.vertical, SymphonyDesignStyle.Spacing.sm)
        .background(SymphonyDesignStyle.Background.tertiary)
    }
}
```

**Step 2: Update SymphonyIssueListView to use the extracted view**

Replace `filterBar` computed property with:

```swift
SymphonyIssueListFilterBarView(
    searchText: $searchText,
    statusFilter: $statusFilter,
    statusKeys: statusKeys,
    issueCount: filteredRowsCount
)
```

**Step 3: Build and verify previews**

**Step 4: Commit**

```
feat: extract issue list filter bar into dedicated file
```

---

### Task 5: Extract SymphonyIssueListHeaderRowView

**Files:**
- Create: `SymphonyKanban/Presentation/Views/Symphony/Issues/SymphonyIssueListHeaderRowView.swift`
- Modify: `SymphonyKanban/Presentation/Views/Symphony/Issues/SymphonyIssueListView.swift:100-154`

**Step 1: Create SymphonyIssueListHeaderRowView.swift**

Move `SortColumn` enum, `headerRow`, `columnHeader()`, and `labelsHeader()` into this file. `SortColumn` becomes a public type since it's shared between the header and the parent view.

```swift
import SwiftUI

// MARK: - SymphonyIssueListSortColumn

public enum SymphonyIssueListSortColumn: String, CaseIterable {
    case priority = "Priority"
    case identifier = "ID"
    case title = "Title"
    case scope = "Scope"
    case status = "Status"
    case agent = "Agent"
    case labels = "Labels"
    case lastEvent = "Last Event"
    case tokens = "Tokens"
}

// MARK: - SymphonyIssueListHeaderRowView
/// Sortable column header row for the issue list table.

public struct SymphonyIssueListHeaderRowView: View {
    @Binding var sortColumn: SymphonyIssueListSortColumn
    @Binding var sortAscending: Bool

    public init(
        sortColumn: Binding<SymphonyIssueListSortColumn>,
        sortAscending: Binding<Bool>
    ) {
        self._sortColumn = sortColumn
        self._sortAscending = sortAscending
    }

    public var body: some View {
        HStack(spacing: 0) {
            columnHeader(.priority, width: 60)
            columnHeader(.identifier, width: 90)
            columnHeader(.title, minWidth: 160)
            columnHeader(.scope, width: 110)
            columnHeader(.status, width: 100)
            columnHeader(.agent, width: 110)
            nonSortableHeader("Labels", width: 140)
            columnHeader(.lastEvent, width: 150)
            columnHeader(.tokens, width: 90)
        }
        .padding(.horizontal, SymphonyDesignStyle.Spacing.lg)
        .padding(.vertical, SymphonyDesignStyle.Spacing.sm)
        .background(SymphonyDesignStyle.Background.primary.opacity(0.5))
    }

    private func columnHeader(
        _ column: SymphonyIssueListSortColumn,
        width: CGFloat? = nil,
        minWidth: CGFloat? = nil
    ) -> some View {
        Button {
            if sortColumn == column {
                sortAscending.toggle()
            } else {
                sortColumn = column
                sortAscending = true
            }
        } label: {
            HStack(spacing: SymphonyDesignStyle.Spacing.xs) {
                Text(column.rawValue)
                    .font(SymphonyDesignStyle.Typography.micro)
                    .fontWeight(.semibold)
                    .foregroundStyle(SymphonyDesignStyle.Text.tertiary)
                    .textCase(.uppercase)
                    .tracking(0.6)

                if sortColumn == column {
                    Image(systemName: sortAscending ? "chevron.up" : "chevron.down")
                        .font(.system(size: 8, weight: .bold))
                        .foregroundStyle(SymphonyDesignStyle.Accent.blue)
                }
            }
            .frame(maxWidth: minWidth != nil ? .infinity : nil, alignment: .leading)
        }
        .buttonStyle(.plain)
        .frame(width: width)
        .frame(minWidth: minWidth)
    }

    private func nonSortableHeader(_ title: String, width: CGFloat) -> some View {
        Text(title)
            .font(SymphonyDesignStyle.Typography.micro)
            .fontWeight(.semibold)
            .foregroundStyle(SymphonyDesignStyle.Text.tertiary)
            .textCase(.uppercase)
            .tracking(0.6)
            .frame(width: width, alignment: .leading)
    }
}
```

Note: Added `.scope` column and renamed `labelsHeader` to `nonSortableHeader` (labels are not sortable).

**Step 2: Update SymphonyIssueListView**

- Remove private `SortColumn` enum
- Change `@State private var sortColumn: SortColumn` to `@State private var sortColumn: SymphonyIssueListSortColumn`
- Replace `headerRow` with `SymphonyIssueListHeaderRowView(sortColumn: $sortColumn, sortAscending: $sortAscending)`
- Update `rowComparator` to use `SymphonyIssueListSortColumn` and add `.scope` case

**Step 3: Build and verify previews**

**Step 4: Commit**

```
feat: extract issue list header row with scope column
```

---

### Task 6: Extract SymphonyIssueListRowView and SymphonyIssueListSectionHeaderView

**Files:**
- Create: `SymphonyKanban/Presentation/Views/Symphony/Issues/SymphonyIssueListRowView.swift`
- Create: `SymphonyKanban/Presentation/Views/Symphony/Issues/SymphonyIssueListSectionHeaderView.swift`
- Modify: `SymphonyKanban/Presentation/Views/Symphony/Issues/SymphonyIssueListView.swift:204-371`

**Step 1: Create SymphonyIssueListRowView.swift**

```swift
import SwiftUI

// MARK: - SymphonyIssueListRowView
/// Single data row in the issue list table, showing all columns for one issue.

public struct SymphonyIssueListRowView: View {
    let row: SymphonyIssueListRowViewModel
    let index: Int
    let isHovered: Bool
    let onSelected: () -> Void
    let onHover: (Bool) -> Void

    public init(
        row: SymphonyIssueListRowViewModel,
        index: Int,
        isHovered: Bool,
        onSelected: @escaping () -> Void,
        onHover: @escaping (Bool) -> Void
    ) {
        self.row = row
        self.index = index
        self.isHovered = isHovered
        self.onSelected = onSelected
        self.onHover = onHover
    }

    public var body: some View {
        Button(action: onSelected) {
            HStack(spacing: 0) {
                SymphonyPriorityDotView(level: row.priorityLevel)
                    .frame(width: 60, alignment: .leading)

                Text(row.identifier)
                    .font(SymphonyDesignStyle.Typography.callout)
                    .fontWeight(.semibold)
                    .foregroundStyle(SymphonyDesignStyle.Accent.blue)
                    .frame(width: 90, alignment: .leading)

                titleCell
                    .frame(maxWidth: .infinity, alignment: .leading)

                scopeCell
                    .frame(width: 110, alignment: .leading)

                SymphonyStatusBadgeView(row.statusLabel, statusKey: row.statusKey, size: .small)
                    .frame(width: 100, alignment: .leading)

                agentCell
                    .frame(width: 110, alignment: .leading)

                labelsCell
                    .frame(width: 140, alignment: .leading)

                lastEventCell
                    .frame(width: 150, alignment: .leading)

                Text(row.tokenCount ?? "-")
                    .font(SymphonyDesignStyle.Typography.micro)
                    .foregroundStyle(SymphonyDesignStyle.Text.secondary)
                    .frame(width: 90, alignment: .trailing)
            }
            .padding(.horizontal, SymphonyDesignStyle.Spacing.lg)
            .padding(.vertical, SymphonyDesignStyle.Spacing.sm)
            .background(rowBackground)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .onHover { hovering in
            onHover(hovering)
        }
    }

    private var titleCell: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(row.title)
                .font(SymphonyDesignStyle.Typography.body)
                .foregroundStyle(SymphonyDesignStyle.Text.primary)
                .lineLimit(1)
        }
    }

    private var scopeCell: some View {
        Group {
            if let scopeName = row.scopeName, scopeName.isEmpty == false {
                SymphonyLabelChipView(scopeName, color: SymphonyDesignStyle.Accent.indigo)
            } else {
                Text("-")
                    .font(SymphonyDesignStyle.Typography.micro)
                    .foregroundStyle(SymphonyDesignStyle.Text.tertiary)
            }
        }
    }

    private var agentCell: some View {
        Group {
            if let name = row.agentName {
                HStack(spacing: SymphonyDesignStyle.Spacing.xs) {
                    SymphonyAgentAvatarView(name: name, size: 18)
                    Text(name)
                        .font(SymphonyDesignStyle.Typography.micro)
                        .foregroundStyle(SymphonyDesignStyle.Text.secondary)
                        .lineLimit(1)
                }
            } else {
                Text("-")
                    .font(SymphonyDesignStyle.Typography.micro)
                    .foregroundStyle(SymphonyDesignStyle.Text.tertiary)
            }
        }
    }

    private var labelsCell: some View {
        HStack(spacing: SymphonyDesignStyle.Spacing.xxs) {
            ForEach(row.labels.prefix(2), id: \.self) { label in
                SymphonyLabelChipView(label)
            }
            if row.labels.count > 2 {
                Text("+\(row.labels.count - 2)")
                    .font(SymphonyDesignStyle.Typography.micro)
                    .foregroundStyle(SymphonyDesignStyle.Text.tertiary)
            }
        }
    }

    private var lastEventCell: some View {
        VStack(alignment: .leading, spacing: 1) {
            if let event = row.lastEvent {
                Text(event)
                    .font(SymphonyDesignStyle.Typography.micro)
                    .foregroundStyle(SymphonyDesignStyle.Text.secondary)
                    .lineLimit(1)
            }
            if let time = row.lastEventTime {
                Text(time)
                    .font(SymphonyDesignStyle.Typography.micro)
                    .foregroundStyle(SymphonyDesignStyle.Text.tertiary)
            }
        }
    }

    @ViewBuilder
    private var rowBackground: some View {
        if row.isSelected {
            SymphonyDesignStyle.Accent.blue.opacity(0.10)
        } else if isHovered {
            SymphonyDesignStyle.Background.elevated
        } else if index.isMultiple(of: 2) {
            SymphonyDesignStyle.Background.secondary
        } else {
            SymphonyDesignStyle.Background.tertiary
        }
    }
}
```

Note: `scopeCell` now renders as a `SymphonyLabelChipView` with indigo accent (design alignment). The old title cell no longer shows scope name inline — it moved to its own column.

**Step 2: Create SymphonyIssueListSectionHeaderView.swift**

```swift
import SwiftUI

// MARK: - SymphonyIssueListSectionHeaderView
/// Section header for grouped issue list mode, with optional error row.

public struct SymphonyIssueListSectionHeaderView: View {
    let section: SymphonyIssueListSectionViewModel
    let showHeader: Bool

    public init(section: SymphonyIssueListSectionViewModel, showHeader: Bool) {
        self.section = section
        self.showHeader = showHeader
    }

    public var body: some View {
        if showHeader {
            header
        }

        if let errorMessage = section.errorMessage,
           errorMessage.isEmpty == false {
            errorRow(errorMessage)
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: SymphonyDesignStyle.Spacing.xxs) {
            if let title = section.title {
                Text(title)
                    .font(SymphonyDesignStyle.Typography.title3)
                    .foregroundStyle(SymphonyDesignStyle.Text.primary)
            }

            if let subtitle = section.subtitle,
               subtitle.isEmpty == false {
                Text(subtitle)
                    .font(SymphonyDesignStyle.Typography.caption)
                    .foregroundStyle(SymphonyDesignStyle.Text.tertiary)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, SymphonyDesignStyle.Spacing.lg)
        .padding(.top, SymphonyDesignStyle.Spacing.lg)
        .padding(.bottom, SymphonyDesignStyle.Spacing.sm)
        .background(SymphonyDesignStyle.Background.secondary)
    }

    private func errorRow(_ message: String) -> some View {
        HStack(spacing: SymphonyDesignStyle.Spacing.sm) {
            Image(systemName: "exclamationmark.triangle.fill")
                .foregroundStyle(SymphonyDesignStyle.Accent.coral)
            Text(message)
                .font(SymphonyDesignStyle.Typography.caption)
                .foregroundStyle(SymphonyDesignStyle.Text.secondary)
            Spacer()
        }
        .padding(.horizontal, SymphonyDesignStyle.Spacing.lg)
        .padding(.vertical, SymphonyDesignStyle.Spacing.sm)
        .background(SymphonyDesignStyle.Background.tertiary)
    }
}
```

**Step 3: Update SymphonyIssueListView**

Replace `issueRow()`, `rowBackground()`, `agentCell()`, `labelsCell()`, `sectionHeader()`, `sectionErrorRow()`, and `shouldRenderSectionHeader()` with the new views. The `dataRows` section becomes:

```swift
private var dataRows: some View {
    ScrollView {
        LazyVStack(spacing: 0) {
            ForEach(Array(filteredSections.enumerated()), id: \.element.id) { sectionIndex, section in
                SymphonyIssueListSectionHeaderView(
                    section: section,
                    showHeader: section.title != nil || section.errorMessage != nil || viewModel.sections.count > 1
                )

                ForEach(Array(section.rows.enumerated()), id: \.element.id) { rowIndex, row in
                    SymphonyIssueListRowView(
                        row: row,
                        index: sectionIndex * 1000 + rowIndex,
                        isHovered: hoveredRowID == row.id,
                        onSelected: { onIssueSelected(row.identifier) },
                        onHover: { isHovered in
                            hoveredRowID = isHovered ? row.id : nil
                        }
                    )
                    SymphonyDividerView(opacity: 0.03)
                }
            }
        }
    }
}
```

**Step 4: Build and verify previews**

**Step 5: Commit**

```
feat: extract issue list row and section header into dedicated files
```

---

### Task 7: Design Alignment — Card ViewModel + Hover + Scope Badge

**Files:**
- Modify: `SymphonyKanban/Presentation/ViewModels/Symphony/SymphonyKanbanBoardViewModel.swift:76-117` (SymphonyKanbanCardViewModel)
- Modify: `SymphonyKanban/Presentation/Presenters/Symphony/SymphonyIssueCatalogPresenter.swift:99-144`
- Modify: `SymphonyKanban/Presentation/Views/Symphony/Board/SymphonyKanbanCardView.swift`

**Step 1: Add `statusLabel` to SymphonyKanbanCardViewModel**

Add `public let statusLabel: String` after `statusKey` in the view model struct. Update the init to include it with a default computed from statusKey:

```swift
public let statusLabel: String

public init(
    id: String,
    identifier: String,
    title: String,
    scopeName: String? = nil,
    priorityLevel: Int,
    statusKey: String,
    statusLabel: String? = nil,
    agentName: String? = nil,
    labels: [String] = [],
    tokenCount: String? = nil,
    lastEvent: String? = nil,
    lastEventTime: String? = nil,
    isRunning: Bool = false
) {
    // ... existing assignments ...
    self.statusLabel = statusLabel ?? statusKey.capitalized
    // ... rest ...
}
```

**Step 2: Update presenter to pass statusLabel when creating card view models**

In `SymphonyIssueCatalogPresenter`, both `makeColumn` overloads should pass the status title as `statusLabel`. The column already has a `title` property that maps to the human label ("In Progress", "Backlog", etc.), so pass `title` as the card's `statusLabel`:

In the `makeColumn(id:title:entries:)` method (line 99):
```swift
statusLabel: title,
```

In the `makeColumn(id:title:issues:scopeName:)` method (line 122):
```swift
statusLabel: title,
```

**Step 3: Update card view to use `.symphonyElevatedCard()` on hover**

Replace the custom hover shadow in `SymphonyKanbanCardView` body. Remove:
```swift
.scaleEffect(isHovered ? 1.015 : 1.0)
.shadow(
    color: .black.opacity(isHovered ? 0.35 : 0),
    radius: isHovered ? 12 : 0,
    x: 0,
    y: isHovered ? 6 : 0
)
```

Replace with a conditional modifier approach — apply `.symphonyCard()` normally and overlay an elevated style on hover:

```swift
.buttonStyle(.plain)
.opacity(isHovered ? 0.97 : 1.0)
.scaleEffect(isHovered ? 1.01 : 1.0)
.onHover { hovering in
    withAnimation(SymphonyDesignStyle.Motion.stiffSnap) {
        isHovered = hovering
    }
}
```

This is lighter than the old hardcoded shadow while still providing feedback.

**Step 4: Update card titleRow to show scope badge**

In the card's `titleRow`, replace the plain text scope name with a `SymphonyLabelChipView`:

```swift
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
```

**Step 5: Update mock data to include statusLabel**

Update mock data in `SymphonyKanbanBoardView` to pass `statusLabel` for each card. Example:
```swift
statusLabel: "In Progress",
```

**Step 6: Build and verify previews**

**Step 7: Commit**

```
feat: align card view with design system — status label, scope badge, hover
```

---

### Task 8: Design Alignment — List View Row Alternation + Scope Column

**Files:**
- Modify: `SymphonyKanban/Presentation/Views/Symphony/Issues/SymphonyIssueListRowView.swift`
- Modify: `SymphonyKanban/Presentation/Views/Symphony/Issues/SymphonyIssueListView.swift`

**Step 1: Fix row alternation in SymphonyIssueListRowView**

The row background already uses `SymphonyDesignStyle.Background.secondary` and `.tertiary`. Replace the `.opacity(0.4)` on tertiary — it's fine as written after extraction since we use `SymphonyDesignStyle.Background.tertiary` directly. Verify no `.opacity(0.4)` remains.

**Step 2: Add scope sort case to rowComparator**

In `SymphonyIssueListView`, add the `.scope` case to `rowComparator`:

```swift
case .scope:
    result = (a.scopeName ?? "").localizedStandardCompare(b.scopeName ?? "") == .orderedAscending
```

**Step 3: Build and verify previews**

**Step 4: Commit**

```
feat: align list view with design system — scope column, row backgrounds
```

---

### Task 9: Create SymphonyStartupGateView

**Files:**
- Create: `SymphonyKanban/Presentation/Views/Symphony/Startup/SymphonyStartupGateView.swift`

**Step 1: Create the file**

```swift
import SwiftUI

// MARK: - SymphonyStartupGateView
/// Root application gate that branches on startup state. Sits between
/// the app entry point and the main navigation routes, ensuring the
/// user sees loading, setup, or error screens before entering the app.

public struct SymphonyStartupGateView: View {
    private let startupStatusController: SymphonyStartupStatusController
    private let navigationRoutesBuilder: (SymphonyStartupStatusViewModel) -> AnyView
    private let setupViewBuilder: (SymphonyStartupStatusViewModel) -> AnyView

    @State private var phase: StartupPhase = .loading
    @State private var appeared = false

    private enum StartupPhase: Equatable {
        case loading
        case ready(SymphonyStartupStatusViewModel)
        case setupRequired(SymphonyStartupStatusViewModel)
        case failed(SymphonyStartupStatusViewModel)
    }

    public init(
        startupStatusController: SymphonyStartupStatusController,
        navigationRoutesBuilder: @escaping (SymphonyStartupStatusViewModel) -> AnyView,
        setupViewBuilder: @escaping (SymphonyStartupStatusViewModel) -> AnyView
    ) {
        self.startupStatusController = startupStatusController
        self.navigationRoutesBuilder = navigationRoutesBuilder
        self.setupViewBuilder = setupViewBuilder
    }

    public var body: some View {
        Group {
            switch phase {
            case .loading:
                SymphonyStartupLoadingView()
                    .transition(.opacity.combined(with: .scale(scale: 0.98)))

            case .ready(let viewModel):
                navigationRoutesBuilder(viewModel)
                    .transition(.opacity.combined(with: .scale(scale: 0.98)))

            case .setupRequired(let viewModel):
                setupViewBuilder(viewModel)
                    .transition(.opacity.combined(with: .scale(scale: 0.98)))

            case .failed(let viewModel):
                SymphonyStartupErrorView(
                    viewModel: viewModel,
                    onRetry: { resolveStartupState() },
                    onSetup: {
                        withAnimation(SymphonyDesignStyle.Motion.smooth) {
                            phase = .setupRequired(viewModel)
                        }
                    }
                )
                .transition(.opacity.combined(with: .scale(scale: 0.98)))
            }
        }
        .animation(SymphonyDesignStyle.Motion.smooth, value: phaseKey)
        .onAppear {
            resolveStartupState()
        }
    }

    private func resolveStartupState() {
        withAnimation(SymphonyDesignStyle.Motion.smooth) {
            phase = .loading
        }

        // Small delay to show loading state visually
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
            let viewModel = startupStatusController.queryViewModel()

            withAnimation(SymphonyDesignStyle.Motion.smooth) {
                switch viewModel.state {
                case .ready:
                    phase = .ready(viewModel)
                case .setupRequired:
                    phase = .setupRequired(viewModel)
                case .failed:
                    phase = .failed(viewModel)
                }
            }
        }
    }

    private var phaseKey: String {
        switch phase {
        case .loading: return "loading"
        case .ready: return "ready"
        case .setupRequired: return "setupRequired"
        case .failed: return "failed"
        }
    }
}

#Preview("Startup Gate - Loading") {
    SymphonyStartupGateView(
        startupStatusController: SymphonyStartupStatusController(
            startupService: SymphonyStartupService.mock
        ),
        navigationRoutesBuilder: { _ in AnyView(Text("Main App")) },
        setupViewBuilder: { _ in AnyView(Text("Setup")) }
    )
    .frame(width: 800, height: 600)
}
```

Note: The preview depends on a mock `SymphonyStartupService`. If no `.mock` exists, use a minimal preview that shows just the loading state.

**Step 2: Build and verify preview renders**

**Step 3: Commit**

```
feat: add startup gate view with loading/ready/setup/failed branching
```

---

### Task 10: Create SymphonyStartupLoadingView

**Files:**
- Create: `SymphonyKanban/Presentation/Views/Symphony/Startup/SymphonyStartupLoadingView.swift`

**Step 1: Create the file**

```swift
import SwiftUI

// MARK: - SymphonyStartupLoadingView
/// Loading screen shown while the startup gate resolves workspace
/// bindings and validates tracker access.

public struct SymphonyStartupLoadingView: View {
    @State private var appeared = false
    @State private var statusIndex = 0

    private let statusMessages = [
        "Checking saved workspace bindings...",
        "Validating tracker access..."
    ]

    public init() {}

    public var body: some View {
        ZStack {
            LinearGradient.symphonyBackground.ignoresSafeArea()

            VStack(spacing: SymphonyDesignStyle.Spacing.xl) {
                Image(systemName: "arrow.triangle.2.circlepath")
                    .font(.system(size: 40, weight: .light))
                    .foregroundStyle(SymphonyDesignStyle.Accent.teal)
                    .symphonyStaggerIn(index: 0, isVisible: appeared)

                Text("Symphony")
                    .font(SymphonyDesignStyle.Typography.largeTitle)
                    .foregroundStyle(SymphonyDesignStyle.Text.primary)
                    .symphonyStaggerIn(index: 1, isVisible: appeared)

                HStack(spacing: SymphonyDesignStyle.Spacing.sm) {
                    SymphonyPulsingDotView(color: SymphonyDesignStyle.Accent.teal)
                    Text(statusMessages[statusIndex])
                        .font(SymphonyDesignStyle.Typography.body)
                        .foregroundStyle(SymphonyDesignStyle.Text.secondary)
                }
                .symphonyStaggerIn(index: 2, isVisible: appeared)
            }
        }
        .onAppear {
            withAnimation(SymphonyDesignStyle.Motion.gentle) {
                appeared = true
            }
            // Advance status message after a delay
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) {
                withAnimation(SymphonyDesignStyle.Motion.smooth) {
                    statusIndex = min(statusIndex + 1, statusMessages.count - 1)
                }
            }
        }
    }
}

#Preview("Startup Loading") {
    SymphonyStartupLoadingView()
        .frame(width: 800, height: 600)
}
```

**Step 2: Build and verify preview**

**Step 3: Commit**

```
feat: add startup loading view with progressive status text
```

---

### Task 11: Create SymphonyStartupErrorView

**Files:**
- Create: `SymphonyKanban/Presentation/Views/Symphony/Startup/SymphonyStartupErrorView.swift`

**Step 1: Create the file**

```swift
import SwiftUI

// MARK: - SymphonyStartupErrorView
/// Full-screen error surface for startup failures with retry action.

public struct SymphonyStartupErrorView: View {
    let viewModel: SymphonyStartupStatusViewModel
    let onRetry: () -> Void
    let onSetup: () -> Void

    @State private var appeared = false

    public init(
        viewModel: SymphonyStartupStatusViewModel,
        onRetry: @escaping () -> Void,
        onSetup: @escaping () -> Void
    ) {
        self.viewModel = viewModel
        self.onRetry = onRetry
        self.onSetup = onSetup
    }

    public var body: some View {
        ZStack {
            LinearGradient.symphonyBackground.ignoresSafeArea()

            VStack(spacing: SymphonyDesignStyle.Spacing.xl) {
                Image(systemName: "exclamationmark.triangle.fill")
                    .font(.system(size: 40, weight: .light))
                    .foregroundStyle(SymphonyDesignStyle.Accent.coral)
                    .symphonyStaggerIn(index: 0, isVisible: appeared)

                VStack(spacing: SymphonyDesignStyle.Spacing.sm) {
                    Text(viewModel.title)
                        .font(SymphonyDesignStyle.Typography.title)
                        .foregroundStyle(SymphonyDesignStyle.Text.primary)

                    Text(viewModel.message)
                        .font(SymphonyDesignStyle.Typography.body)
                        .foregroundStyle(SymphonyDesignStyle.Text.secondary)
                        .multilineTextAlignment(.center)
                        .frame(maxWidth: 400)
                }
                .symphonyStaggerIn(index: 1, isVisible: appeared)

                HStack(spacing: SymphonyDesignStyle.Spacing.md) {
                    Button(action: onRetry) {
                        HStack(spacing: SymphonyDesignStyle.Spacing.sm) {
                            Image(systemName: "arrow.clockwise")
                            Text("Retry")
                        }
                        .font(SymphonyDesignStyle.Typography.headline)
                        .foregroundStyle(.white)
                        .padding(.horizontal, SymphonyDesignStyle.Spacing.xl)
                        .padding(.vertical, SymphonyDesignStyle.Spacing.md)
                        .background(
                            RoundedRectangle(cornerRadius: SymphonyDesignStyle.Radius.lg, style: .continuous)
                                .fill(SymphonyDesignStyle.Accent.blue)
                        )
                    }
                    .buttonStyle(.plain)

                    Button(action: onSetup) {
                        Text("Setup Workspace")
                            .font(SymphonyDesignStyle.Typography.headline)
                            .foregroundStyle(SymphonyDesignStyle.Text.secondary)
                            .padding(.horizontal, SymphonyDesignStyle.Spacing.xl)
                            .padding(.vertical, SymphonyDesignStyle.Spacing.md)
                            .background(
                                RoundedRectangle(cornerRadius: SymphonyDesignStyle.Radius.lg, style: .continuous)
                                    .fill(SymphonyDesignStyle.Background.tertiary)
                            )
                            .overlay(
                                RoundedRectangle(cornerRadius: SymphonyDesignStyle.Radius.lg, style: .continuous)
                                    .strokeBorder(SymphonyDesignStyle.Border.default, lineWidth: 0.5)
                            )
                    }
                    .buttonStyle(.plain)
                }
                .symphonyStaggerIn(index: 2, isVisible: appeared)
            }
        }
        .onAppear {
            withAnimation(SymphonyDesignStyle.Motion.gentle) {
                appeared = true
            }
        }
    }
}

#Preview("Startup Error") {
    SymphonyStartupErrorView(
        viewModel: SymphonyStartupStatusViewModel(
            state: .failed,
            title: "Startup Failed",
            message: "Could not connect to tracker. Check your network connection and try again.",
            currentWorkingDirectoryPath: "/Users/demo/project",
            explicitWorkflowPath: nil,
            activeBindingCount: 0,
            readyBindingCount: 0,
            failedBindingCount: 0,
            boundScopeNames: [],
            resolvedWorkflowPaths: [],
            trackerStatusLabels: []
        ),
        onRetry: {},
        onSetup: {}
    )
    .frame(width: 800, height: 600)
}
```

**Step 2: Build and verify preview**

**Step 3: Commit**

```
feat: add startup error view with retry and setup actions
```

---

### Task 12: Create SymphonyStartupDegradedBannerView

**Files:**
- Create: `SymphonyKanban/Presentation/Views/Symphony/Startup/SymphonyStartupDegradedBannerView.swift`

**Step 1: Create the file**

```swift
import SwiftUI

// MARK: - SymphonyStartupDegradedBannerView
/// Compact amber banner shown when some workspace bindings failed
/// but at least one is healthy.

public struct SymphonyStartupDegradedBannerView: View {
    let failedBindingCount: Int
    let activeBindingCount: Int
    let onDismiss: () -> Void
    let onTap: () -> Void

    @State private var isExpanded = false

    public init(
        failedBindingCount: Int,
        activeBindingCount: Int,
        onDismiss: @escaping () -> Void,
        onTap: @escaping () -> Void = {}
    ) {
        self.failedBindingCount = failedBindingCount
        self.activeBindingCount = activeBindingCount
        self.onDismiss = onDismiss
        self.onTap = onTap
    }

    public var body: some View {
        HStack(spacing: SymphonyDesignStyle.Spacing.sm) {
            Image(systemName: "exclamationmark.triangle.fill")
                .foregroundStyle(SymphonyDesignStyle.Accent.amber)

            Text("\(failedBindingCount) of \(activeBindingCount) workspace bindings failed")
                .font(SymphonyDesignStyle.Typography.caption)
                .foregroundStyle(SymphonyDesignStyle.Text.secondary)

            Spacer()

            Button(action: onDismiss) {
                Image(systemName: "xmark")
                    .font(.system(size: 10, weight: .bold))
                    .foregroundStyle(SymphonyDesignStyle.Text.tertiary)
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, SymphonyDesignStyle.Spacing.lg)
        .padding(.vertical, SymphonyDesignStyle.Spacing.sm)
        .background(SymphonyDesignStyle.Accent.amber.opacity(0.10))
        .overlay(alignment: .bottom) {
            Rectangle()
                .fill(SymphonyDesignStyle.Accent.amber.opacity(0.20))
                .frame(height: 0.5)
        }
        .onTapGesture(perform: onTap)
    }
}

#Preview("Degraded Banner") {
    VStack(spacing: 0) {
        SymphonyStartupDegradedBannerView(
            failedBindingCount: 1,
            activeBindingCount: 2,
            onDismiss: {}
        )
        Spacer()
    }
    .frame(width: 800, height: 200)
    .background(SymphonyDesignStyle.Background.secondary)
}
```

**Step 2: Build and verify preview**

**Step 3: Commit**

```
feat: add degraded banner for partial binding failures
```

---

### Task 13: Create SymphonyWorkspaceBindingSetupView (Container)

**Files:**
- Create: `SymphonyKanban/Presentation/Views/Symphony/Setup/SymphonyWorkspaceBindingSetupView.swift`

**Step 1: Create the file**

```swift
import SwiftUI

// MARK: - SymphonyWorkspaceBindingSetupView
/// Multi-step wizard for creating workspace-to-tracker bindings.
/// Manages step navigation, back button, and step indicator dots.

public struct SymphonyWorkspaceBindingSetupView: View {
    public enum Mode {
        case firstRun
        case repair
    }

    let mode: Mode
    let onComplete: () -> Void

    @State private var currentStep: SetupStep
    @State private var appeared = false
    @State private var selectedTrackerKind: String?
    @State private var isAuthenticated = false
    @State private var selectedScopes: [ScopeSelection] = []
    @State private var completedBindings: [BindingSummary] = []

    public struct ScopeSelection: Equatable, Identifiable {
        public let id: String
        public let scopeKind: String
        public let scopeIdentifier: String
        public let scopeName: String
    }

    public struct BindingSummary: Equatable, Identifiable {
        public let id: String
        public let trackerKind: String
        public let scopeName: String
        public let isHealthy: Bool
    }

    enum SetupStep: Int, CaseIterable {
        case welcome = 0
        case trackerSelection = 1
        case authentication = 2
        case scopeSelection = 3
        case confirmation = 4

        var dotCount: Int { SetupStep.allCases.count }
    }

    public init(
        mode: Mode = .firstRun,
        onComplete: @escaping () -> Void
    ) {
        self.mode = mode
        self.onComplete = onComplete
        self._currentStep = State(initialValue: mode == .repair ? .trackerSelection : .welcome)
    }

    public var body: some View {
        ZStack {
            LinearGradient.symphonyBackground.ignoresSafeArea()

            VStack(spacing: 0) {
                // Top bar with back button
                topBar
                    .symphonyStaggerIn(index: 0, isVisible: appeared)

                // Step content
                stepContent
                    .frame(maxWidth: 480, maxHeight: .infinity)
                    .frame(maxWidth: .infinity)

                // Step indicator dots
                stepDots
                    .padding(.bottom, SymphonyDesignStyle.Spacing.xl)
                    .symphonyStaggerIn(index: 1, isVisible: appeared)
            }
        }
        .onAppear {
            withAnimation(SymphonyDesignStyle.Motion.gentle) {
                appeared = true
            }
        }
    }

    private var topBar: some View {
        HStack {
            if currentStep.rawValue > (mode == .repair ? 1 : 0) {
                Button {
                    withAnimation(SymphonyDesignStyle.Motion.smooth) {
                        goBack()
                    }
                } label: {
                    HStack(spacing: SymphonyDesignStyle.Spacing.xs) {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 12, weight: .semibold))
                        Text("Back")
                            .font(SymphonyDesignStyle.Typography.body)
                    }
                    .foregroundStyle(SymphonyDesignStyle.Text.secondary)
                }
                .buttonStyle(.plain)
            }

            Spacer()
        }
        .padding(.horizontal, SymphonyDesignStyle.Spacing.lg)
        .padding(.vertical, SymphonyDesignStyle.Spacing.md)
        .frame(height: 48)
    }

    @ViewBuilder
    private var stepContent: some View {
        Group {
            switch currentStep {
            case .welcome:
                SymphonySetupWelcomeStepView {
                    advanceTo(.trackerSelection)
                }

            case .trackerSelection:
                SymphonySetupTrackerSelectionStepView(
                    selectedTrackerKind: $selectedTrackerKind,
                    onContinue: { advanceTo(.authentication) }
                )

            case .authentication:
                SymphonySetupAuthenticationStepView(
                    trackerKind: selectedTrackerKind ?? "linear",
                    isAuthenticated: $isAuthenticated,
                    onContinue: { advanceTo(.scopeSelection) }
                )

            case .scopeSelection:
                SymphonySetupScopeSelectionStepView(
                    trackerKind: selectedTrackerKind ?? "linear",
                    selectedScopes: $selectedScopes,
                    onContinue: { advanceTo(.confirmation) }
                )

            case .confirmation:
                SymphonySetupConfirmationStepView(
                    trackerKind: selectedTrackerKind ?? "linear",
                    selectedScopes: selectedScopes,
                    completedBindings: completedBindings,
                    onAddAnother: {
                        // Save current scopes as completed, reset for next round
                        for scope in selectedScopes {
                            completedBindings.append(BindingSummary(
                                id: scope.id,
                                trackerKind: selectedTrackerKind ?? "linear",
                                scopeName: scope.scopeName,
                                isHealthy: true
                            ))
                        }
                        selectedScopes = []
                        advanceTo(.trackerSelection)
                    },
                    onComplete: onComplete
                )
            }
        }
        .transition(.asymmetric(
            insertion: .move(edge: .trailing).combined(with: .opacity),
            removal: .move(edge: .leading).combined(with: .opacity)
        ))
    }

    private var stepDots: some View {
        HStack(spacing: SymphonyDesignStyle.Spacing.sm) {
            ForEach(SetupStep.allCases, id: \.rawValue) { step in
                Circle()
                    .fill(
                        step == currentStep
                            ? SymphonyDesignStyle.Accent.blue
                            : SymphonyDesignStyle.Text.tertiary.opacity(0.4)
                    )
                    .frame(width: 6, height: 6)
            }
        }
    }

    private func advanceTo(_ step: SetupStep) {
        withAnimation(SymphonyDesignStyle.Motion.smooth) {
            currentStep = step
        }
    }

    private func goBack() {
        let allSteps = SetupStep.allCases
        let minStep = mode == .repair ? 1 : 0
        if let currentIndex = allSteps.firstIndex(of: currentStep),
           currentIndex > minStep {
            currentStep = allSteps[currentIndex - 1]
        }
    }
}

#Preview("Setup - First Run") {
    SymphonyWorkspaceBindingSetupView(
        mode: .firstRun,
        onComplete: {}
    )
    .frame(width: 800, height: 600)
}

#Preview("Setup - Repair") {
    SymphonyWorkspaceBindingSetupView(
        mode: .repair,
        onComplete: {}
    )
    .frame(width: 800, height: 600)
}
```

**Step 2: Build (will have errors until step views are created in Tasks 14-18)**

**Step 3: Commit**

```
feat: add workspace binding setup container with step navigation
```

---

### Task 14: Create SymphonySetupWelcomeStepView

**Files:**
- Create: `SymphonyKanban/Presentation/Views/Symphony/Setup/SymphonySetupWelcomeStepView.swift`

**Step 1: Create the file**

```swift
import SwiftUI

// MARK: - SymphonySetupWelcomeStepView
/// Welcome step explaining what Symphony does and prompting the user
/// to connect their first workspace.

public struct SymphonySetupWelcomeStepView: View {
    let onGetStarted: () -> Void

    @State private var appeared = false

    public init(onGetStarted: @escaping () -> Void) {
        self.onGetStarted = onGetStarted
    }

    public var body: some View {
        VStack(spacing: SymphonyDesignStyle.Spacing.xxl) {
            Spacer()

            Image(systemName: "square.grid.3x3.topleft.filled")
                .font(.system(size: 48, weight: .light))
                .foregroundStyle(SymphonyDesignStyle.Accent.teal)
                .symphonyStaggerIn(index: 0, isVisible: appeared)

            VStack(spacing: SymphonyDesignStyle.Spacing.md) {
                Text("Welcome to Symphony")
                    .font(SymphonyDesignStyle.Typography.largeTitle)
                    .foregroundStyle(SymphonyDesignStyle.Text.primary)

                Text("Connect your workspace to a project tracker to see your issues on a live Kanban board.")
                    .font(SymphonyDesignStyle.Typography.body)
                    .foregroundStyle(SymphonyDesignStyle.Text.secondary)
                    .multilineTextAlignment(.center)
                    .frame(maxWidth: 360)
            }
            .symphonyStaggerIn(index: 1, isVisible: appeared)

            Button(action: onGetStarted) {
                Text("Get Started")
                    .font(SymphonyDesignStyle.Typography.headline)
                    .foregroundStyle(.white)
                    .padding(.horizontal, SymphonyDesignStyle.Spacing.xxl)
                    .padding(.vertical, SymphonyDesignStyle.Spacing.md)
                    .background(
                        RoundedRectangle(cornerRadius: SymphonyDesignStyle.Radius.lg, style: .continuous)
                            .fill(SymphonyDesignStyle.Accent.blue)
                    )
            }
            .buttonStyle(.plain)
            .symphonyStaggerIn(index: 2, isVisible: appeared)

            Spacer()
        }
        .onAppear {
            withAnimation(SymphonyDesignStyle.Motion.gentle) {
                appeared = true
            }
        }
    }
}

#Preview("Welcome Step") {
    SymphonySetupWelcomeStepView(onGetStarted: {})
        .frame(width: 480, height: 600)
        .background(LinearGradient.symphonyBackground)
}
```

**Step 2: Build and verify preview**

**Step 3: Commit**

```
feat: add setup welcome step view
```

---

### Task 15: Create SymphonySetupTrackerSelectionStepView

**Files:**
- Create: `SymphonyKanban/Presentation/Views/Symphony/Setup/SymphonySetupTrackerSelectionStepView.swift`

**Step 1: Create the file**

```swift
import SwiftUI

// MARK: - SymphonySetupTrackerSelectionStepView
/// Tracker selection step showing available tracker integrations as
/// selectable cards.

public struct SymphonySetupTrackerSelectionStepView: View {
    @Binding var selectedTrackerKind: String?
    let onContinue: () -> Void

    @State private var appeared = false

    private struct TrackerOption: Identifiable {
        let id: String
        let name: String
        let icon: String
        let description: String
    }

    private let trackers = [
        TrackerOption(
            id: "linear",
            name: "Linear",
            icon: "chart.bar.xaxis",
            description: "Connect to Linear teams and projects"
        )
    ]

    public init(
        selectedTrackerKind: Binding<String?>,
        onContinue: @escaping () -> Void
    ) {
        self._selectedTrackerKind = selectedTrackerKind
        self.onContinue = onContinue
    }

    public var body: some View {
        VStack(spacing: SymphonyDesignStyle.Spacing.xxl) {
            Spacer()

            VStack(spacing: SymphonyDesignStyle.Spacing.sm) {
                Text("Choose a Tracker")
                    .font(SymphonyDesignStyle.Typography.title)
                    .foregroundStyle(SymphonyDesignStyle.Text.primary)

                Text("Select the project tracker you want to connect.")
                    .font(SymphonyDesignStyle.Typography.body)
                    .foregroundStyle(SymphonyDesignStyle.Text.secondary)
            }
            .symphonyStaggerIn(index: 0, isVisible: appeared)

            VStack(spacing: SymphonyDesignStyle.Spacing.md) {
                ForEach(Array(trackers.enumerated()), id: \.element.id) { index, tracker in
                    Button {
                        withAnimation(SymphonyDesignStyle.Motion.snappy) {
                            selectedTrackerKind = tracker.id
                        }
                    } label: {
                        HStack(spacing: SymphonyDesignStyle.Spacing.md) {
                            Image(systemName: tracker.icon)
                                .font(.system(size: 24, weight: .medium))
                                .foregroundStyle(SymphonyDesignStyle.Accent.blue)
                                .frame(width: 40)

                            VStack(alignment: .leading, spacing: SymphonyDesignStyle.Spacing.xxs) {
                                Text(tracker.name)
                                    .font(SymphonyDesignStyle.Typography.headline)
                                    .foregroundStyle(SymphonyDesignStyle.Text.primary)
                                Text(tracker.description)
                                    .font(SymphonyDesignStyle.Typography.caption)
                                    .foregroundStyle(SymphonyDesignStyle.Text.secondary)
                            }

                            Spacer()

                            if selectedTrackerKind == tracker.id {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundStyle(SymphonyDesignStyle.Accent.blue)
                            }
                        }
                        .padding(SymphonyDesignStyle.Spacing.md)
                        .symphonyCard(selected: selectedTrackerKind == tracker.id)
                    }
                    .buttonStyle(.plain)
                    .symphonyStaggerIn(index: index + 1, isVisible: appeared)
                }
            }

            Button(action: onContinue) {
                Text("Continue")
                    .font(SymphonyDesignStyle.Typography.headline)
                    .foregroundStyle(.white)
                    .padding(.horizontal, SymphonyDesignStyle.Spacing.xxl)
                    .padding(.vertical, SymphonyDesignStyle.Spacing.md)
                    .background(
                        RoundedRectangle(cornerRadius: SymphonyDesignStyle.Radius.lg, style: .continuous)
                            .fill(SymphonyDesignStyle.Accent.blue)
                    )
            }
            .buttonStyle(.plain)
            .disabled(selectedTrackerKind == nil)
            .opacity(selectedTrackerKind == nil ? 0.5 : 1.0)
            .symphonyStaggerIn(index: trackers.count + 1, isVisible: appeared)

            Spacer()
        }
        .onAppear {
            withAnimation(SymphonyDesignStyle.Motion.gentle) {
                appeared = true
            }
        }
    }
}

#Preview("Tracker Selection") {
    SymphonySetupTrackerSelectionStepView(
        selectedTrackerKind: .constant("linear"),
        onContinue: {}
    )
    .frame(width: 480, height: 600)
    .background(LinearGradient.symphonyBackground)
}
```

**Step 2: Build and verify preview**

**Step 3: Commit**

```
feat: add tracker selection step view
```

---

### Task 16: Create SymphonySetupAuthenticationStepView

**Files:**
- Create: `SymphonyKanban/Presentation/Views/Symphony/Setup/SymphonySetupAuthenticationStepView.swift`

**Step 1: Create the file**

```swift
import SwiftUI

// MARK: - SymphonySetupAuthenticationStepView
/// Authentication step that shows connection status and triggers
/// the OAuth flow if not yet authenticated.

public struct SymphonySetupAuthenticationStepView: View {
    let trackerKind: String
    @Binding var isAuthenticated: Bool
    let onContinue: () -> Void

    @State private var appeared = false

    public init(
        trackerKind: String,
        isAuthenticated: Binding<Bool>,
        onContinue: @escaping () -> Void
    ) {
        self.trackerKind = trackerKind
        self._isAuthenticated = isAuthenticated
        self.onContinue = onContinue
    }

    public var body: some View {
        VStack(spacing: SymphonyDesignStyle.Spacing.xxl) {
            Spacer()

            VStack(spacing: SymphonyDesignStyle.Spacing.sm) {
                Text("Authenticate")
                    .font(SymphonyDesignStyle.Typography.title)
                    .foregroundStyle(SymphonyDesignStyle.Text.primary)

                Text("Connect to \(trackerDisplayName) to access your issues.")
                    .font(SymphonyDesignStyle.Typography.body)
                    .foregroundStyle(SymphonyDesignStyle.Text.secondary)
            }
            .symphonyStaggerIn(index: 0, isVisible: appeared)

            // Connection status card
            VStack(spacing: SymphonyDesignStyle.Spacing.md) {
                HStack(spacing: SymphonyDesignStyle.Spacing.md) {
                    Circle()
                        .fill(isAuthenticated ? SymphonyDesignStyle.Accent.green : SymphonyDesignStyle.Accent.amber)
                        .frame(width: 10, height: 10)

                    Text(isAuthenticated ? "Connected to \(trackerDisplayName)" : "Not connected")
                        .font(SymphonyDesignStyle.Typography.headline)
                        .foregroundStyle(SymphonyDesignStyle.Text.primary)

                    Spacer()

                    if isAuthenticated {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundStyle(SymphonyDesignStyle.Accent.green)
                    }
                }
                .padding(SymphonyDesignStyle.Spacing.md)
                .symphonyCard(selected: isAuthenticated)

                if !isAuthenticated {
                    Button {
                        // In real implementation, this triggers OAuth via SymphonyAuthController
                        // For now, simulate connection
                        withAnimation(SymphonyDesignStyle.Motion.snappy) {
                            isAuthenticated = true
                        }
                    } label: {
                        HStack(spacing: SymphonyDesignStyle.Spacing.sm) {
                            Image(systemName: "link")
                            Text("Connect \(trackerDisplayName)")
                        }
                        .font(SymphonyDesignStyle.Typography.headline)
                        .foregroundStyle(.white)
                        .padding(.horizontal, SymphonyDesignStyle.Spacing.xxl)
                        .padding(.vertical, SymphonyDesignStyle.Spacing.md)
                        .background(
                            RoundedRectangle(cornerRadius: SymphonyDesignStyle.Radius.lg, style: .continuous)
                                .fill(SymphonyDesignStyle.Accent.blue)
                        )
                    }
                    .buttonStyle(.plain)
                }
            }
            .symphonyStaggerIn(index: 1, isVisible: appeared)

            if isAuthenticated {
                Button(action: onContinue) {
                    Text("Continue")
                        .font(SymphonyDesignStyle.Typography.headline)
                        .foregroundStyle(.white)
                        .padding(.horizontal, SymphonyDesignStyle.Spacing.xxl)
                        .padding(.vertical, SymphonyDesignStyle.Spacing.md)
                        .background(
                            RoundedRectangle(cornerRadius: SymphonyDesignStyle.Radius.lg, style: .continuous)
                                .fill(SymphonyDesignStyle.Accent.blue)
                        )
                }
                .buttonStyle(.plain)
                .symphonyStaggerIn(index: 2, isVisible: appeared)
            }

            Spacer()
        }
        .onAppear {
            withAnimation(SymphonyDesignStyle.Motion.gentle) {
                appeared = true
            }
        }
    }

    private var trackerDisplayName: String {
        switch trackerKind {
        case "linear": return "Linear"
        default: return trackerKind.capitalized
        }
    }
}

#Preview("Auth - Not Connected") {
    SymphonySetupAuthenticationStepView(
        trackerKind: "linear",
        isAuthenticated: .constant(false),
        onContinue: {}
    )
    .frame(width: 480, height: 600)
    .background(LinearGradient.symphonyBackground)
}

#Preview("Auth - Connected") {
    SymphonySetupAuthenticationStepView(
        trackerKind: "linear",
        isAuthenticated: .constant(true),
        onContinue: {}
    )
    .frame(width: 480, height: 600)
    .background(LinearGradient.symphonyBackground)
}
```

**Step 2: Build and verify previews**

**Step 3: Commit**

```
feat: add authentication step view for setup wizard
```

---

### Task 17: Create SymphonySetupScopeSelectionStepView

**Files:**
- Create: `SymphonyKanban/Presentation/Views/Symphony/Setup/SymphonySetupScopeSelectionStepView.swift`

**Step 1: Create the file**

```swift
import SwiftUI

// MARK: - SymphonySetupScopeSelectionStepView
/// Scope selection step allowing users to choose one or more
/// tracker scopes (teams/projects) to bind to their workspace.

public struct SymphonySetupScopeSelectionStepView: View {
    let trackerKind: String
    @Binding var selectedScopes: [SymphonyWorkspaceBindingSetupView.ScopeSelection]
    let onContinue: () -> Void

    @State private var appeared = false
    @State private var isLoading = true

    // Mock available scopes — in real implementation, fetched from tracker API
    private var availableScopes: [SymphonyWorkspaceBindingSetupView.ScopeSelection] {
        [
            .init(id: "team-eng", scopeKind: "team", scopeIdentifier: "ENG", scopeName: "Engineering"),
            .init(id: "team-design", scopeKind: "team", scopeIdentifier: "DES", scopeName: "Design"),
            .init(id: "team-infra", scopeKind: "team", scopeIdentifier: "INF", scopeName: "Infrastructure")
        ]
    }

    public init(
        trackerKind: String,
        selectedScopes: Binding<[SymphonyWorkspaceBindingSetupView.ScopeSelection]>,
        onContinue: @escaping () -> Void
    ) {
        self.trackerKind = trackerKind
        self._selectedScopes = selectedScopes
        self.onContinue = onContinue
    }

    public var body: some View {
        VStack(spacing: SymphonyDesignStyle.Spacing.xxl) {
            Spacer()

            VStack(spacing: SymphonyDesignStyle.Spacing.sm) {
                Text("Select Scopes")
                    .font(SymphonyDesignStyle.Typography.title)
                    .foregroundStyle(SymphonyDesignStyle.Text.primary)

                Text("Choose which teams or projects to track.")
                    .font(SymphonyDesignStyle.Typography.body)
                    .foregroundStyle(SymphonyDesignStyle.Text.secondary)
            }
            .symphonyStaggerIn(index: 0, isVisible: appeared)

            if isLoading {
                HStack(spacing: SymphonyDesignStyle.Spacing.sm) {
                    SymphonyPulsingDotView(color: SymphonyDesignStyle.Accent.teal)
                    Text("Loading available scopes...")
                        .font(SymphonyDesignStyle.Typography.body)
                        .foregroundStyle(SymphonyDesignStyle.Text.secondary)
                }
                .symphonyStaggerIn(index: 1, isVisible: appeared)
            } else {
                VStack(spacing: SymphonyDesignStyle.Spacing.sm) {
                    ForEach(Array(availableScopes.enumerated()), id: \.element.id) { index, scope in
                        let isSelected = selectedScopes.contains(where: { $0.id == scope.id })

                        Button {
                            withAnimation(SymphonyDesignStyle.Motion.snappy) {
                                if isSelected {
                                    selectedScopes.removeAll { $0.id == scope.id }
                                } else {
                                    selectedScopes.append(scope)
                                }
                            }
                        } label: {
                            HStack(spacing: SymphonyDesignStyle.Spacing.md) {
                                VStack(alignment: .leading, spacing: SymphonyDesignStyle.Spacing.xxs) {
                                    Text(scope.scopeName)
                                        .font(SymphonyDesignStyle.Typography.headline)
                                        .foregroundStyle(SymphonyDesignStyle.Text.primary)
                                    Text("\(scope.scopeKind.capitalized) \(scope.scopeIdentifier)")
                                        .font(SymphonyDesignStyle.Typography.caption)
                                        .foregroundStyle(SymphonyDesignStyle.Text.tertiary)
                                }

                                Spacer()

                                if isSelected {
                                    Image(systemName: "checkmark.circle.fill")
                                        .foregroundStyle(SymphonyDesignStyle.Accent.blue)
                                } else {
                                    Image(systemName: "circle")
                                        .foregroundStyle(SymphonyDesignStyle.Text.tertiary)
                                }
                            }
                            .padding(SymphonyDesignStyle.Spacing.md)
                            .symphonyCard(selected: isSelected)
                        }
                        .buttonStyle(.plain)
                        .symphonyStaggerIn(index: index + 1, isVisible: appeared)
                    }
                }

                Button(action: onContinue) {
                    Text("Continue")
                        .font(SymphonyDesignStyle.Typography.headline)
                        .foregroundStyle(.white)
                        .padding(.horizontal, SymphonyDesignStyle.Spacing.xxl)
                        .padding(.vertical, SymphonyDesignStyle.Spacing.md)
                        .background(
                            RoundedRectangle(cornerRadius: SymphonyDesignStyle.Radius.lg, style: .continuous)
                                .fill(SymphonyDesignStyle.Accent.blue)
                        )
                }
                .buttonStyle(.plain)
                .disabled(selectedScopes.isEmpty)
                .opacity(selectedScopes.isEmpty ? 0.5 : 1.0)
                .symphonyStaggerIn(index: availableScopes.count + 1, isVisible: appeared)
            }

            Spacer()
        }
        .onAppear {
            withAnimation(SymphonyDesignStyle.Motion.gentle) {
                appeared = true
            }
            // Simulate scope loading
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
                withAnimation(SymphonyDesignStyle.Motion.smooth) {
                    isLoading = false
                }
            }
        }
    }
}

#Preview("Scope Selection") {
    SymphonySetupScopeSelectionStepView(
        trackerKind: "linear",
        selectedScopes: .constant([]),
        onContinue: {}
    )
    .frame(width: 480, height: 600)
    .background(LinearGradient.symphonyBackground)
}
```

**Step 2: Build and verify preview**

**Step 3: Commit**

```
feat: add scope selection step view for setup wizard
```

---

### Task 18: Create SymphonySetupConfirmationStepView

**Files:**
- Create: `SymphonyKanban/Presentation/Views/Symphony/Setup/SymphonySetupConfirmationStepView.swift`

**Step 1: Create the file**

```swift
import SwiftUI

// MARK: - SymphonySetupConfirmationStepView
/// Confirmation step showing a summary of selected bindings with
/// options to add another workspace or finalize setup.

public struct SymphonySetupConfirmationStepView: View {
    let trackerKind: String
    let selectedScopes: [SymphonyWorkspaceBindingSetupView.ScopeSelection]
    let completedBindings: [SymphonyWorkspaceBindingSetupView.BindingSummary]
    let onAddAnother: () -> Void
    let onComplete: () -> Void

    @State private var appeared = false

    public init(
        trackerKind: String,
        selectedScopes: [SymphonyWorkspaceBindingSetupView.ScopeSelection],
        completedBindings: [SymphonyWorkspaceBindingSetupView.BindingSummary],
        onAddAnother: @escaping () -> Void,
        onComplete: @escaping () -> Void
    ) {
        self.trackerKind = trackerKind
        self.selectedScopes = selectedScopes
        self.completedBindings = completedBindings
        self.onAddAnother = onAddAnother
        self.onComplete = onComplete
    }

    private var allBindings: [(name: String, kind: String, isNew: Bool)] {
        let completed = completedBindings.map { (name: $0.scopeName, kind: $0.trackerKind, isNew: false) }
        let current = selectedScopes.map { (name: $0.scopeName, kind: trackerKind, isNew: true) }
        return completed + current
    }

    private var trackerDisplayName: String {
        switch trackerKind {
        case "linear": return "Linear"
        default: return trackerKind.capitalized
        }
    }

    public var body: some View {
        VStack(spacing: SymphonyDesignStyle.Spacing.xxl) {
            Spacer()

            VStack(spacing: SymphonyDesignStyle.Spacing.sm) {
                Image(systemName: "checkmark.circle")
                    .font(.system(size: 40, weight: .light))
                    .foregroundStyle(SymphonyDesignStyle.Accent.green)

                Text("Ready to Connect")
                    .font(SymphonyDesignStyle.Typography.title)
                    .foregroundStyle(SymphonyDesignStyle.Text.primary)

                Text("Review your workspace bindings before connecting.")
                    .font(SymphonyDesignStyle.Typography.body)
                    .foregroundStyle(SymphonyDesignStyle.Text.secondary)
            }
            .symphonyStaggerIn(index: 0, isVisible: appeared)

            // Binding summary cards
            VStack(spacing: SymphonyDesignStyle.Spacing.sm) {
                ForEach(Array(allBindings.enumerated()), id: \.offset) { index, binding in
                    HStack(spacing: SymphonyDesignStyle.Spacing.md) {
                        SymphonyLabelChipView(binding.kind.capitalized, color: SymphonyDesignStyle.Accent.indigo)

                        Text(binding.name)
                            .font(SymphonyDesignStyle.Typography.headline)
                            .foregroundStyle(SymphonyDesignStyle.Text.primary)

                        Spacer()

                        if binding.isNew {
                            Text("New")
                                .font(SymphonyDesignStyle.Typography.micro)
                                .foregroundStyle(SymphonyDesignStyle.Accent.green)
                        }
                    }
                    .padding(SymphonyDesignStyle.Spacing.md)
                    .symphonyCard()
                    .symphonyStaggerIn(index: index + 1, isVisible: appeared)
                }
            }

            // Actions
            VStack(spacing: SymphonyDesignStyle.Spacing.md) {
                Button(action: onComplete) {
                    Text(allBindings.count == 1 ? "Connect" : "Connect All")
                        .font(SymphonyDesignStyle.Typography.headline)
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, SymphonyDesignStyle.Spacing.md)
                        .background(
                            RoundedRectangle(cornerRadius: SymphonyDesignStyle.Radius.lg, style: .continuous)
                                .fill(SymphonyDesignStyle.Accent.blue)
                        )
                }
                .buttonStyle(.plain)

                Button(action: onAddAnother) {
                    HStack(spacing: SymphonyDesignStyle.Spacing.sm) {
                        Image(systemName: "plus")
                        Text("Add Another Workspace")
                    }
                    .font(SymphonyDesignStyle.Typography.body)
                    .foregroundStyle(SymphonyDesignStyle.Text.secondary)
                }
                .buttonStyle(.plain)
            }
            .symphonyStaggerIn(index: allBindings.count + 1, isVisible: appeared)

            Spacer()
        }
        .onAppear {
            withAnimation(SymphonyDesignStyle.Motion.gentle) {
                appeared = true
            }
        }
    }
}

#Preview("Confirmation - Single") {
    SymphonySetupConfirmationStepView(
        trackerKind: "linear",
        selectedScopes: [
            .init(id: "team-eng", scopeKind: "team", scopeIdentifier: "ENG", scopeName: "Engineering")
        ],
        completedBindings: [],
        onAddAnother: {},
        onComplete: {}
    )
    .frame(width: 480, height: 600)
    .background(LinearGradient.symphonyBackground)
}

#Preview("Confirmation - Multiple") {
    SymphonySetupConfirmationStepView(
        trackerKind: "linear",
        selectedScopes: [
            .init(id: "team-design", scopeKind: "team", scopeIdentifier: "DES", scopeName: "Design")
        ],
        completedBindings: [
            .init(id: "team-eng", trackerKind: "linear", scopeName: "Engineering", isHealthy: true)
        ],
        onAddAnother: {},
        onComplete: {}
    )
    .frame(width: 480, height: 600)
    .background(LinearGradient.symphonyBackground)
}
```

**Step 2: Build and verify previews**

**Step 3: Commit**

```
feat: add confirmation step view for setup wizard
```

---

### Task 19: Final Build + Print Section 5 Instructions

**Step 1: Build the full project**

Run: `xcodebuild build -project SymphonyKanban.xcodeproj -scheme SymphonyKanban -destination 'platform=macOS'`

Fix any compilation errors.

**Step 2: Verify all previews render**

Spot-check that the key previews render:
- SymphonyKanbanBoardView
- SymphonyKanbanCardView
- SymphonyIssueListView
- SymphonyStartupGateView
- SymphonyStartupLoadingView
- SymphonyStartupErrorView
- SymphonyWorkspaceBindingSetupView

**Step 3: Print Section 5 (DI/Routing) instructions for the user**

Output the full instructions for the user to implement the DI, routing, and content router changes as described in design section 5.

**Step 4: Commit any remaining fixes**

```
chore: fix compilation issues from view extraction and startup gate
```
