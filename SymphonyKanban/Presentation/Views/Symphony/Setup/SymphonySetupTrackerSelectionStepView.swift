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
