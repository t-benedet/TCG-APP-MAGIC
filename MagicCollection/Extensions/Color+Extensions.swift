import SwiftUI

extension Color {
    // MARK: - Magic Theme Colors

    static let magicBackground = Color("magicBackground")
    static let magicCardBackground = Color("magicCardBackground")
    static let magicAccent = Color("magicAccent")
    static let magicGold = Color("magicGold")
    static let magicSecondary = Color("magicSecondary")

    // MARK: - Rarity Colors

    static let rarityCommon = Color("rarityCommon")
    static let rarityUncommon = Color("rarityUncommon")
    static let rarityRare = Color("rarityRare")
    static let rarityMythic = Color("rarityMythic")

    // MARK: - Mana Colors

    static let manaWhite = Color("manaWhite")
    static let manaBlue = Color("manaBlue")
    static let manaBlack = Color("manaBlack")
    static let manaRed = Color("manaRed")
    static let manaGreen = Color("manaGreen")
    static let manaColorless = Color("manaColorless")

    // MARK: - Fallback Colors (for previews or missing assets)

    static var magicBackgroundFallback: Color {
        Color(red: 0.08, green: 0.08, blue: 0.12)
    }

    static var magicCardBackgroundFallback: Color {
        Color(red: 0.12, green: 0.12, blue: 0.18)
    }

    static var magicAccentFallback: Color {
        Color(red: 0.6, green: 0.4, blue: 0.9)
    }

    static var magicGoldFallback: Color {
        Color(red: 0.85, green: 0.65, blue: 0.2)
    }

    // MARK: - Rarity Color Helpers

    static func rarityColor(for rarity: String?) -> Color {
        switch rarity?.lowercased() {
        case "common":
            return Color(white: 0.7)
        case "uncommon":
            return Color(red: 0.6, green: 0.75, blue: 0.85)
        case "rare":
            return Color(red: 0.85, green: 0.7, blue: 0.3)
        case "mythic":
            return Color(red: 0.9, green: 0.4, blue: 0.2)
        default:
            return Color(white: 0.5)
        }
    }

    // MARK: - Gradient Helpers

    static var magicGradient: LinearGradient {
        LinearGradient(
            colors: [
                Color(red: 0.15, green: 0.1, blue: 0.25),
                Color(red: 0.08, green: 0.08, blue: 0.15)
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    static var cardGlowGradient: RadialGradient {
        RadialGradient(
            colors: [
                Color(red: 0.6, green: 0.4, blue: 0.9).opacity(0.3),
                Color.clear
            ],
            center: .center,
            startRadius: 0,
            endRadius: 150
        )
    }

    static var goldGradient: LinearGradient {
        LinearGradient(
            colors: [
                Color(red: 0.95, green: 0.8, blue: 0.4),
                Color(red: 0.75, green: 0.55, blue: 0.2),
                Color(red: 0.95, green: 0.8, blue: 0.4)
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    static var mythicGradient: LinearGradient {
        LinearGradient(
            colors: [
                Color(red: 0.95, green: 0.5, blue: 0.2),
                Color(red: 0.85, green: 0.3, blue: 0.15),
                Color(red: 0.95, green: 0.5, blue: 0.2)
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }
}

// MARK: - View Modifiers

struct MagicCardStyle: ViewModifier {
    func body(content: Content) -> some View {
        content
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color(red: 0.12, green: 0.12, blue: 0.18))
                    .shadow(color: Color.black.opacity(0.3), radius: 10, x: 0, y: 5)
            )
    }
}

struct GlowEffect: ViewModifier {
    let color: Color
    let radius: CGFloat

    func body(content: Content) -> some View {
        content
            .shadow(color: color.opacity(0.5), radius: radius / 2)
            .shadow(color: color.opacity(0.3), radius: radius)
    }
}

extension View {
    func magicCardStyle() -> some View {
        modifier(MagicCardStyle())
    }

    func glowEffect(color: Color = Color(red: 0.6, green: 0.4, blue: 0.9), radius: CGFloat = 10) -> some View {
        modifier(GlowEffect(color: color, radius: radius))
    }
}
