import SwiftUI

struct CardRowView: View {
    let card: CollectionCard
    let onTap: () -> Void
    let onIncrement: () -> Void
    let onDecrement: () -> Void

    @State private var isPressed = false

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 12) {
                // Card Image
                AsyncImage(url: URL(string: card.thumbnailUrl ?? "")) { phase in
                    switch phase {
                    case .empty:
                        RoundedRectangle(cornerRadius: 8)
                            .fill(Color(white: 0.2))
                            .overlay(
                                ProgressView()
                                    .tint(.white)
                            )
                    case .success(let image):
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .clipShape(RoundedRectangle(cornerRadius: 8))
                    case .failure:
                        RoundedRectangle(cornerRadius: 8)
                            .fill(Color(white: 0.2))
                            .overlay(
                                Image(systemName: "photo")
                                    .foregroundColor(.gray)
                            )
                    @unknown default:
                        EmptyView()
                    }
                }
                .frame(width: 60, height: 84)
                .shadow(color: Color.rarityColor(for: card.rarity).opacity(0.5), radius: 5)

                // Card Info
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text(card.name)
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(.white)
                            .lineLimit(1)

                        if card.isFoil {
                            Image(systemName: "sparkles")
                                .font(.system(size: 12))
                                .foregroundStyle(Color.goldGradient)
                        }
                    }

                    Text(card.setName ?? "Unknown Set")
                        .font(.system(size: 13))
                        .foregroundColor(.gray)
                        .lineLimit(1)

                    HStack(spacing: 8) {
                        // Rarity badge
                        Text(card.formattedRarity)
                            .font(.system(size: 11, weight: .medium))
                            .foregroundColor(.white)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 3)
                            .background(
                                Capsule()
                                    .fill(Color.rarityColor(for: card.rarity).opacity(0.3))
                            )

                        // Price
                        if let price = card.cachedPriceUsd {
                            Text("$\(price)")
                                .font(.system(size: 12, weight: .medium))
                                .foregroundColor(Color(red: 0.4, green: 0.8, blue: 0.4))
                        }
                    }
                }

                Spacer()

                // Quantity Controls
                VStack(spacing: 4) {
                    Text("×\(card.quantity)")
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(.white)

                    HStack(spacing: 8) {
                        Button(action: onDecrement) {
                            Image(systemName: "minus.circle.fill")
                                .font(.system(size: 22))
                                .foregroundColor(.gray)
                        }
                        .buttonStyle(.plain)

                        Button(action: onIncrement) {
                            Image(systemName: "plus.circle.fill")
                                .font(.system(size: 22))
                                .foregroundColor(Color(red: 0.6, green: 0.4, blue: 0.9))
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
            .padding(12)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color(red: 0.12, green: 0.12, blue: 0.18))
                    .shadow(color: Color.black.opacity(0.2), radius: 5, x: 0, y: 2)
            )
            .scaleEffect(isPressed ? 0.98 : 1.0)
        }
        .buttonStyle(.plain)
        .onLongPressGesture(minimumDuration: .infinity, pressing: { pressing in
            withAnimation(.easeInOut(duration: 0.1)) {
                isPressed = pressing
            }
        }, perform: {})
    }
}

// MARK: - Search Result Row

struct SearchResultRowView: View {
    let card: ScryfallCard
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 12) {
                // Card Image
                AsyncImage(url: URL(string: card.thumbnailUrl ?? "")) { phase in
                    switch phase {
                    case .empty:
                        RoundedRectangle(cornerRadius: 8)
                            .fill(Color(white: 0.2))
                            .overlay(ProgressView().tint(.white))
                    case .success(let image):
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .clipShape(RoundedRectangle(cornerRadius: 8))
                    case .failure:
                        RoundedRectangle(cornerRadius: 8)
                            .fill(Color(white: 0.2))
                            .overlay(
                                Image(systemName: "photo")
                                    .foregroundColor(.gray)
                            )
                    @unknown default:
                        EmptyView()
                    }
                }
                .frame(width: 50, height: 70)
                .shadow(color: Color.rarityColor(for: card.rarity).opacity(0.5), radius: 3)

                // Card Info
                VStack(alignment: .leading, spacing: 4) {
                    Text(card.name)
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundColor(.white)
                        .lineLimit(1)

                    Text(card.setName ?? "Unknown Set")
                        .font(.system(size: 12))
                        .foregroundColor(.gray)
                        .lineLimit(1)

                    HStack(spacing: 6) {
                        Text(card.formattedRarity)
                            .font(.system(size: 10, weight: .medium))
                            .foregroundColor(.white)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(
                                Capsule()
                                    .fill(Color.rarityColor(for: card.rarity).opacity(0.3))
                            )

                        if let price = card.prices?.usd {
                            Text("$\(price)")
                                .font(.system(size: 11, weight: .medium))
                                .foregroundColor(Color(red: 0.4, green: 0.8, blue: 0.4))
                        }
                    }
                }

                Spacer()

                Image(systemName: "plus.circle.fill")
                    .font(.system(size: 24))
                    .foregroundColor(Color(red: 0.6, green: 0.4, blue: 0.9))
            }
            .padding(10)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color(red: 0.12, green: 0.12, blue: 0.18))
            )
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    VStack {
        SearchResultRowView(
            card: ScryfallCard(
                id: "1",
                oracleId: nil,
                name: "Black Lotus",
                lang: "en",
                releasedAt: nil,
                uri: nil,
                scryfallUri: nil,
                layout: nil,
                manaCost: "{0}",
                cmc: 0,
                typeLine: "Artifact",
                oracleText: nil,
                power: nil,
                toughness: nil,
                colors: nil,
                colorIdentity: nil,
                keywords: nil,
                setCode: "lea",
                setName: "Limited Edition Alpha",
                collectorNumber: "232",
                rarity: "rare",
                flavorText: nil,
                artist: "Christopher Rush",
                prices: CardPrices(usd: "50000", usdFoil: nil, usdEtched: nil, eur: "45000", eurFoil: nil, tix: nil),
                imageUris: nil,
                cardFaces: nil,
                purchaseUris: nil
            ),
            onTap: {}
        )
    }
    .padding()
    .background(Color(red: 0.08, green: 0.08, blue: 0.12))
}
