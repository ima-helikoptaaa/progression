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

        // Warm text hierarchy (adaptive for dark mode)
        static let textPrimary = Color(adaptiveLight: "2D1B00", dark: "F5E6D3")
        static let textSecondary = Color(adaptiveLight: "7A6652", dark: "B8A088")
        static let textTertiary = Color(adaptiveLight: "BDA88E", dark: "8A7560")

        // Warm backgrounds (adaptive for dark mode)
        static let background = Color(adaptiveLight: "FFF8F0", dark: "1A1208")
        static let card = Color(adaptiveLight: "FFFFFF", dark: "2A1F14")
        static let cardBorder = Color(adaptiveLight: "FFE8D6", dark: "3D2E1E")

        // Fox mascot accent
        static let foxOrange = Color(hex: "FF6B35")
        static let foxCream = Color(adaptiveLight: "FFF3E0", dark: "2A1F14")

        // Progress card (dark warm gradient)
        static let progressCardBg = Color(adaptiveLight: "1A0E00", dark: "0D0700")

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
        static let smallPadding: CGFloat = 8
        static let largePadding: CGFloat = 24
    }

    enum Shadows {
        static let card = (color: Color(hex: "FF6B35").opacity(0.08), radius: CGFloat(12), x: CGFloat(0), y: CGFloat(4))
        static let subtle = (color: Color.black.opacity(0.04), radius: CGFloat(6), x: CGFloat(0), y: CGFloat(2))
        static let elevated = (color: Color(hex: "FF6B35").opacity(0.12), radius: CGFloat(16), x: CGFloat(0), y: CGFloat(6))
        static let glow = (color: Color(hex: "FF6B35").opacity(0.3), radius: CGFloat(20), x: CGFloat(0), y: CGFloat(0))
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

    init(adaptiveLight: String, dark: String) {
        self.init(UIColor { traitCollection in
            let hex = traitCollection.userInterfaceStyle == .dark ? dark : adaptiveLight
            return UIColor(Color(hex: hex))
        })
    }
}
