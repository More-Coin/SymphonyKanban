import SwiftUI

// MARK: - SymphonyDesignStyle
/// Design system for Symphony Kanban — "Obsidian Mission Control"
/// A dark, refined command-center aesthetic optimized for macOS with
/// vivid status-driven accent colors, native vibrancy, and spring animations.
public enum SymphonyDesignStyle {

    // MARK: - Background Hierarchy (darkest → lightest)

    public enum Background {
        /// Deepest layer — window chrome, sidebar
        public static let primary = Color(red: 0.05, green: 0.067, blue: 0.09)
        /// Main content area
        public static let secondary = Color(red: 0.082, green: 0.11, blue: 0.15)
        /// Card / panel surfaces
        public static let tertiary = Color(red: 0.11, green: 0.14, blue: 0.19)
        /// Elevated surfaces — hover states, popovers
        public static let elevated = Color(red: 0.14, green: 0.17, blue: 0.23)
        /// Sidebar tint (slightly cooler than primary)
        public static let sidebar = Color(red: 0.04, green: 0.055, blue: 0.078)
        /// Kanban column well
        public static let columnWell = Color(red: 0.065, green: 0.085, blue: 0.12)
    }

    // MARK: - Accent Palette

    public enum Accent {
        /// Primary action, links, active indicators
        public static let blue = Color(red: 0.33, green: 0.63, blue: 1.0)
        /// Success, completion
        public static let green = Color(red: 0.25, green: 0.78, blue: 0.42)
        /// Warning, retry, caution
        public static let amber = Color(red: 0.95, green: 0.68, blue: 0.22)
        /// Error, blocked, urgent
        public static let coral = Color(red: 0.97, green: 0.32, blue: 0.29)
        /// Review, medium priority, info
        public static let lavender = Color(red: 0.68, green: 0.52, blue: 1.0)
        /// In-progress, active work
        public static let teal = Color(red: 0.22, green: 0.80, blue: 0.73)
        /// Secondary action, indigo accent
        public static let indigo = Color(red: 0.40, green: 0.40, blue: 0.95)
    }

    // MARK: - Text Hierarchy

    public enum Text {
        public static let primary = Color.white.opacity(0.92)
        public static let secondary = Color.white.opacity(0.56)
        public static let tertiary = Color.white.opacity(0.30)
        public static let inverse = Color(red: 0.05, green: 0.067, blue: 0.09)
    }

    // MARK: - Borders

    public enum Border {
        public static let subtle = Color.white.opacity(0.04)
        public static let `default` = Color.white.opacity(0.08)
        public static let active = Color.white.opacity(0.16)
        public static let focus = Accent.blue.opacity(0.5)
    }

    // MARK: - Semantic Status Colors (Kanban column states)

    public enum Status {
        public static let backlog = Color.white.opacity(0.22)
        public static let ready = Accent.blue
        public static let inProgress = Accent.teal
        public static let blocked = Accent.coral
        public static let review = Accent.lavender
        public static let done = Accent.green
        public static let retrying = Accent.amber

        /// Map a status key string to its color
        public static func color(for key: String) -> Color {
            switch key.lowercased() {
            case "backlog": return backlog
            case "ready", "claimed": return ready
            case "in_progress", "inprogress", "doing", "running": return inProgress
            case "blocked", "retry_queued", "retryqueued": return blocked
            case "review": return review
            case "done", "completed": return done
            case "retrying", "retry": return retrying
            default: return backlog
            }
        }
    }

    // MARK: - Priority Colors

    public enum Priority {
        public static let urgent = Accent.coral
        public static let high = Accent.amber
        public static let medium = Accent.lavender
        public static let low = Color.white.opacity(0.35)
        public static let none = Color.white.opacity(0.18)

        /// Map a priority integer (1=urgent, 4=low) to its color
        public static func color(for level: Int) -> Color {
            switch level {
            case 1: return urgent
            case 2: return high
            case 3: return medium
            case 4: return low
            default: return none
            }
        }

        /// Map a priority integer to its label
        public static func label(for level: Int) -> String {
            switch level {
            case 1: return "Urgent"
            case 2: return "High"
            case 3: return "Medium"
            case 4: return "Low"
            default: return "None"
            }
        }
    }

    // MARK: - Spacing Scale

    public enum Spacing {
        public static let xxs: CGFloat = 2
        public static let xs: CGFloat = 4
        public static let sm: CGFloat = 8
        public static let md: CGFloat = 12
        public static let lg: CGFloat = 16
        public static let xl: CGFloat = 24
        public static let xxl: CGFloat = 32
        public static let xxxl: CGFloat = 48
    }

    // MARK: - Corner Radius

    public enum Radius {
        public static let xs: CGFloat = 4
        public static let sm: CGFloat = 6
        public static let md: CGFloat = 10
        public static let lg: CGFloat = 14
        public static let xl: CGFloat = 20
        public static let pill: CGFloat = 100
    }

    // MARK: - Animation Presets

    public enum Motion {
        /// Quick, snappy interactions (button taps, toggles)
        public static let snappy = Animation.spring(response: 0.3, dampingFraction: 0.82)
        /// Smooth transitions (panel slides, content changes)
        public static let smooth = Animation.spring(response: 0.45, dampingFraction: 0.86)
        /// Gentle entrances (page loads, modals)
        public static let gentle = Animation.spring(response: 0.6, dampingFraction: 0.78)
        /// Bouncy feedback (drag-drop, card moves)
        public static let bounce = Animation.spring(response: 0.4, dampingFraction: 0.62)
        /// Stiff snap (micro interactions)
        public static let stiffSnap = Animation.spring(response: 0.2, dampingFraction: 0.92)
        /// Card reorder animation
        public static let cardMove = Animation.spring(response: 0.35, dampingFraction: 0.75)

        /// Stagger delay for list/grid entrance animations
        public static func stagger(index: Int, base: Double = 0.04) -> Double {
            Double(index) * base
        }
    }

    // MARK: - Typography

    public enum Typography {
        public static let largeTitle: Font = .system(size: 28, weight: .bold, design: .rounded)
        public static let title: Font = .system(size: 20, weight: .semibold, design: .rounded)
        public static let title3: Font = .system(size: 16, weight: .semibold, design: .rounded)
        public static let headline: Font = .system(size: 14, weight: .semibold)
        public static let body: Font = .system(size: 13, weight: .regular)
        public static let callout: Font = .system(size: 12, weight: .medium)
        public static let caption: Font = .system(size: 11, weight: .medium)
        public static let micro: Font = .system(size: 10, weight: .medium, design: .monospaced)
        public static let code: Font = .system(size: 12, weight: .regular, design: .monospaced)
    }

    // MARK: - Sidebar Dimensions

    public enum Sidebar {
        public static let width: CGFloat = 220
        public static let iconSize: CGFloat = 18
        public static let itemHeight: CGFloat = 32
        public static let sectionSpacing: CGFloat = 24
    }

    // MARK: - Kanban Dimensions

    public enum Kanban {
        public static let columnMinWidth: CGFloat = 280
        public static let columnMaxWidth: CGFloat = 360
        public static let cardMinHeight: CGFloat = 80
        public static let columnHeaderHeight: CGFloat = 44
        public static let columnSpacing: CGFloat = 12
        public static let cardSpacing: CGFloat = 8
    }
}

// MARK: - View Modifiers

public extension View {
    /// Apply the standard Symphony card style
    func symphonyCard(
        cornerRadius: CGFloat = SymphonyDesignStyle.Radius.lg,
        selected: Bool = false
    ) -> some View {
        self
            .background(
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .fill(SymphonyDesignStyle.Background.tertiary)
            )
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .strokeBorder(
                        selected
                            ? SymphonyDesignStyle.Border.active
                            : SymphonyDesignStyle.Border.default,
                        lineWidth: 1
                    )
            )
            .clipShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
            .shadow(
                color: .black.opacity(selected ? 0.4 : 0.25),
                radius: selected ? 12 : 6,
                x: 0,
                y: selected ? 6 : 3
            )
    }

    /// Apply elevated card style (for hover / active states)
    func symphonyElevatedCard(
        cornerRadius: CGFloat = SymphonyDesignStyle.Radius.lg
    ) -> some View {
        self
            .background(
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .fill(SymphonyDesignStyle.Background.elevated)
            )
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .strokeBorder(SymphonyDesignStyle.Border.active, lineWidth: 1)
            )
            .clipShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
            .shadow(color: .black.opacity(0.4), radius: 16, x: 0, y: 8)
    }

    /// Kanban column well style
    func symphonyColumnWell() -> some View {
        self
            .background(
                RoundedRectangle(cornerRadius: SymphonyDesignStyle.Radius.xl, style: .continuous)
                    .fill(SymphonyDesignStyle.Background.columnWell)
            )
            .overlay(
                RoundedRectangle(cornerRadius: SymphonyDesignStyle.Radius.xl, style: .continuous)
                    .strokeBorder(SymphonyDesignStyle.Border.subtle, lineWidth: 1)
            )
    }

    /// Glass morphism panel (for overlays, modals)
    func symphonyGlass() -> some View {
        self
            .background(.ultraThinMaterial)
            .clipShape(RoundedRectangle(cornerRadius: SymphonyDesignStyle.Radius.lg, style: .continuous))
            .shadow(color: .black.opacity(0.3), radius: 20, x: 0, y: 10)
    }

    /// Staggered entrance animation
    func symphonyStaggerIn(index: Int, isVisible: Bool) -> some View {
        self
            .opacity(isVisible ? 1 : 0)
            .offset(y: isVisible ? 0 : 12)
            .animation(
                SymphonyDesignStyle.Motion.smooth.delay(SymphonyDesignStyle.Motion.stagger(index: index)),
                value: isVisible
            )
    }
}

// MARK: - Gradient Presets

public extension LinearGradient {
    /// Subtle glow gradient for status indicators
    static func symphonyStatusGlow(_ color: Color) -> LinearGradient {
        LinearGradient(
            colors: [color.opacity(0.25), color.opacity(0.08)],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    /// Background gradient for the main content area
    static var symphonyBackground: LinearGradient {
        LinearGradient(
            colors: [
                SymphonyDesignStyle.Background.secondary,
                SymphonyDesignStyle.Background.primary
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }
}
