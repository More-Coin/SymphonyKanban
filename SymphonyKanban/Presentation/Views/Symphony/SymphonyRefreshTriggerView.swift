import SwiftUI

public struct SymphonyRefreshTriggerView: View {
    private let viewModel: SymphonyRefreshTriggerViewModel
    private let onRefreshTapped: () -> Void

    public init(
        viewModel: SymphonyRefreshTriggerViewModel,
        onRefreshTapped: @escaping () -> Void = {}
    ) {
        self.viewModel = viewModel
        self.onRefreshTapped = onRefreshTapped
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            header
            content
            actionRow
        }
        .padding(20)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(backgroundFill)
        .overlay(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .strokeBorder(.white.opacity(0.10), lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
    }

    private var header: some View {
        HStack(alignment: .firstTextBaseline, spacing: 12) {
            VStack(alignment: .leading, spacing: 6) {
                Text(viewModel.title)
                    .font(.title3.weight(.semibold))
                Text(viewModel.subtitle)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            Spacer(minLength: 12)

            statusBadge
        }
    }

    private var content: some View {
        VStack(alignment: .leading, spacing: 8) {
            labelRow(text: viewModel.sourceLabel)
            if let lastRefreshLabel = viewModel.lastRefreshLabel {
                labelRow(text: lastRefreshLabel)
            }
            if let noteLabel = viewModel.noteLabel {
                labelRow(text: noteLabel)
            }
        }
    }

    private var actionRow: some View {
        HStack {
            Button(action: onRefreshTapped) {
                Label(viewModel.primaryActionTitle, systemImage: "arrow.clockwise")
                    .labelStyle(.titleAndIcon)
            }
            .buttonStyle(.borderedProminent)
            .disabled(!viewModel.isPrimaryActionEnabled)
            .accessibilityLabel(viewModel.primaryActionAccessibilityLabel)

            Spacer(minLength: 12)

            if viewModel.isRefreshing {
                ProgressView()
                    .controlSize(.small)
            }
        }
    }

    private var statusBadge: some View {
        Text(viewModel.statusLabel)
            .font(.caption.weight(.semibold))
            .textCase(.uppercase)
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(
                Capsule(style: .continuous)
                    .fill(viewModel.isRefreshing ? Color.orange.opacity(0.18) : Color.green.opacity(0.18))
            )
            .foregroundStyle(viewModel.isRefreshing ? Color.orange : Color.green)
    }

    private func labelRow(text: String) -> some View {
        HStack(alignment: .firstTextBaseline, spacing: 8) {
            Circle()
                .fill(.secondary.opacity(0.45))
                .frame(width: 6, height: 6)
            Text(text)
                .font(.footnote)
                .foregroundStyle(.secondary)
            Spacer(minLength: 0)
        }
    }

    private var backgroundFill: some View {
        RoundedRectangle(cornerRadius: 20, style: .continuous)
            .fill(
                LinearGradient(
                    colors: [
                        Color(red: 0.12, green: 0.17, blue: 0.24),
                        Color(red: 0.07, green: 0.10, blue: 0.14)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
    }
}

#Preview("Refresh idle") {
    SymphonyRefreshTriggerView(
        viewModel: SymphonyRefreshTriggerViewModel(
            title: "Symphony Refresh",
            subtitle: "Refresh the Symphony runtime data before reviewing the next change.",
            sourceLabel: "Triggered from dashboard",
            statusLabel: "Ready",
            lastRefreshLabel: "Last refreshed 5 minutes ago",
            noteLabel: "Note: Manual refresh requested by the user.",
            primaryActionTitle: "Refresh now",
            primaryActionAccessibilityLabel: "Refresh Symphony runtime data",
            isRefreshing: false,
            isPrimaryActionEnabled: true
        )
    )
    .padding()
    .background(Color.black.opacity(0.92))
}

#Preview("Refreshing") {
    SymphonyRefreshTriggerView(
        viewModel: SymphonyRefreshTriggerViewModel(
            title: "Symphony Refresh",
            subtitle: "Refreshing Symphony runtime data.",
            sourceLabel: "Triggered from issue detail",
            statusLabel: "Refreshing",
            lastRefreshLabel: "Last refreshed just now",
            noteLabel: nil,
            primaryActionTitle: "Refreshing...",
            primaryActionAccessibilityLabel: "Refresh Symphony runtime data in progress",
            isRefreshing: true,
            isPrimaryActionEnabled: false
        )
    )
    .padding()
    .background(Color.black.opacity(0.92))
}
