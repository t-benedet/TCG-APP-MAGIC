import SwiftUI

struct GlowingCardView: View {
    let imageUrl: String?
    let rarity: String?
    let isFoil: Bool
    let onTap: () -> Void

    @State private var isAnimating = false
    @State private var shimmerOffset: CGFloat = -1

    var body: some View {
        Button(action: onTap) {
            ZStack {
                // Glow effect based on rarity
                if let rarity = rarity {
                    RoundedRectangle(cornerRadius: 18)
                        .fill(Color.rarityColor(for: rarity))
                        .blur(radius: 20)
                        .opacity(isAnimating ? 0.6 : 0.3)
                        .scaleEffect(isAnimating ? 1.05 : 1.0)
                }

                // Card image
                AsyncImage(url: URL(string: imageUrl ?? "")) { phase in
                    switch phase {
                    case .empty:
                        cardPlaceholder
                            .overlay(ProgressView().tint(.white))
                    case .success(let image):
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .clipShape(RoundedRectangle(cornerRadius: 14))
                            .overlay(
                                // Foil shimmer effect
                                isFoil ? shimmerOverlay : nil
                            )
                    case .failure:
                        cardPlaceholder
                            .overlay(
                                Image(systemName: "photo")
                                    .font(.system(size: 30))
                                    .foregroundColor(.gray)
                            )
                    @unknown default:
                        cardPlaceholder
                    }
                }
                .shadow(color: Color.rarityColor(for: rarity).opacity(0.5), radius: 10)
            }
        }
        .buttonStyle(.plain)
        .onAppear {
            withAnimation(.easeInOut(duration: 2).repeatForever(autoreverses: true)) {
                isAnimating = true
            }
            if isFoil {
                withAnimation(.linear(duration: 2).repeatForever(autoreverses: false)) {
                    shimmerOffset = 2
                }
            }
        }
    }

    private var cardPlaceholder: some View {
        RoundedRectangle(cornerRadius: 14)
            .fill(
                LinearGradient(
                    colors: [Color(white: 0.15), Color(white: 0.1)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .aspectRatio(0.714, contentMode: .fit)
    }

    private var shimmerOverlay: some View {
        GeometryReader { geometry in
            LinearGradient(
                colors: [
                    .clear,
                    .white.opacity(0.3),
                    .clear
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .mask(
                Rectangle()
                    .fill(
                        LinearGradient(
                            colors: [.clear, .white, .clear],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .offset(x: shimmerOffset * geometry.size.width)
            )
            .clipShape(RoundedRectangle(cornerRadius: 14))
        }
    }
}

// MARK: - Card Grid Item

struct CardGridItem: View {
    let card: CollectionCard
    let onTap: () -> Void

    var body: some View {
        VStack(spacing: 8) {
            GlowingCardView(
                imageUrl: card.thumbnailUrl,
                rarity: card.rarity,
                isFoil: card.isFoil,
                onTap: onTap
            )
            .frame(height: 180)

            VStack(spacing: 2) {
                Text(card.name)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(.white)
                    .lineLimit(1)

                HStack(spacing: 4) {
                    Text("×\(card.quantity)")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundColor(Color(red: 0.6, green: 0.4, blue: 0.9))

                    if let price = card.cachedPriceUsd {
                        Text("• $\(price)")
                            .font(.system(size: 10))
                            .foregroundColor(Color(red: 0.4, green: 0.8, blue: 0.4))
                    }
                }
            }
        }
    }
}

// MARK: - Rarity Badge

struct RarityBadge: View {
    let rarity: String?

    var body: some View {
        HStack(spacing: 4) {
            Circle()
                .fill(Color.rarityColor(for: rarity))
                .frame(width: 8, height: 8)

            Text(rarity?.capitalized ?? "Unknown")
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(.white)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 5)
        .background(
            Capsule()
                .fill(Color.rarityColor(for: rarity).opacity(0.2))
                .overlay(
                    Capsule()
                        .stroke(Color.rarityColor(for: rarity).opacity(0.5), lineWidth: 1)
                )
        )
    }
}

// MARK: - Foil Badge

struct FoilBadge: View {
    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: "sparkles")
                .font(.system(size: 10))

            Text("Foil")
                .font(.system(size: 12, weight: .medium))
        }
        .foregroundStyle(Color.goldGradient)
        .padding(.horizontal, 10)
        .padding(.vertical, 5)
        .background(
            Capsule()
                .fill(Color(red: 0.3, green: 0.25, blue: 0.1))
                .overlay(
                    Capsule()
                        .stroke(
                            LinearGradient(
                                colors: [
                                    Color(red: 0.95, green: 0.8, blue: 0.4),
                                    Color(red: 0.75, green: 0.55, blue: 0.2)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 1
                        )
                )
        )
    }
}

#Preview {
    VStack(spacing: 20) {
        HStack(spacing: 12) {
            RarityBadge(rarity: "common")
            RarityBadge(rarity: "uncommon")
            RarityBadge(rarity: "rare")
            RarityBadge(rarity: "mythic")
        }

        FoilBadge()
    }
    .padding()
    .background(Color(red: 0.08, green: 0.08, blue: 0.12))
}
