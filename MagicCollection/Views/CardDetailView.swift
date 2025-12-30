import SwiftUI

struct CardDetailView: View {
    let card: ScryfallCard
    let onAdd: (Int, Bool) -> Void

    @State private var quantity = 1
    @State private var isFoil = false
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // Card Image
                    cardImageSection

                    // Card Info
                    cardInfoSection

                    // Prices
                    if let prices = card.prices, prices.hasAnyPrice {
                        PriceView(
                            prices: prices,
                            purchaseUris: card.purchaseUris,
                            isFoil: isFoil
                        )
                    }

                    // Add to Collection
                    addToCollectionSection
                }
                .padding(20)
            }
            .background(
                LinearGradient(
                    colors: [
                        Color(red: 0.08, green: 0.06, blue: 0.15),
                        Color(red: 0.05, green: 0.05, blue: 0.1)
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .ignoresSafeArea()
            )
            .navigationTitle(card.name)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
        .preferredColorScheme(.dark)
    }

    // MARK: - Card Image Section

    private var cardImageSection: some View {
        ZStack {
            // Glow effect
            RoundedRectangle(cornerRadius: 20)
                .fill(Color.rarityColor(for: card.rarity))
                .blur(radius: 30)
                .opacity(0.4)

            AsyncImage(url: URL(string: card.displayImageUrl ?? "")) { phase in
                switch phase {
                case .empty:
                    RoundedRectangle(cornerRadius: 16)
                        .fill(Color(white: 0.15))
                        .aspectRatio(0.714, contentMode: .fit)
                        .overlay(ProgressView().tint(.white))
                case .success(let image):
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                case .failure:
                    RoundedRectangle(cornerRadius: 16)
                        .fill(Color(white: 0.15))
                        .aspectRatio(0.714, contentMode: .fit)
                        .overlay(
                            Image(systemName: "photo")
                                .font(.system(size: 40))
                                .foregroundColor(.gray)
                        )
                @unknown default:
                    EmptyView()
                }
            }
            .frame(maxWidth: 300)
            .shadow(color: Color.rarityColor(for: card.rarity).opacity(0.5), radius: 20)
        }
    }

    // MARK: - Card Info Section

    private var cardInfoSection: some View {
        VStack(spacing: 16) {
            // Name and Set
            VStack(spacing: 4) {
                Text(card.name)
                    .font(.system(size: 24, weight: .bold))
                    .foregroundColor(.white)
                    .multilineTextAlignment(.center)

                Text(card.setName ?? "Unknown Set")
                    .font(.system(size: 15))
                    .foregroundColor(.gray)
            }

            // Badges
            HStack(spacing: 10) {
                RarityBadge(rarity: card.rarity)

                if let collectorNumber = card.collectorNumber {
                    Text("#\(collectorNumber)")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.white)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 5)
                        .background(
                            Capsule()
                                .fill(Color(white: 0.2))
                        )
                }
            }

            // Type and Mana
            VStack(spacing: 8) {
                if let typeLine = card.typeLine {
                    Text(typeLine)
                        .font(.system(size: 14))
                        .foregroundColor(.white)
                }

                if let manaCost = card.manaCost {
                    Text(manaCost)
                        .font(.system(size: 14))
                        .foregroundColor(.gray)
                }
            }

            // Oracle Text
            if let oracleText = card.oracleText {
                Text(oracleText)
                    .font(.system(size: 14))
                    .foregroundColor(.white.opacity(0.9))
                    .multilineTextAlignment(.center)
                    .padding(16)
                    .frame(maxWidth: .infinity)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color(white: 0.1))
                    )
            }

            // Flavor Text
            if let flavorText = card.flavorText {
                Text(flavorText)
                    .font(.system(size: 13, weight: .regular, design: .serif))
                    .italic()
                    .foregroundColor(.gray)
                    .multilineTextAlignment(.center)
            }

            // Artist
            if let artist = card.artist {
                HStack(spacing: 6) {
                    Image(systemName: "paintbrush.fill")
                        .font(.system(size: 12))
                    Text(artist)
                        .font(.system(size: 13))
                }
                .foregroundColor(.gray)
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color(red: 0.12, green: 0.12, blue: 0.18))
        )
    }

    // MARK: - Add to Collection Section

    private var addToCollectionSection: some View {
        VStack(spacing: 16) {
            Text("Add to Collection")
                .font(.system(size: 18, weight: .bold))
                .foregroundColor(.white)

            // Quantity Selector
            HStack(spacing: 20) {
                Text("Quantity")
                    .foregroundColor(.gray)

                Spacer()

                HStack(spacing: 16) {
                    Button(action: { if quantity > 1 { quantity -= 1 } }) {
                        Image(systemName: "minus.circle.fill")
                            .font(.system(size: 28))
                            .foregroundColor(quantity > 1 ? Color(red: 0.6, green: 0.4, blue: 0.9) : .gray)
                    }
                    .disabled(quantity <= 1)

                    Text("\(quantity)")
                        .font(.system(size: 24, weight: .bold))
                        .foregroundColor(.white)
                        .frame(minWidth: 40)

                    Button(action: { quantity += 1 }) {
                        Image(systemName: "plus.circle.fill")
                            .font(.system(size: 28))
                            .foregroundColor(Color(red: 0.6, green: 0.4, blue: 0.9))
                    }
                }
            }

            // Foil Toggle
            Toggle(isOn: $isFoil) {
                HStack(spacing: 8) {
                    Image(systemName: "sparkles")
                        .foregroundStyle(isFoil ? Color.goldGradient : LinearGradient(colors: [.gray], startPoint: .leading, endPoint: .trailing))
                    Text("Foil")
                        .foregroundColor(.white)
                }
            }
            .tint(Color(red: 0.85, green: 0.65, blue: 0.2))

            // Add Button
            Button(action: {
                onAdd(quantity, isFoil)
                dismiss()
            }) {
                HStack(spacing: 8) {
                    Image(systemName: "plus.circle.fill")
                    Text("Add to Collection")
                }
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(
                    RoundedRectangle(cornerRadius: 14)
                        .fill(
                            LinearGradient(
                                colors: [
                                    Color(red: 0.6, green: 0.4, blue: 0.9),
                                    Color(red: 0.5, green: 0.3, blue: 0.8)
                                ],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                )
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color(red: 0.12, green: 0.12, blue: 0.18))
        )
    }
}
