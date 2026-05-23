import SwiftUI

// MARK: - Color Tokens

extension Color {
    static let appBG          = Color(hex: "0A0E1A")
    static let appSurface     = Color(hex: "131929")
    static let appSurfaceHigh = Color(hex: "1A2235")
    static let appAccent      = Color(hex: "A78BFA")   // purple
    static let appAccentAlt   = Color(hex: "7C3AED")
    static let appMuted       = Color(hex: "8B9CB6")
    static let appBorder      = Color.white.opacity(0.06)

    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3:  (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6:  (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8:  (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default: (a, r, g, b) = (255, 0, 0, 0)
        }
        self.init(.sRGB, red: Double(r)/255, green: Double(g)/255, blue: Double(b)/255, opacity: Double(a)/255)
    }
}

// MARK: - Haptics

enum Haptics {
    static func impact(_ style: UIImpactFeedbackGenerator.FeedbackStyle = .medium) {
        UIImpactFeedbackGenerator(style: style).impactOccurred()
    }
    static func notification(_ type: UINotificationFeedbackGenerator.FeedbackType) {
        UINotificationFeedbackGenerator().notificationOccurred(type)
    }
    static func selection() { UISelectionFeedbackGenerator().selectionChanged() }
}

// MARK: - Gradient Button Style

struct GradientButtonStyle: ButtonStyle {
    var colors: [Color] = [Color(hex: "A78BFA"), Color(hex: "7C3AED")]
    var cornerRadius: CGFloat = 16

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.97 : 1.0)
            .animation(.spring(response: 0.2, dampingFraction: 0.7), value: configuration.isPressed)
            .background(
                RoundedRectangle(cornerRadius: cornerRadius)
                    .fill(LinearGradient(colors: colors, startPoint: .topLeading, endPoint: .bottomTrailing))
                    .shadow(color: colors.first?.opacity(configuration.isPressed ? 0.2 : 0.45) ?? .clear,
                            radius: configuration.isPressed ? 4 : 14,
                            y: configuration.isPressed ? 2 : 7)
            )
    }
}

// MARK: - Glass Surface

struct GlassSurface: ViewModifier {
    var cornerRadius: CGFloat = 20
    func body(content: Content) -> some View {
        content
            .background(
                RoundedRectangle(cornerRadius: cornerRadius)
                    .fill(Color.appSurface)
                    .overlay(RoundedRectangle(cornerRadius: cornerRadius)
                        .stroke(Color.appBorder, lineWidth: 1))
            )
    }
}

extension View {
    func glassSurface(cornerRadius: CGFloat = 20) -> some View {
        modifier(GlassSurface(cornerRadius: cornerRadius))
    }
}
