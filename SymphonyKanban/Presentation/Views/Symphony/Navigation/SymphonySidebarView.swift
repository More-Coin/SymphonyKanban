import SwiftUI

// MARK: - SymphonySidebarView

public struct SymphonySidebarView: View {
    @Binding var selectedTab: SymphonyTabViewModel
    let isLinearConnected: Bool
    let isCodexConnected: Bool
    let onIntegrationTapped: (String) -> Void
    let onSettingsTapped: () -> Void

    @State private var hoveredTab: SymphonyTabViewModel?
    @State private var appeared = false

    public init(
        selectedTab: Binding<SymphonyTabViewModel>,
        isLinearConnected: Bool,
        isCodexConnected: Bool,
        onIntegrationTapped: @escaping (String) -> Void = { _ in },
        onSettingsTapped: @escaping () -> Void = {}
    ) {
        self._selectedTab = selectedTab
        self.isLinearConnected = isLinearConnected
        self.isCodexConnected = isCodexConnected
        self.onIntegrationTapped = onIntegrationTapped
        self.onSettingsTapped = onSettingsTapped
    }

    public var body: some View {
        VStack(spacing: 0) {
            appHeader
            navigationTabs
            integrationsDivider
            integrationsSection
            Spacer()
            bottomStatus
        }
        .background(SymphonyDesignStyle.Background.sidebar.ignoresSafeArea())
        .onAppear {
            withAnimation(SymphonyDesignStyle.Motion.gentle) {
                appeared = true
            }
        }
    }

    // MARK: - App Header

    private var appHeader: some View {
        HStack(spacing: SymphonyDesignStyle.Spacing.sm) {
            Image(systemName: "waveform.circle.fill")
                .font(.system(size: 22, weight: .medium))
                .foregroundStyle(SymphonyDesignStyle.Accent.teal)
                .symbolRenderingMode(.hierarchical)

            Text("Symphony")
                .font(SymphonyDesignStyle.Typography.title)
                .foregroundStyle(SymphonyDesignStyle.Text.primary)

            Spacer()
        }
        .padding(.horizontal, SymphonyDesignStyle.Spacing.lg)
        .padding(.top, SymphonyDesignStyle.Spacing.lg)
        .padding(.bottom, SymphonyDesignStyle.Spacing.xl)
    }

    // MARK: - Navigation Tabs

    private var navigationTabs: some View {
        VStack(spacing: SymphonyDesignStyle.Spacing.xxs) {
            ForEach(Array(SymphonyTabViewModel.allCases.enumerated()), id: \.element.id) { index, tab in
                sidebarTabItem(tab, index: index)
            }
        }
        .padding(.horizontal, SymphonyDesignStyle.Spacing.sm)
    }

    private func sidebarTabItem(_ tab: SymphonyTabViewModel, index: Int) -> some View {
        let isSelected = selectedTab == tab
        let isHovered = hoveredTab == tab

        return Button {
            withAnimation(SymphonyDesignStyle.Motion.snappy) {
                selectedTab = tab
            }
        } label: {
            HStack(spacing: SymphonyDesignStyle.Spacing.md) {
                Image(systemName: tab.icon)
                    .font(.system(size: SymphonyDesignStyle.Sidebar.iconSize, weight: isSelected ? .semibold : .regular))
                    .foregroundStyle(isSelected ? SymphonyDesignStyle.Accent.teal : SymphonyDesignStyle.Text.secondary)
                    .frame(width: 22)

                Text(tab.rawValue)
                    .font(SymphonyDesignStyle.Typography.headline)
                    .foregroundStyle(isSelected ? SymphonyDesignStyle.Text.primary : SymphonyDesignStyle.Text.secondary)

                Spacer()

                if tab == .board {
                    Text("3")
                        .font(SymphonyDesignStyle.Typography.micro)
                        .foregroundStyle(SymphonyDesignStyle.Accent.teal)
                        .padding(.horizontal, 5)
                        .padding(.vertical, 2)
                        .background(
                            Capsule().fill(SymphonyDesignStyle.Accent.teal.opacity(0.14))
                        )
                }
            }
            .padding(.horizontal, SymphonyDesignStyle.Spacing.md)
            .frame(height: SymphonyDesignStyle.Sidebar.itemHeight)
            .background(
                RoundedRectangle(cornerRadius: SymphonyDesignStyle.Radius.sm, style: .continuous)
                    .fill(isSelected
                        ? SymphonyDesignStyle.Accent.teal.opacity(0.10)
                        : isHovered
                            ? Color.white.opacity(0.04)
                            : Color.clear
                    )
            )
            .overlay(
                RoundedRectangle(cornerRadius: SymphonyDesignStyle.Radius.sm, style: .continuous)
                    .strokeBorder(
                        isSelected ? SymphonyDesignStyle.Accent.teal.opacity(0.18) : Color.clear,
                        lineWidth: 0.5
                    )
            )
        }
        .buttonStyle(.plain)
        .onHover { hovering in
            withAnimation(SymphonyDesignStyle.Motion.stiffSnap) {
                hoveredTab = hovering ? tab : nil
            }
        }
        .symphonyStaggerIn(index: index, isVisible: appeared)
    }

    // MARK: - Integrations

    private var integrationsDivider: some View {
        SymphonyDividerView()
            .padding(.horizontal, SymphonyDesignStyle.Spacing.lg)
            .padding(.vertical, SymphonyDesignStyle.Spacing.xl)
    }

    private var integrationsSection: some View {
        VStack(alignment: .leading, spacing: SymphonyDesignStyle.Spacing.md) {
            Text("INTEGRATIONS")
                .font(SymphonyDesignStyle.Typography.micro)
                .foregroundStyle(SymphonyDesignStyle.Text.tertiary)
                .tracking(1.0)
                .padding(.horizontal, SymphonyDesignStyle.Spacing.lg)

            VStack(spacing: SymphonyDesignStyle.Spacing.sm) {
                integrationRow(
                    icon: "link",
                    service: "Linear",
                    isConnected: isLinearConnected
                ) {
                    onIntegrationTapped("Linear")
                }
                integrationRow(
                    icon: "terminal",
                    service: "Codex",
                    isConnected: isCodexConnected
                ) {
                    onIntegrationTapped("Codex")
                }
            }
            .padding(.horizontal, SymphonyDesignStyle.Spacing.sm)
        }
    }

    private func integrationRow(
        icon: String,
        service: String,
        isConnected: Bool,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            HStack(spacing: SymphonyDesignStyle.Spacing.md) {
                Image(systemName: icon)
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(isConnected ? SymphonyDesignStyle.Accent.green : SymphonyDesignStyle.Text.tertiary)
                    .frame(width: 22)

                Text(service)
                    .font(SymphonyDesignStyle.Typography.body)
                    .foregroundStyle(SymphonyDesignStyle.Text.secondary)

                Spacer()

                Circle()
                    .fill(isConnected ? SymphonyDesignStyle.Accent.green : SymphonyDesignStyle.Text.tertiary.opacity(0.5))
                    .frame(width: 6, height: 6)
            }
            .padding(.horizontal, SymphonyDesignStyle.Spacing.md)
            .frame(height: SymphonyDesignStyle.Sidebar.itemHeight)
        }
        .buttonStyle(.plain)
    }

    // MARK: - Bottom Status

    private var bottomStatus: some View {
        VStack(spacing: SymphonyDesignStyle.Spacing.sm) {
            SymphonyDividerView()

            HStack(spacing: SymphonyDesignStyle.Spacing.sm) {
                SymphonyPulsingDotView(color: SymphonyDesignStyle.Accent.green)
                Text("System Active")
                    .font(SymphonyDesignStyle.Typography.caption)
                    .foregroundStyle(SymphonyDesignStyle.Text.tertiary)
                Spacer()

                SymphonyIconButtonView(icon: "gearshape", label: "Settings", action: onSettingsTapped)
            }
            .padding(.horizontal, SymphonyDesignStyle.Spacing.lg)
            .padding(.bottom, SymphonyDesignStyle.Spacing.md)
        }
    }
}

#Preview {
    SymphonySidebarView(
        selectedTab: .constant(.board),
        isLinearConnected: true,
        isCodexConnected: false,
        onIntegrationTapped: { _ in },
        onSettingsTapped: {}
    )
    .frame(width: 220, height: 600)
}
