# Startup Gate & View Improvements Design

**Date:** 2026-03-30
**Branch:** codex/linear-state-type-support
**Status:** Approved

## Summary

Improve the Symphony Kanban presentation layer in four areas:
1. Split oversized view files so previews render reliably
2. Align existing views with the design system
3. Add a root startup gate with loading/setup/ready/failed states
4. Build a full workspace binding setup flow for first-run and repair

Section 5 (DI, routing, content router wiring) will be implemented separately by the user.

---

## Section 1: File Organization (View Splits)

### Board directory (`Board/`)

Split `SymphonyKanbanBoardView.swift` (329 lines) and `SymphonyKanbanCardView.swift` (207 lines):

| New File | Extracted From | Contents |
|----------|---------------|----------|
| `SymphonyKanbanBoardSectionView.swift` | BoardView | `boardSection()`, `sectionErrorView()` |
| `SymphonyKanbanColumnsScrollView.swift` | BoardView | `columnsScrollView()` — horizontal column scroller |
| `SymphonyKanbanCardTopRowView.swift` | CardView | `topRow` — priority + identifier + running + status badge |
| `SymphonyKanbanCardBottomRowView.swift` | CardView | `bottomRow` + `labelChips` — agent + labels + tokens + event |

Mock data stays inline in the parent views.

### Issues directory (`Issues/`)

Split `SymphonyIssueListView.swift` (503 lines):

| New File | Contents |
|----------|----------|
| `SymphonyIssueListFilterBarView.swift` | `filterBar` + status keys computation |
| `SymphonyIssueListHeaderRowView.swift` | `headerRow` + `columnHeader()` + `labelsHeader()` |
| `SymphonyIssueListRowView.swift` | `issueRow()` + `rowBackground()` + `agentCell()` + `labelsCell()` |
| `SymphonyIssueListSectionHeaderView.swift` | `sectionHeader()` + `sectionErrorRow()` + `shouldRenderSectionHeader()` |

---

## Section 2: Design Alignment

### Card view
- Replace custom hover shadow (`.black.opacity(0.35)`) with `.symphonyElevatedCard()` on hover
- Remove `statusLabel(for:)` — use label from view model (already provided by presenter)
- Remove `chipColor(for:)` — move label-to-color mapping to presenter/view model
- Add scope badge as `SymphonyLabelChipView` with indigo accent when `scopeName` is present

### Board view
- Replace `Group` root with consistent container
- Background tap gesture should not interfere with scroll gestures

### List view
- Add "Scope" column header to match scope name rendering in rows
- Extract `SortColumn` enum with the header row file
- Replace `.opacity(0.4)` row alternation with direct `Background.secondary`/`Background.tertiary`

---

## Section 3: Startup Gate

### New files in `Presentation/Views/Symphony/Startup/`

| File | Purpose |
|------|---------|
| `SymphonyStartupGateView.swift` | Root gate — branches on startup state |
| `SymphonyStartupLoadingView.swift` | Loading indicator with progressive status text |
| `SymphonyStartupErrorView.swift` | Failure surface with retry |
| `SymphonyStartupDegradedBannerView.swift` | Partial failure banner for content router |

### SymphonyStartupGateView

Sits between `SymphonyKanbanRootView` and `SymphonyNavigationRoutes`.

State machine:
- `loading` → query startup status
  - `setupRequired` → `SymphonyWorkspaceBindingSetupView`
  - `ready` → `SymphonyNavigationRoutes` (with binding context)
  - `failed` → `SymphonyStartupErrorView`

On `.ready` with `failedBindingCount > 0`, passes degraded state to content router.

Uses `@State private var phase: StartupPhase` (`.loading`, `.ready`, `.setupRequired`, `.failed(String)`).
Transitions: `SymphonyDesignStyle.Motion.smooth` with `.opacity.combined(with: .scale)`.

### SymphonyStartupLoadingView

- Centered layout, `LinearGradient.symphonyBackground`
- Progressive status text: "Checking saved workspace bindings..." → "Validating tracker access..."
- `SymphonyPulsingDotView` with teal accent
- `.symphonyStaggerIn()` on elements

### SymphonyStartupErrorView

- Coral error icon (`exclamationmark.triangle.fill`)
- Error message from `SymphonyFailureSummaryContract`
- "Retry" button (blue accent, `.symphonyCard()`)
- "Setup Workspace" secondary action
- `LinearGradient.symphonyBackground`

### SymphonyStartupDegradedBannerView

- Amber background at 10% opacity, amber border
- Warning icon + "1 of 2 workspace bindings failed"
- Dismissible (X button, `Motion.snappy`)
- Tappable to expand failure details

---

## Section 4: WorkspaceBindingSetupView

### New files in `Presentation/Views/Symphony/Setup/`

| File | Step | Content |
|------|------|---------|
| `SymphonyWorkspaceBindingSetupView.swift` | Container | Step navigation, back button, step dots |
| `SymphonySetupWelcomeStepView.swift` | Welcome | Branding, explanation, "Get Started" |
| `SymphonySetupTrackerSelectionStepView.swift` | Tracker | Selectable tracker cards (Linear) |
| `SymphonySetupAuthenticationStepView.swift` | Auth | Embed auth flow or show connected state |
| `SymphonySetupScopeSelectionStepView.swift` | Scope | Multi-select scope list from tracker API |
| `SymphonySetupConfirmationStepView.swift` | Confirm | Summary + "Connect" action |

### UX Flow

1. Welcome → 2. Tracker Selection → 3. Authentication → 4. Scope Selection → 5. Confirmation

### Design Aesthetic

- Centered content, max width ~480pt
- `.symphonyCard()` for selectable items, `.symphonyCard(selected: true)` for selected
- Blue accent primary buttons, tertiary secondary buttons
- Step transitions: `.asymmetric(insertion: .move(edge: .trailing), removal: .move(edge: .leading))`
- `.symphonyStaggerIn()` entrance animations

### Multi-Binding Support

- "Add Another Workspace" option on confirmation step
- Returns to step 2 with previous binding saved
- Confirmation shows stacked cards for all bindings
- "Done" finalizes and triggers startup gate re-check

### Repair Mode

- Skip welcome step
- Pre-select tracker kind from existing binding
- Show healthy vs failed bindings
- "Reconnect" action on failed bindings → auth step
- Healthy bindings shown as read-only cards

---

## Section 5: DI, Routing, Content Router (User-Implemented)

Instructions will be provided after sections 1-4 are complete. Covers:
- `SymphonyKanbanApp.swift` → replace `makeNavigationRoutes()` with `makeStartupGate()`
- `SymphonyUIDI.swift` → new `makeStartupGate()` and `makeWorkspaceBindingSetupView()` factories
- `SymphonyContentRouterView` → accept degraded state, render banner
- `SymphonyNavigationRoutes` → pass degraded state through from gate
