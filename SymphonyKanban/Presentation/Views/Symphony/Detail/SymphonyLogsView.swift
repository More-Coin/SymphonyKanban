import SwiftUI

public struct SymphonyLogsView: View {
    private let viewModel: SymphonyLogsViewModel

    public init(viewModel: SymphonyLogsViewModel) {
        self.viewModel = viewModel
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: SymphonyDesignStyle.Spacing.md) {
            // Header
            HStack(alignment: .center) {
                Image(systemName: "doc.text")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(SymphonyDesignStyle.Accent.amber)

                Text(viewModel.title)
                    .font(SymphonyDesignStyle.Typography.title3)
                    .foregroundStyle(SymphonyDesignStyle.Text.primary)

                Spacer()
            }

            Text(viewModel.subtitle)
                .font(SymphonyDesignStyle.Typography.caption)
                .foregroundStyle(SymphonyDesignStyle.Text.tertiary)

            if viewModel.entries.isEmpty {
                HStack(spacing: SymphonyDesignStyle.Spacing.sm) {
                    Image(systemName: "tray")
                        .font(.system(size: 11))
                        .foregroundStyle(SymphonyDesignStyle.Text.tertiary)
                    Text(viewModel.emptyState)
                        .font(SymphonyDesignStyle.Typography.caption)
                        .foregroundStyle(SymphonyDesignStyle.Text.tertiary)
                }
                .padding(.vertical, SymphonyDesignStyle.Spacing.sm)
            } else {
                VStack(spacing: SymphonyDesignStyle.Spacing.sm) {
                    ForEach(viewModel.entries) { entry in
                        logEntryRow(entry)
                    }
                }
            }
        }
        .padding(SymphonyDesignStyle.Spacing.lg)
        .symphonyCard()
    }

    private func logEntryRow(_ entry: SymphonyLogsViewModel.Entry) -> some View {
        HStack(spacing: SymphonyDesignStyle.Spacing.md) {
            Image(systemName: "doc.text.fill")
                .font(.system(size: 12, weight: .medium))
                .foregroundStyle(SymphonyDesignStyle.Accent.amber.opacity(0.7))
                .frame(width: 20, alignment: .center)

            VStack(alignment: .leading, spacing: SymphonyDesignStyle.Spacing.xxs) {
                Text(entry.label)
                    .font(SymphonyDesignStyle.Typography.headline)
                    .foregroundStyle(SymphonyDesignStyle.Text.primary)

                Text(entry.subtitle)
                    .font(SymphonyDesignStyle.Typography.code)
                    .foregroundStyle(SymphonyDesignStyle.Text.tertiary)
                    .textSelection(.enabled)
                    .lineLimit(1)
                    .truncationMode(.middle)

                if let destination = entry.destination {
                    Text(destination)
                        .font(SymphonyDesignStyle.Typography.micro)
                        .foregroundStyle(SymphonyDesignStyle.Accent.blue)
                        .textSelection(.enabled)
                }
            }

            Spacer()

            Image(systemName: "chevron.right")
                .font(.system(size: 9, weight: .semibold))
                .foregroundStyle(SymphonyDesignStyle.Text.tertiary)
        }
        .padding(SymphonyDesignStyle.Spacing.md)
        .background(
            RoundedRectangle(cornerRadius: SymphonyDesignStyle.Radius.md, style: .continuous)
                .fill(SymphonyDesignStyle.Background.elevated.opacity(0.5))
        )
        .overlay(
            RoundedRectangle(cornerRadius: SymphonyDesignStyle.Radius.md, style: .continuous)
                .strokeBorder(SymphonyDesignStyle.Border.subtle, lineWidth: 0.5)
        )
        .contentShape(Rectangle())
    }
}

#Preview {
    SymphonyLogsView(
        viewModel: SymphonyLogsViewModel(
            title: "Logs",
            subtitle: "Codex session output captured for this issue.",
            emptyState: "No log files are attached to this issue.",
            entries: [
                SymphonyLogsViewModel.Entry(
                    label: "Console",
                    subtitle: "/tmp/symphony/logs/KAN-142-console.log",
                    destination: "file:///tmp/symphony/logs/KAN-142-console.log"
                ),
                SymphonyLogsViewModel.Entry(
                    label: "Structured Events",
                    subtitle: "/tmp/symphony/logs/KAN-142-events.jsonl",
                    destination: nil
                )
            ]
        )
    )
    .padding()
    .background(SymphonyDesignStyle.Background.secondary)
}
