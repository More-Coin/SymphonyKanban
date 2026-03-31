import SwiftUI

// MARK: - SymphonyKanbanCardUpdatingOverlayView
/// A lightweight overlay shown on cards that are mid-mutation.
/// Dims the card content and displays a centered progress spinner.

public struct SymphonyKanbanCardUpdatingOverlayView: View {
    public var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: SymphonyDesignStyle.Radius.lg, style: .continuous)
                .fill(.black.opacity(0.25))

            VStack(spacing: SymphonyDesignStyle.Spacing.xs) {
                ProgressView()
                    .controlSize(.small)
                Text("Updating…")
                    .font(SymphonyDesignStyle.Typography.caption)
                    .foregroundStyle(.white)
            }
        }
    }
}
