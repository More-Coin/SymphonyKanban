import SwiftUI

// MARK: - SymphonyIssueListSectionHeaderView
/// Section header for grouped mode in the issue list.

public struct SymphonyIssueListSectionHeaderView: View {
    let section: SymphonyIssueListSectionViewModel
    let showHeader: Bool

    public init(
        section: SymphonyIssueListSectionViewModel,
        showHeader: Bool
    ) {
        self.section = section
        self.showHeader = showHeader
    }

    public var body: some View {
        if showHeader {
            titleContent
        }

        if let errorMessage = section.errorMessage,
           errorMessage.isEmpty == false {
            errorRow(errorMessage)
        }
    }

    // MARK: - Private

    @ViewBuilder
    private var titleContent: some View {
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
