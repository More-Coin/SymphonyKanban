import SwiftUI

// MARK: - SymphonyStatusBadgeView
/// Compact pill badge showing a status label with semantic color coding.
public struct SymphonyStatusBadgeView: View {
    let label: String
    let statusKey: String
    let size: BadgeSize

    public enum BadgeSize {
        case small, regular

        var font: Font {
            switch self {
            case .small: return SymphonyDesignStyle.Typography.micro
            case .regular: return SymphonyDesignStyle.Typography.caption
            }
        }
        var hPad: CGFloat {
            switch self {
            case .small: return 6
            case .regular: return 10
            }
        }
        var vPad: CGFloat {
            switch self {
            case .small: return 3
            case .regular: return 5
            }
        }
    }

    public init(_ label: String, statusKey: String, size: BadgeSize = .regular) {
        self.label = label
        self.statusKey = statusKey
        self.size = size
    }

    public var body: some View {
        let color = SymphonyDesignStyle.Status.color(for: statusKey)
        Text(label)
            .font(size.font)
            .fontWeight(.semibold)
            .foregroundStyle(color)
            .padding(.horizontal, size.hPad)
            .padding(.vertical, size.vPad)
            .background(
                Capsule(style: .continuous)
                    .fill(color.opacity(0.14))
            )
            .overlay(
                Capsule(style: .continuous)
                    .strokeBorder(color.opacity(0.20), lineWidth: 0.5)
            )
    }
}

// MARK: - SymphonyPriorityDotView
/// Small colored dot indicating priority level.
public struct SymphonyPriorityDotView: View {
    let level: Int
    let showLabel: Bool

    public init(level: Int, showLabel: Bool = false) {
        self.level = level
        self.showLabel = showLabel
    }

    public var body: some View {
        HStack(spacing: 5) {
            Circle()
                .fill(SymphonyDesignStyle.Priority.color(for: level))
                .frame(width: 8, height: 8)
            if showLabel {
                Text(SymphonyDesignStyle.Priority.label(for: level))
                    .font(SymphonyDesignStyle.Typography.caption)
                    .foregroundStyle(SymphonyDesignStyle.Text.secondary)
            }
        }
    }
}

// MARK: - SymphonyLabelChipView
/// Small tag/label chip for issue labels.
public struct SymphonyLabelChipView: View {
    let text: String
    let color: Color

    public init(_ text: String, color: Color = SymphonyDesignStyle.Accent.blue) {
        self.text = text
        self.color = color
    }

    public var body: some View {
        Text(text)
            .font(SymphonyDesignStyle.Typography.micro)
            .fontWeight(.medium)
            .foregroundStyle(color.opacity(0.85))
            .padding(.horizontal, 7)
            .padding(.vertical, 3)
            .background(
                RoundedRectangle(cornerRadius: SymphonyDesignStyle.Radius.xs, style: .continuous)
                    .fill(color.opacity(0.10))
            )
    }
}

// MARK: - SymphonyMetricTileView
/// Compact metric display tile for dashboards.
public struct SymphonyMetricTileView: View {
    let value: String
    let label: String
    let accentColor: Color

    public init(value: String, label: String, accentColor: Color = SymphonyDesignStyle.Accent.blue) {
        self.value = value
        self.label = label
        self.accentColor = accentColor
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(value)
                .font(SymphonyDesignStyle.Typography.title)
                .foregroundStyle(accentColor)
            Text(label)
                .font(SymphonyDesignStyle.Typography.caption)
                .foregroundStyle(SymphonyDesignStyle.Text.tertiary)
        }
        .padding(SymphonyDesignStyle.Spacing.md)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: SymphonyDesignStyle.Radius.md, style: .continuous)
                .fill(accentColor.opacity(0.06))
        )
        .overlay(
            RoundedRectangle(cornerRadius: SymphonyDesignStyle.Radius.md, style: .continuous)
                .strokeBorder(accentColor.opacity(0.12), lineWidth: 0.5)
        )
    }
}

// MARK: - SymphonyEmptyStateView
/// Placeholder for empty content areas.
public struct SymphonyEmptyStateView: View {
    let icon: String
    let title: String
    let message: String

    public init(icon: String = "tray", title: String, message: String) {
        self.icon = icon
        self.title = title
        self.message = message
    }

    public var body: some View {
        VStack(spacing: SymphonyDesignStyle.Spacing.md) {
            Image(systemName: icon)
                .font(.system(size: 32, weight: .light))
                .foregroundStyle(SymphonyDesignStyle.Text.tertiary)

            Text(title)
                .font(SymphonyDesignStyle.Typography.headline)
                .foregroundStyle(SymphonyDesignStyle.Text.secondary)

            Text(message)
                .font(SymphonyDesignStyle.Typography.body)
                .foregroundStyle(SymphonyDesignStyle.Text.tertiary)
                .multilineTextAlignment(.center)
                .frame(maxWidth: 280)
        }
        .padding(SymphonyDesignStyle.Spacing.xxxl)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

// MARK: - SymphonySectionHeaderView
/// Consistent section header with optional count badge.
public struct SymphonySectionHeaderView: View {
    let title: String
    let count: Int?
    let accentColor: Color

    public init(_ title: String, count: Int? = nil, accentColor: Color = SymphonyDesignStyle.Text.secondary) {
        self.title = title
        self.count = count
        self.accentColor = accentColor
    }

    public var body: some View {
        HStack(spacing: SymphonyDesignStyle.Spacing.sm) {
            Text(title)
                .font(SymphonyDesignStyle.Typography.caption)
                .fontWeight(.semibold)
                .foregroundStyle(SymphonyDesignStyle.Text.secondary)
                .textCase(.uppercase)
                .tracking(0.8)

            if let count {
                Text("\(count)")
                    .font(SymphonyDesignStyle.Typography.micro)
                    .fontWeight(.bold)
                    .foregroundStyle(accentColor)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(
                        Capsule(style: .continuous)
                            .fill(accentColor.opacity(0.14))
                    )
            }

            Spacer()
        }
    }
}

// MARK: - SymphonyPulsingDotView
/// Animated pulsing dot for active/running states.
public struct SymphonyPulsingDotView: View {
    let color: Color
    @State private var isPulsing = false

    public init(color: Color = SymphonyDesignStyle.Accent.teal) {
        self.color = color
    }

    public var body: some View {
        ZStack {
            Circle()
                .fill(color.opacity(0.3))
                .frame(width: 12, height: 12)
                .scaleEffect(isPulsing ? 1.6 : 1.0)
                .opacity(isPulsing ? 0 : 0.6)

            Circle()
                .fill(color)
                .frame(width: 8, height: 8)
        }
        .onAppear {
            withAnimation(
                .easeInOut(duration: 1.5)
                .repeatForever(autoreverses: false)
            ) {
                isPulsing = true
            }
        }
    }
}

// MARK: - SymphonyAgentAvatarView
/// Small avatar circle for agent representation.
public struct SymphonyAgentAvatarView: View {
    let name: String
    let color: Color
    let size: CGFloat

    public init(name: String, color: Color = SymphonyDesignStyle.Accent.indigo, size: CGFloat = 24) {
        self.name = name
        self.color = color
        self.size = size
    }

    private var initials: String {
        let parts = name.split(separator: " ")
        if parts.count >= 2 {
            return String(parts[0].prefix(1) + parts[1].prefix(1)).uppercased()
        }
        return String(name.prefix(2)).uppercased()
    }

    public var body: some View {
        ZStack {
            Circle()
                .fill(
                    LinearGradient(
                        colors: [color, color.opacity(0.7)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )

            Text(initials)
                .font(.system(size: size * 0.4, weight: .bold, design: .rounded))
                .foregroundStyle(.white)
        }
        .frame(width: size, height: size)
    }
}

// MARK: - SymphonyDividerView
/// Styled divider consistent with the design system.
public struct SymphonyDividerView: View {
    let opacity: Double

    public init(opacity: Double = 0.06) {
        self.opacity = opacity
    }

    public var body: some View {
        Rectangle()
            .fill(Color.white.opacity(opacity))
            .frame(height: 1)
    }
}

// MARK: - SymphonyIconButtonView
/// Consistent icon button style.
public struct SymphonyIconButtonView: View {
    let icon: String
    let label: String
    let color: Color
    let action: () -> Void

    public init(icon: String, label: String, color: Color = SymphonyDesignStyle.Text.secondary, action: @escaping () -> Void) {
        self.icon = icon
        self.label = label
        self.color = color
        self.action = action
    }

    public var body: some View {
        Button(action: action) {
            Image(systemName: icon)
                .font(.system(size: 14, weight: .medium))
                .foregroundStyle(color)
                .frame(width: 28, height: 28)
                .background(
                    RoundedRectangle(cornerRadius: SymphonyDesignStyle.Radius.sm, style: .continuous)
                        .fill(Color.white.opacity(0.04))
                )
                .overlay(
                    RoundedRectangle(cornerRadius: SymphonyDesignStyle.Radius.sm, style: .continuous)
                        .strokeBorder(Color.white.opacity(0.08), lineWidth: 0.5)
                )
        }
        .buttonStyle(.plain)
        .help(label)
    }
}

// MARK: - SymphonySearchFieldView
/// Styled search field for filtering.
public struct SymphonySearchFieldView: View {
    let placeholder: String
    @Binding var text: String

    public init(placeholder: String = "Search...", text: Binding<String>) {
        self.placeholder = placeholder
        self._text = text
    }

    public var body: some View {
        HStack(spacing: SymphonyDesignStyle.Spacing.sm) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 12, weight: .medium))
                .foregroundStyle(SymphonyDesignStyle.Text.tertiary)

            TextField(placeholder, text: $text)
                .textFieldStyle(.plain)
                .font(SymphonyDesignStyle.Typography.body)
                .foregroundStyle(SymphonyDesignStyle.Text.primary)

            if !text.isEmpty {
                Button {
                    text = ""
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 12))
                        .foregroundStyle(SymphonyDesignStyle.Text.tertiary)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, SymphonyDesignStyle.Spacing.md)
        .padding(.vertical, SymphonyDesignStyle.Spacing.sm)
        .background(
            RoundedRectangle(cornerRadius: SymphonyDesignStyle.Radius.sm, style: .continuous)
                .fill(SymphonyDesignStyle.Background.tertiary)
        )
        .overlay(
            RoundedRectangle(cornerRadius: SymphonyDesignStyle.Radius.sm, style: .continuous)
                .strokeBorder(SymphonyDesignStyle.Border.default, lineWidth: 0.5)
        )
    }
}

// MARK: - SymphonyConnectionIndicatorView
/// Shows connected/disconnected state for integrations.
public struct SymphonyConnectionIndicatorView: View {
    let service: String
    let isConnected: Bool

    public init(service: String, isConnected: Bool) {
        self.service = service
        self.isConnected = isConnected
    }

    public var body: some View {
        HStack(spacing: SymphonyDesignStyle.Spacing.sm) {
            Circle()
                .fill(isConnected ? SymphonyDesignStyle.Accent.green : SymphonyDesignStyle.Text.tertiary)
                .frame(width: 6, height: 6)

            Text(service)
                .font(SymphonyDesignStyle.Typography.caption)
                .foregroundStyle(SymphonyDesignStyle.Text.secondary)
        }
    }
}
