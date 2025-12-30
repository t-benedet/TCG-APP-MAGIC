import SwiftUI

struct AddCardView: View {
    let card: ScryfallCard
    let onAdd: (Int, Bool) -> Void

    @State private var quantity = 1
    @State private var isFoil = false
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                // Card Preview
                HStack(spacing: 16) {
                    AsyncImage(url: URL(string: card.thumbnailUrl ?? "")) { phase in
                        switch phase {
                        case .success(let image):
                            image
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                                .frame(width: 100, height: 140)
                                .clipShape(RoundedRectangle(cornerRadius: 10))
                                .shadow(color: Color.rarityColor(for: card.rarity).opacity(0.5), radius: 8)
                        default:
                            RoundedRectangle(cornerRadius: 10)
                                .fill(Color(white: 0.2))
                                .frame(width: 100, height: 140)
                        }
                    }

                    VStack(alignment: .leading, spacing: 8) {
                        Text(card.name)
                            .font(.system(size: 18, weight: .bold))
                            .foregroundColor(.white)
                            .lineLimit(2)

                        Text(card.setName ?? "Unknown Set")
                            .font(.system(size: 14))
                            .foregroundColor(.gray)

                        HStack(spacing: 8) {
                            RarityBadge(rarity: card.rarity)

                            if let price = card.prices?.usd {
                                PriceBadge(price: price, currency: "$")
                            }
                        }

                        if let typeLine = card.typeLine {
                            Text(typeLine)
                                .font(.system(size: 12))
                                .foregroundColor(.gray)
                                .lineLimit(1)
                        }
                    }

                    Spacer()
                }
                .padding(20)
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(Color(red: 0.12, green: 0.12, blue: 0.18))
                )

                // Options
                VStack(spacing: 16) {
                    // Quantity
                    HStack {
                        Text("Quantity")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(.white)

                        Spacer()

                        HStack(spacing: 20) {
                            Button(action: { if quantity > 1 { quantity -= 1 } }) {
                                Image(systemName: "minus.circle.fill")
                                    .font(.system(size: 32))
                                    .foregroundColor(quantity > 1 ? Color(red: 0.6, green: 0.4, blue: 0.9) : .gray)
                            }
                            .disabled(quantity <= 1)

                            Text("\(quantity)")
                                .font(.system(size: 28, weight: .bold))
                                .foregroundColor(.white)
                                .frame(minWidth: 50)

                            Button(action: { quantity += 1 }) {
                                Image(systemName: "plus.circle.fill")
                                    .font(.system(size: 32))
                                    .foregroundColor(Color(red: 0.6, green: 0.4, blue: 0.9))
                            }
                        }
                    }

                    Divider()
                        .background(Color.gray.opacity(0.3))

                    // Foil Toggle
                    Toggle(isOn: $isFoil) {
                        HStack(spacing: 10) {
                            Image(systemName: "sparkles")
                                .font(.system(size: 16))
                                .foregroundStyle(isFoil ? Color.goldGradient : LinearGradient(colors: [.gray], startPoint: .leading, endPoint: .trailing))

                            VStack(alignment: .leading, spacing: 2) {
                                Text("Foil Version")
                                    .font(.system(size: 16, weight: .medium))
                                    .foregroundColor(.white)

                                if let foilPrice = card.prices?.usdFoil {
                                    Text("$\(foilPrice)")
                                        .font(.system(size: 12))
                                        .foregroundColor(Color(red: 0.85, green: 0.65, blue: 0.2))
                                }
                            }
                        }
                    }
                    .tint(Color(red: 0.85, green: 0.65, blue: 0.2))
                }
                .padding(20)
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(Color(red: 0.12, green: 0.12, blue: 0.18))
                )

                // Price Summary
                VStack(spacing: 8) {
                    HStack {
                        Text("Unit Price")
                            .foregroundColor(.gray)
                        Spacer()
                        if let price = isFoil ? card.prices?.usdFoil : card.prices?.usd {
                            Text("$\(price)")
                                .foregroundColor(.white)
                        } else {
                            Text("N/A")
                                .foregroundColor(.gray)
                        }
                    }

                    HStack {
                        Text("Total Value")
                            .font(.system(size: 16, weight: .bold))
                            .foregroundColor(.white)
                        Spacer()
                        if let priceStr = isFoil ? card.prices?.usdFoil : card.prices?.usd,
                           let price = Double(priceStr) {
                            Text(String(format: "$%.2f", price * Double(quantity)))
                                .font(.system(size: 18, weight: .bold))
                                .foregroundColor(Color(red: 0.4, green: 0.85, blue: 0.4))
                        } else {
                            Text("N/A")
                                .foregroundColor(.gray)
                        }
                    }
                }
                .padding(16)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color(white: 0.1))
                )

                Spacer()

                // Add Button
                Button(action: {
                    onAdd(quantity, isFoil)
                }) {
                    HStack(spacing: 10) {
                        Image(systemName: "plus.circle.fill")
                            .font(.system(size: 20))

                        Text("Add \(quantity) Card\(quantity > 1 ? "s" : "") to Collection")
                            .font(.system(size: 16, weight: .semibold))
                    }
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 18)
                    .background(
                        RoundedRectangle(cornerRadius: 16)
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
                Color(red: 0.05, green: 0.05, blue: 0.1)
                    .ignoresSafeArea()
            )
            .navigationTitle("Add Card")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
        }
        .presentationDetents([.medium, .large])
        .preferredColorScheme(.dark)
    }
}
