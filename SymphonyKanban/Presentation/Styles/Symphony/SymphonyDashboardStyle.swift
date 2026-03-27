import SwiftUI

public enum SymphonyDashboardStyle {
    public static let pagePadding: CGFloat = 24
    public static let panelCornerRadius: CGFloat = 24
    public static let pageBackground = LinearGradient(
        colors: [
            Color(red: 0.94, green: 0.92, blue: 0.87),
            Color(red: 0.86, green: 0.90, blue: 0.88),
            Color(red: 0.75, green: 0.84, blue: 0.86)
        ],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
    public static let panelBackground = LinearGradient(
        colors: [
            Color(red: 0.08, green: 0.14, blue: 0.18),
            Color(red: 0.05, green: 0.08, blue: 0.11)
        ],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
    public static let accent = Color(red: 0.97, green: 0.54, blue: 0.28)
    public static let secondaryAccent = Color(red: 0.38, green: 0.78, blue: 0.67)
    public static let surfaceBorder = Color.white.opacity(0.10)
    public static let surfaceOverlay = Color.white.opacity(0.05)

    public static func rowBackground(isSelected: Bool) -> Color {
        isSelected ? accent.opacity(0.18) : Color.white.opacity(0.04)
    }
}
