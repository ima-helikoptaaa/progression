import SwiftUI

enum Theme {
    enum Colors {
        // Progression warm orange palette
        static let primary = Color(hex: "FF6B35")
        static let primaryLight = Color(hex: "FF8F5E")
        static let accent = Color(hex: "FFB347")
        static let success = Color(hex: "4CAF50")
        static let warning = Color(hex: "FF9800")
        static let danger = Color(hex: "EF5350")

        // Warm text hierarchy
        static let textPrimary = Color(hex: "2D1B00")
        static let textSecondary = Color(hex: "7A6652")
        static let textTertiary = Color(hex: "BDA88E")

        // Warm backgrounds
        static let background = Color(hex: "FFF8F0")
        static let card = Color.white
        static let cardBorder = Color(hex: "FFE8D6")

        // Fox mascot accent
        static let foxOrange = Color(hex: "FF6B35")
        static let foxCream = Color(hex: "FFF3E0")

        // Curated activity color palette (6 warm-toned colors)
        static let activityColors: [String] = [
            "#FF6B35", "#7BAF5E", "#C4956A", "#9B86B2",
            "#D4A04E", "#6B9E94"
        ]
    }

    enum Layout {
        static let cardRadius: CGFloat = 20
        static let buttonRadius: CGFloat = 14
        static let padding: CGFloat = 16
        static let cardPadding: CGFloat = 20
    }

    enum Icons {
        static let pointIcon = "diamond.fill"
    }

    enum Animation {
        static let spring = SwiftUI.Animation.spring(response: 0.5, dampingFraction: 0.82)
        static let quick = SwiftUI.Animation.spring(response: 0.3, dampingFraction: 0.85)
        static let staggered = SwiftUI.Animation.spring(response: 0.45, dampingFraction: 0.8)
        static let bouncy = SwiftUI.Animation.spring(response: 0.4, dampingFraction: 0.75)

        static func staggerDelay(index: Int) -> SwiftUI.Animation {
            SwiftUI.Animation.spring(response: 0.45, dampingFraction: 0.8).delay(Double(index) * 0.05)
        }
    }
}

// MARK: - Card Modifier

struct AppleCard: ViewModifier {
    var cornerRadius: CGFloat = Theme.Layout.cardRadius

    func body(content: Content) -> some View {
        content
            .background(
                RoundedRectangle(cornerRadius: cornerRadius)
                    .fill(Theme.Colors.card)
                    .shadow(color: Color(hex: "FF6B35").opacity(0.08), radius: 12, x: 0, y: 4)
            )
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius)
                    .stroke(Theme.Colors.cardBorder, lineWidth: 1)
            )
    }
}

extension View {
    func appleCard(cornerRadius: CGFloat = Theme.Layout.cardRadius) -> some View {
        modifier(AppleCard(cornerRadius: cornerRadius))
    }

    func glassCard(cornerRadius: CGFloat = Theme.Layout.cardRadius) -> some View {
        modifier(AppleCard(cornerRadius: cornerRadius))
    }
}

extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 6:
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8:
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (255, 0, 0, 0)
        }
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}
