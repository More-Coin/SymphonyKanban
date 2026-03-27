import SwiftUI

// MARK: - SymphonyAuthView
/// Login/connection view for Linear and Codex integrations.
/// Displays service cards with connect/disconnect actions and stub API key fields.

public struct SymphonyAuthView: View {
    @State private var viewModel = SymphonyAuthView.mockViewModel
    @State private var appeared = false
    @State private var tokenInputs: [String: String] = [:]

    public init() {}

    public var body: some View {
        ScrollView {
            VStack(spacing: SymphonyDesignStyle.Spacing.xxl) {
                header
                serviceCards
            }
            .frame(maxWidth: 500)
            .padding(SymphonyDesignStyle.Spacing.xxxl)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(SymphonyDesignStyle.Background.secondary)
        .onAppear {
            withAnimation(SymphonyDesignStyle.Motion.gentle) {
                appeared = true
            }
        }
    }

    // MARK: - Header

    private var header: some View {
        VStack(spacing: SymphonyDesignStyle.Spacing.sm) {
            Image(systemName: "link.badge.plus")
                .font(.system(size: 36, weight: .light))
                .foregroundStyle(SymphonyDesignStyle.Accent.blue)
                .padding(.bottom, SymphonyDesignStyle.Spacing.sm)

            Text("Connect Your Services")
                .font(SymphonyDesignStyle.Typography.largeTitle)
                .foregroundStyle(SymphonyDesignStyle.Text.primary)

            Text("Link your project management and code execution tools to enable Symphony's agent-driven workflow.")
                .font(SymphonyDesignStyle.Typography.body)
                .foregroundStyle(SymphonyDesignStyle.Text.secondary)
                .multilineTextAlignment(.center)
                .frame(maxWidth: 400)
        }
        .symphonyStaggerIn(index: 0, isVisible: appeared)
    }

    // MARK: - Service Cards

    private var serviceCards: some View {
        VStack(spacing: SymphonyDesignStyle.Spacing.lg) {
            ForEach(Array(viewModel.services.enumerated()), id: \.element.id) { index, service in
                serviceCard(service)
                    .symphonyStaggerIn(index: index + 1, isVisible: appeared)
            }
        }
    }

    // MARK: - Service Card

    private func serviceCard(_ service: SymphonyAuthServiceViewModel) -> some View {
        VStack(alignment: .leading, spacing: SymphonyDesignStyle.Spacing.lg) {
            // Icon + Name + Status
            HStack(spacing: SymphonyDesignStyle.Spacing.md) {
                ZStack {
                    RoundedRectangle(cornerRadius: SymphonyDesignStyle.Radius.md, style: .continuous)
                        .fill(SymphonyDesignStyle.Accent.blue.opacity(0.10))
                        .frame(width: 48, height: 48)

                    Image(systemName: service.icon)
                        .font(.system(size: 22, weight: .medium))
                        .foregroundStyle(SymphonyDesignStyle.Accent.blue)
                }

                VStack(alignment: .leading, spacing: SymphonyDesignStyle.Spacing.xxs) {
                    Text(service.name)
                        .font(SymphonyDesignStyle.Typography.title3)
                        .foregroundStyle(SymphonyDesignStyle.Text.primary)

                    Text(service.statusLabel)
                        .font(SymphonyDesignStyle.Typography.caption)
                        .foregroundStyle(
                            service.isConnected
                                ? SymphonyDesignStyle.Accent.green
                                : SymphonyDesignStyle.Text.tertiary
                        )
                }

                Spacer()

                // Connection status dot
                Circle()
                    .fill(
                        service.isConnected
                            ? SymphonyDesignStyle.Accent.green
                            : SymphonyDesignStyle.Text.tertiary
                    )
                    .frame(width: 10, height: 10)
            }

            // Description
            Text(service.description)
                .font(SymphonyDesignStyle.Typography.body)
                .foregroundStyle(SymphonyDesignStyle.Text.secondary)

            SymphonyDividerView()

            // API Key Input or Last Sync
            if service.isConnected {
                connectedInfo(service)
            } else {
                disconnectedForm(service)
            }

            // Action Button
            actionButton(service)
        }
        .padding(SymphonyDesignStyle.Spacing.xl)
        .symphonyCard()
    }

    // MARK: - Connected Info

    private func connectedInfo(_ service: SymphonyAuthServiceViewModel) -> some View {
        VStack(alignment: .leading, spacing: SymphonyDesignStyle.Spacing.sm) {
            if let syncTime = service.lastSyncTime {
                HStack(spacing: SymphonyDesignStyle.Spacing.sm) {
                    Image(systemName: "clock.arrow.circlepath")
                        .font(.system(size: 12))
                        .foregroundStyle(SymphonyDesignStyle.Text.tertiary)

                    Text("Last synced \(syncTime)")
                        .font(SymphonyDesignStyle.Typography.caption)
                        .foregroundStyle(SymphonyDesignStyle.Text.tertiary)
                }
            }

            HStack(spacing: SymphonyDesignStyle.Spacing.sm) {
                Image(systemName: "checkmark.shield.fill")
                    .font(.system(size: 12))
                    .foregroundStyle(SymphonyDesignStyle.Accent.green)

                Text("Authorized and active")
                    .font(SymphonyDesignStyle.Typography.caption)
                    .foregroundStyle(SymphonyDesignStyle.Text.secondary)
            }
        }
    }

    // MARK: - Disconnected Form

    private func disconnectedForm(_ service: SymphonyAuthServiceViewModel) -> some View {
        VStack(alignment: .leading, spacing: SymphonyDesignStyle.Spacing.md) {
            Text("API Token")
                .font(SymphonyDesignStyle.Typography.caption)
                .foregroundStyle(SymphonyDesignStyle.Text.secondary)

            SecureField("Enter your \(service.name) API token", text: tokenBinding(for: service.id))
                .textFieldStyle(.plain)
                .font(SymphonyDesignStyle.Typography.body)
                .foregroundStyle(SymphonyDesignStyle.Text.primary)
                .padding(.horizontal, SymphonyDesignStyle.Spacing.md)
                .padding(.vertical, SymphonyDesignStyle.Spacing.sm)
                .background(
                    RoundedRectangle(cornerRadius: SymphonyDesignStyle.Radius.sm, style: .continuous)
                        .fill(SymphonyDesignStyle.Background.primary)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: SymphonyDesignStyle.Radius.sm, style: .continuous)
                        .strokeBorder(SymphonyDesignStyle.Border.default, lineWidth: 0.5)
                )

            HStack(spacing: SymphonyDesignStyle.Spacing.xs) {
                Image(systemName: "arrow.up.right.square")
                    .font(.system(size: 10))
                    .foregroundStyle(SymphonyDesignStyle.Accent.blue)

                Text("You'll be redirected to \(service.name) to authorize")
                    .font(SymphonyDesignStyle.Typography.micro)
                    .foregroundStyle(SymphonyDesignStyle.Text.tertiary)
            }
        }
    }

    // MARK: - Action Button

    private func actionButton(_ service: SymphonyAuthServiceViewModel) -> some View {
        HStack {
            Spacer()
            Button {} label: {
                Text(service.isConnected ? "Disconnect" : "Connect")
                    .font(SymphonyDesignStyle.Typography.callout)
                    .fontWeight(.semibold)
                    .foregroundStyle(
                        service.isConnected
                            ? SymphonyDesignStyle.Accent.coral
                            : .white
                    )
                    .padding(.horizontal, SymphonyDesignStyle.Spacing.xl)
                    .padding(.vertical, SymphonyDesignStyle.Spacing.sm)
                    .background(
                        RoundedRectangle(cornerRadius: SymphonyDesignStyle.Radius.sm, style: .continuous)
                            .fill(
                                service.isConnected
                                    ? SymphonyDesignStyle.Accent.coral.opacity(0.12)
                                    : SymphonyDesignStyle.Accent.blue
                            )
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: SymphonyDesignStyle.Radius.sm, style: .continuous)
                            .strokeBorder(
                                service.isConnected
                                    ? SymphonyDesignStyle.Accent.coral.opacity(0.25)
                                    : Color.clear,
                                lineWidth: 0.5
                            )
                    )
            }
            .buttonStyle(.plain)
        }
    }

    // MARK: - Helpers

    private func tokenBinding(for serviceID: String) -> Binding<String> {
        Binding(
            get: { tokenInputs[serviceID] ?? "" },
            set: { tokenInputs[serviceID] = $0 }
        )
    }
}

// MARK: - Mock Data

extension SymphonyAuthView {
    static var mockViewModel: SymphonyAuthViewModel {
        SymphonyAuthViewModel(services: [
            SymphonyAuthServiceViewModel(
                id: "linear",
                name: "Linear",
                icon: "rectangle.3.group",
                description: "Connect to Linear to sync issues, track status changes, and enable agent-driven triage across your projects.",
                isConnected: true,
                statusLabel: "Connected",
                lastSyncTime: "2 minutes ago"
            ),
            SymphonyAuthServiceViewModel(
                id: "codex",
                name: "Codex",
                icon: "terminal",
                description: "Connect to Codex to enable AI agent code execution, automated builds, and real-time session monitoring.",
                isConnected: false,
                statusLabel: "Not connected",
                lastSyncTime: nil
            )
        ])
    }
}

#Preview {
    SymphonyAuthView()
        .frame(width: 600, height: 800)
        .background(SymphonyDesignStyle.Background.primary)
}
