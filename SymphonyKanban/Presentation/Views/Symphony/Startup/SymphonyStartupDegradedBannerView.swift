import SwiftUI

// MARK: - SymphonyStartupDegradedBannerView
/// Compact amber banner shown when some workspace bindings failed
/// but at least one binding remains healthy.

public struct SymphonyStartupDegradedBannerView: View {
    let failedBindingCount: Int
    let activeBindingCount: Int
    let onDismiss: () -> Void
    let onTap: () -> Void

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

// MARK: - Preview

#Preview("Degraded Banner") {
    VStack {
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
