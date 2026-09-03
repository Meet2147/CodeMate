import SwiftUI

/// Dark, editor-first chrome for the "coding surface" of the app --
/// the problem explorer, the workspace (statement/editor/assistant), and
/// the code editor itself. Deliberately distinct from CMTheme's soft
/// neumorphic look used by onboarding/Settings/Progress, the same way a
/// real IDE's editor area looks different from its surrounding chrome.
/// Always dark, regardless of system appearance -- that's the point of
/// an "IDE" look, and it keeps code contrast predictable.
enum IDETheme {
    static let background       = Color(red: 0.098, green: 0.102, blue: 0.114)   // editor canvas
    static let sidebarBackground = Color(red: 0.114, green: 0.118, blue: 0.130)  // explorer / panels
    static let elevatedBackground = Color(red: 0.145, green: 0.149, blue: 0.165) // cards, tab bar
    static let inputBackground  = Color(red: 0.078, green: 0.082, blue: 0.094)   // wells, editor text view

    static let border = Color.white.opacity(0.08)
    static let borderStrong = Color.white.opacity(0.14)

    static let textPrimary = Color(white: 0.90)
    static let textSecondary = Color(white: 0.56)
    static let textTertiary = Color(white: 0.38)

    /// The classic VS Code status-bar blue -- an intentional nod, it's
    /// instantly legible as "this is an editor" chrome.
    static let statusBarBackground = Color(red: 0.0, green: 0.478, blue: 0.784)
    static let statusBarText = Color.white

    static let accent = Color(red: 0.35, green: 0.62, blue: 1.0)
    static let selection = accent.opacity(0.16)

    static let cornerRadius: CGFloat = 6
}

/// Small, flat toolbar-style button (VS Code/Xcode toolbar-ish) -- used
/// inside the IDE chrome instead of NeumorphicButtonStyle's soft-shadow
/// look, which reads more "app UI" than "editor UI".
struct IDEButtonStyle: ButtonStyle {
    var tint: Color = IDETheme.accent
    var prominent: Bool = false

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 12, weight: .medium))
            .foregroundStyle(prominent ? .white : IDETheme.textPrimary)
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(
                RoundedRectangle(cornerRadius: 5, style: .continuous)
                    .fill(prominent ? AnyShapeStyle(tint) : AnyShapeStyle(configuration.isPressed ? Color.white.opacity(0.14) : Color.white.opacity(0.06)))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 5, style: .continuous)
                    .stroke(prominent ? .clear : IDETheme.border, lineWidth: 1)
            )
            .opacity(configuration.isPressed ? 0.8 : 1.0)
    }
}

extension View {
    /// Flat, bordered panel used throughout the IDE chrome in place of
    /// CMTheme's soft-shadow cards -- reads as "editor UI", not "app UI".
    func ideCard(padding: CGFloat = 14) -> some View {
        self
            .padding(padding)
            .background(
                RoundedRectangle(cornerRadius: IDETheme.cornerRadius, style: .continuous)
                    .fill(IDETheme.elevatedBackground)
            )
            .overlay(
                RoundedRectangle(cornerRadius: IDETheme.cornerRadius, style: .continuous)
                    .stroke(IDETheme.border, lineWidth: 1)
            )
    }
}
