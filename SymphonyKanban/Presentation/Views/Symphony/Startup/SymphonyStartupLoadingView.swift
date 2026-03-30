import SwiftUI

// MARK: - SymphonyStartupLoadingView
/// Loading screen shown while the startup gate resolves workspace bindings
/// and validates tracker access.
public struct SymphonyStartupLoadingView: View {
    @State private var appeared = false
    @State private var statusIndex = 0

    private var statusMessage: String {
        switch statusIndex {
        case 0:
            return "Checking saved workspace bindings..."
        default:
            return "Validating tracker access..."
        }
    }

    public var body: some View {
        ZStack {
            LinearGradient.symphonyBackground
                .ignoresSafeArea()

            VStack(spacing: SymphonyDesignStyle.Spacing.xl) {
                Image(systemName: "arrow.triangle.2.circlepath")
                    .font(.system(size: 40, weight: .light))
                    .foregroundStyle(SymphonyDesignStyle.Accent.teal)
                    .symphonyStaggerIn(index: 0, isVisible: appeared)

                Text("Symphony")
                    .font(SymphonyDesignStyle.Typography.largeTitle)
                    .foregroundStyle(SymphonyDesignStyle.Text.primary)
                    .symphonyStaggerIn(index: 1, isVisible: appeared)

                HStack(spacing: SymphonyDesignStyle.Spacing.sm) {
                    SymphonyPulsingDotView(color: SymphonyDesignStyle.Accent.teal)

                    Text(statusMessage)
                        .font(SymphonyDesignStyle.Typography.body)
                        .foregroundStyle(SymphonyDesignStyle.Text.secondary)
                }
                .symphonyStaggerIn(index: 2, isVisible: appeared)
            }
        }
        .onAppear {
            withAnimation(SymphonyDesignStyle.Motion.gentle) {
                appeared = true
            }

            DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) {
                withAnimation(SymphonyDesignStyle.Motion.smooth) {
                    statusIndex = 1
                }
            }
        }
    }
}

#Preview {
    SymphonyStartupLoadingView()
        .frame(width: 800, height: 600)
}
