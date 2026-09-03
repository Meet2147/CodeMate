import SwiftUI

/// Central neumorphic ("soft UI") design system for CodeMate.
/// All surfaces are built from a single base color with paired light/dark
/// shadows to fake extruded / inset plastic. Works in both light & dark mode.
enum CMTheme {
    // MARK: Base surface colors
    static func base(_ scheme: ColorScheme) -> Color {
        scheme == .dark ? Color(red: 0.106, green: 0.114, blue: 0.129)
                         : Color(red: 0.925, green: 0.933, blue: 0.949)
    }

    static func shadowDark(_ scheme: ColorScheme) -> Color {
        scheme == .dark ? Color.black.opacity(0.65) : Color(red: 0.71, green: 0.73, blue: 0.78).opacity(0.75)
    }

    static func shadowLight(_ scheme: ColorScheme) -> Color {
        scheme == .dark ? Color.white.opacity(0.035) : Color.white.opacity(0.9)
    }

    static func textPrimary(_ scheme: ColorScheme) -> Color {
        scheme == .dark ? Color(white: 0.92) : Color(red: 0.16, green: 0.18, blue: 0.22)
    }

    static func textSecondary(_ scheme: ColorScheme) -> Color {
        scheme == .dark ? Color(white: 0.62) : Color(red: 0.42, green: 0.45, blue: 0.52)
    }

    // MARK: Brand / accent
    static let accent = Color(red: 0.36, green: 0.44, blue: 0.98)      // indigo
    static let accentSoft = Color(red: 0.36, green: 0.44, blue: 0.98).opacity(0.16)
    static let success = Color(red: 0.20, green: 0.72, blue: 0.51)
    static let warning = Color(red: 0.95, green: 0.63, blue: 0.20)
    static let danger  = Color(red: 0.92, green: 0.33, blue: 0.38)

    // MARK: Company brand accents (used for badges / filters)
    static func companyColor(_ company: Company) -> Color {
        switch company {
        case .amazon:    return Color(red: 1.00, green: 0.60, blue: 0.10)
        case .google:    return Color(red: 0.26, green: 0.52, blue: 0.96)
        case .apple:     return Color(red: 0.55, green: 0.55, blue: 0.58)
        case .microsoft: return Color(red: 0.00, green: 0.60, blue: 0.86)
        }
    }

    static let cornerRadius: CGFloat = 18
    static let smallCornerRadius: CGFloat = 12
}

/// A raised ("embossed") neumorphic card — the surface pushes toward the viewer.
struct NeumorphicRaised: ViewModifier {
    @Environment(\.colorScheme) private var scheme
    var radius: CGFloat = CMTheme.cornerRadius
    var padding: CGFloat = 16
    var intensity: CGFloat = 1.0

    func body(content: Content) -> some View {
        content
            .padding(padding)
            .background(
                RoundedRectangle(cornerRadius: radius, style: .continuous)
                    .fill(CMTheme.base(scheme))
                    .shadow(color: CMTheme.shadowDark(scheme), radius: 10 * intensity, x: 7 * intensity, y: 7 * intensity)
                    .shadow(color: CMTheme.shadowLight(scheme), radius: 10 * intensity, x: -7 * intensity, y: -7 * intensity)
            )
    }
}

/// An inset ("pressed") neumorphic surface — used for wells, text fields, the editor gutter.
struct NeumorphicInset: ViewModifier {
    @Environment(\.colorScheme) private var scheme
    var radius: CGFloat = CMTheme.smallCornerRadius
    var padding: CGFloat = 12

    func body(content: Content) -> some View {
        content
            .padding(padding)
            .background(
                RoundedRectangle(cornerRadius: radius, style: .continuous)
                    .fill(CMTheme.base(scheme))
                    .overlay(
                        RoundedRectangle(cornerRadius: radius, style: .continuous)
                            .stroke(CMTheme.shadowDark(scheme), lineWidth: 3)
                            .blur(radius: 4)
                            .offset(x: 2, y: 2)
                            .mask(RoundedRectangle(cornerRadius: radius, style: .continuous).fill(
                                LinearGradient(colors: [.black, .clear], startPoint: .topLeading, endPoint: .bottomTrailing)))
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: radius, style: .continuous)
                            .stroke(CMTheme.shadowLight(scheme), lineWidth: 3)
                            .blur(radius: 4)
                            .offset(x: -2, y: -2)
                            .mask(RoundedRectangle(cornerRadius: radius, style: .continuous).fill(
                                LinearGradient(colors: [.clear, .black], startPoint: .topLeading, endPoint: .bottomTrailing)))
                    )
            )
    }
}

struct NeumorphicButtonStyle: ButtonStyle {
    @Environment(\.colorScheme) private var scheme
    var tint: Color = CMTheme.accent
    var prominent: Bool = false

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 13, weight: .semibold, design: .rounded))
            .foregroundStyle(prominent ? .white : CMTheme.textPrimary(scheme))
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .background(
                RoundedRectangle(cornerRadius: CMTheme.smallCornerRadius, style: .continuous)
                    .fill(prominent ? AnyShapeStyle(tint.gradient) : AnyShapeStyle(CMTheme.base(scheme)))
                    .shadow(color: CMTheme.shadowDark(scheme), radius: configuration.isPressed ? 2 : 6,
                            x: configuration.isPressed ? 1 : 4, y: configuration.isPressed ? 1 : 4)
                    .shadow(color: CMTheme.shadowLight(scheme), radius: configuration.isPressed ? 2 : 6,
                            x: configuration.isPressed ? -1 : -4, y: configuration.isPressed ? -1 : -4)
            )
            .scaleEffect(configuration.isPressed ? 0.97 : 1.0)
            .animation(.spring(response: 0.25, dampingFraction: 0.7), value: configuration.isPressed)
    }
}

extension View {
    func neumorphicRaised(radius: CGFloat = CMTheme.cornerRadius, padding: CGFloat = 16, intensity: CGFloat = 1.0) -> some View {
        modifier(NeumorphicRaised(radius: radius, padding: padding, intensity: intensity))
    }

    func neumorphicInset(radius: CGFloat = CMTheme.smallCornerRadius, padding: CGFloat = 12) -> some View {
        modifier(NeumorphicInset(radius: radius, padding: padding))
    }
}
