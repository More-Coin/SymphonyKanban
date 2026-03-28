import SwiftUI

public struct SymphonyAuthView: View {
    private let viewModel: SymphonyAuthViewModel
    private let onConnect: (SymphonyAuthServiceViewModel) -> Void
    private let onDisconnect: (SymphonyAuthServiceViewModel) -> Void
    @State private var appeared = false

    public init(
        viewModel: SymphonyAuthViewModel,
        onConnect: @escaping (SymphonyAuthServiceViewModel) -> Void = { _ in },
        onDisconnect: @escaping (SymphonyAuthServiceViewModel) -> Void = { _ in }
    ) {
        self.viewModel = viewModel
        self.onConnect = onConnect
        self.onDisconnect = onDisconnect
    }

    public var body: some View {
        ScrollView {
            VStack(spacing: SymphonyDesignStyle.Spacing.xxl) {
                header
                banner
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

            Text(viewModel.title)
                .font(SymphonyDesignStyle.Typography.largeTitle)
                .foregroundStyle(SymphonyDesignStyle.Text.primary)

            Text(viewModel.subtitle)
                .font(SymphonyDesignStyle.Typography.body)
                .foregroundStyle(SymphonyDesignStyle.Text.secondary)
                .multilineTextAlignment(.center)
                .frame(maxWidth: 400)
        }
        .symphonyStaggerIn(index: 0, isVisible: appeared)
    }

    private var banner: some View {
        Group {
            if let bannerMessage = viewModel.bannerMessage {
                HStack(spacing: SymphonyDesignStyle.Spacing.sm) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundStyle(SymphonyDesignStyle.Accent.coral)

                    Text(bannerMessage)
                        .font(SymphonyDesignStyle.Typography.caption)
                        .foregroundStyle(SymphonyDesignStyle.Text.secondary)

                    Spacer()
                }
                .padding(SymphonyDesignStyle.Spacing.md)
                .background(
                    RoundedRectangle(cornerRadius: SymphonyDesignStyle.Radius.md, style: .continuous)
                        .fill(SymphonyDesignStyle.Accent.coral.opacity(0.10))
                )
                .overlay(
                    RoundedRectangle(cornerRadius: SymphonyDesignStyle.Radius.md, style: .continuous)
                        .strokeBorder(SymphonyDesignStyle.Accent.coral.opacity(0.18), lineWidth: 0.5)
                )
                .symphonyStaggerIn(index: 1, isVisible: appeared)
            }
        }
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
                            statusColor(for: service)
                        )
                }

                Spacer()

                // Connection status dot
                Circle()
                    .fill(
                        statusColor(for: service)
                    )
                    .frame(width: 10, height: 10)
            }

            // Description
            Text(service.description)
                .font(SymphonyDesignStyle.Typography.body)
                .foregroundStyle(SymphonyDesignStyle.Text.secondary)

            SymphonyDividerView()

            serviceStateInfo(service)

            // Action Button
            actionButton(service)
        }
        .padding(SymphonyDesignStyle.Spacing.xl)
        .symphonyCard()
    }

    // MARK: - Connected Info

    private func connectedInfo(_ service: SymphonyAuthServiceViewModel) -> some View {
        VStack(alignment: .leading, spacing: SymphonyDesignStyle.Spacing.sm) {
            if let connectedAtLabel = service.connectedAtLabel {
                HStack(spacing: SymphonyDesignStyle.Spacing.sm) {
                    Image(systemName: "clock.arrow.circlepath")
                        .font(.system(size: 12))
                        .foregroundStyle(SymphonyDesignStyle.Text.tertiary)

                    Text(connectedAtLabel)
                        .font(SymphonyDesignStyle.Typography.caption)
                        .foregroundStyle(SymphonyDesignStyle.Text.tertiary)
                }
            }

            if let expiresAtLabel = service.expiresAtLabel {
                HStack(spacing: SymphonyDesignStyle.Spacing.sm) {
                    Image(systemName: "hourglass")
                        .font(.system(size: 12))
                        .foregroundStyle(SymphonyDesignStyle.Text.tertiary)

                    Text(expiresAtLabel)
                        .font(SymphonyDesignStyle.Typography.caption)
                        .foregroundStyle(SymphonyDesignStyle.Text.tertiary)
                }
            }

            HStack(spacing: SymphonyDesignStyle.Spacing.sm) {
                Image(systemName: "checkmark.shield.fill")
                    .font(.system(size: 12))
                    .foregroundStyle(SymphonyDesignStyle.Accent.green)

                Text(service.statusMessage)
                    .font(SymphonyDesignStyle.Typography.caption)
                    .foregroundStyle(SymphonyDesignStyle.Text.secondary)
            }
        }
    }

    private func serviceStateInfo(_ service: SymphonyAuthServiceViewModel) -> some View {
        if service.isConnected {
            return AnyView(connectedInfo(service))
        }

        return AnyView(disconnectedInfo(service))
    }

    private func disconnectedInfo(_ service: SymphonyAuthServiceViewModel) -> some View {
        VStack(alignment: .leading, spacing: SymphonyDesignStyle.Spacing.md) {
            Text(service.statusMessage)
                .font(SymphonyDesignStyle.Typography.body)
                .foregroundStyle(SymphonyDesignStyle.Text.secondary)

            HStack(spacing: SymphonyDesignStyle.Spacing.xs) {
                Image(systemName: "arrow.up.right.square")
                    .font(.system(size: 10))
                    .foregroundStyle(SymphonyDesignStyle.Accent.blue)

                Text(redirectHint(for: service))
                    .font(SymphonyDesignStyle.Typography.micro)
                    .foregroundStyle(SymphonyDesignStyle.Text.tertiary)
            }

            if let expiresAtLabel = service.expiresAtLabel {
                HStack(spacing: SymphonyDesignStyle.Spacing.xs) {
                    Image(systemName: "clock.badge.exclamationmark")
                        .font(.system(size: 10))
                        .foregroundStyle(SymphonyDesignStyle.Accent.coral)

                    Text(expiresAtLabel)
                        .font(SymphonyDesignStyle.Typography.micro)
                        .foregroundStyle(SymphonyDesignStyle.Text.tertiary)
                }
            }
        }
    }

    // MARK: - Action Button

    private func actionButton(_ service: SymphonyAuthServiceViewModel) -> some View {
        HStack {
            Spacer()
            Button {
                if service.isConnected {
                    onDisconnect(service)
                } else {
                    onConnect(service)
                }
            } label: {
                Text(service.actionLabel)
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
            .disabled(service.isActionEnabled == false)
            .opacity(service.isActionEnabled ? 1 : 0.65)
        }
    }

    private func statusColor(
        for service: SymphonyAuthServiceViewModel
    ) -> Color {
        switch service.state {
        case .connected:
            return SymphonyDesignStyle.Accent.green
        case .staleSession:
            return SymphonyDesignStyle.Accent.coral
        case .connecting:
            return SymphonyDesignStyle.Accent.blue
        case .disconnected:
            return SymphonyDesignStyle.Text.tertiary
        }
    }

    private func redirectHint(
        for service: SymphonyAuthServiceViewModel
    ) -> String {
        switch service.state {
        case .connecting:
            return "Finish the redirect flow in your browser, then return to Symphony."
        case .staleSession:
            return "Reconnect in the browser to replace the stored session."
        case .disconnected:
            return "Connect opens \(service.name) in your browser and completes through the localhost callback listener."
        case .connected:
            return ""
        }
    }
}

extension SymphonyAuthView {
    static var mockViewModel: SymphonyAuthViewModel {
        SymphonyAuthViewModel(
            title: "Linear Connection",
            subtitle: "Authorize Linear in your browser and let Symphony manage the localhost callback.",
            services: [
            SymphonyAuthServiceViewModel(
                id: "linear",
                name: "Linear",
                icon: "rectangle.3.group",
                description: "Connect Linear to sync issues and keep Symphony's issue reads on OAuth-backed bearer auth.",
                state: .connected,
                statusLabel: "Connected",
                statusMessage: "Connected to Linear.",
                actionLabel: "Disconnect",
                connectedAtLabel: "Connected 2 minutes ago",
                expiresAtLabel: nil,
                accountLabel: nil,
                isActionEnabled: true
            )
        ]
        )
    }
}

#Preview {
    SymphonyAuthView(viewModel: SymphonyAuthView.mockViewModel)
        .frame(width: 600, height: 800)
        .background(SymphonyDesignStyle.Background.primary)
}
