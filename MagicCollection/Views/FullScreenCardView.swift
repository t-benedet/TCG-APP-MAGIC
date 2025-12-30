import SwiftUI

struct FullScreenCardView: View {
    let card: CollectionCard
    @EnvironmentObject var dataManager: DataManager
    @Environment(\.dismiss) private var dismiss
    @State private var showingPrices = false
    @State private var cardDetails: ScryfallCard?
    @State private var isLoadingDetails = false
    @State private var imageScale: CGFloat = 1.0
    @State private var imageOffset: CGSize = .zero

    var body: some View {
        ZStack {
            // Background
            Color.black.ignoresSafeArea()

            // Gradient overlay
            RadialGradient(
                colors: [
                    Color.rarityColor(for: card.rarity).opacity(0.3),
                    Color.black
                ],
                center: .center,
                startRadius: 100,
                endRadius: 400
            )
            .ignoresSafeArea()

            VStack(spacing: 0) {
                // Top Bar
                HStack {
                    Button(action: { dismiss() }) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 28))
                            .foregroundColor(.white.opacity(0.8))
                    }

                    Spacer()

                    // Badges
                    HStack(spacing: 8) {
                        if card.isFoil {
                            FoilBadge()
                        }
                        RarityBadge(rarity: card.rarity)
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 10)

                Spacer()

                // Card Image
                ZoomableCardImage(url: card.imageUrl)
                    .padding(.horizontal, 20)

                Spacer()

                // Card Info
                VStack(spacing: 16) {
                    // Name and Set
                    VStack(spacing: 4) {
                        Text(card.name)
                            .font(.system(size: 22, weight: .bold))
                            .foregroundColor(.white)

                        Text(card.setName ?? "Unknown Set")
                            .font(.system(size: 14))
                            .foregroundColor(.gray)
                    }

                    // Quantity and Actions
                    HStack(spacing: 24) {
                        // Quantity controls
                        HStack(spacing: 16) {
                            Button(action: {
                                dataManager.decrementQuantity(for: card)
                            }) {
                                Image(systemName: "minus.circle.fill")
                                    .font(.system(size: 32))
                                    .foregroundColor(.gray)
                            }

                            VStack(spacing: 2) {
                                Text("×\(card.quantity)")
                                    .font(.system(size: 28, weight: .bold))
                                    .foregroundColor(.white)
                                Text("in collection")
                                    .font(.system(size: 11))
                                    .foregroundColor(.gray)
                            }

                            Button(action: {
                                dataManager.incrementQuantity(for: card)
                            }) {
                                Image(systemName: "plus.circle.fill")
                                    .font(.system(size: 32))
                                    .foregroundColor(Color(red: 0.6, green: 0.4, blue: 0.9))
                            }
                        }
                    }

                    // Price Display
                    HStack(spacing: 16) {
                        if let priceUsd = card.cachedPriceUsd {
                            PriceBadge(price: priceUsd, currency: "$")
                        }
                        if let priceEur = card.cachedPriceEur {
                            PriceBadge(price: priceEur, currency: "€")
                        }
                    }

                    // View Prices Button
                    Button(action: {
                        loadCardDetails()
                        showingPrices = true
                    }) {
                        HStack(spacing: 8) {
                            Image(systemName: "chart.line.uptrend.xyaxis")
                            Text("View Market Prices")
                        }
                        .font(.system(size: 15, weight: .medium))
                        .foregroundColor(.white)
                        .padding(.horizontal, 24)
                        .padding(.vertical, 12)
                        .background(
                            Capsule()
                                .fill(Color(white: 0.2))
                        )
                    }
                }
                .padding(24)
                .background(
                    RoundedRectangle(cornerRadius: 24)
                        .fill(Color(red: 0.1, green: 0.1, blue: 0.15).opacity(0.95))
                )
                .padding(.horizontal, 16)
                .padding(.bottom, 20)
            }
        }
        .sheet(isPresented: $showingPrices) {
            priceSheet
        }
        .preferredColorScheme(.dark)
    }

    // MARK: - Price Sheet

    private var priceSheet: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    // Card Preview
                    AsyncImage(url: URL(string: card.thumbnailUrl ?? "")) { phase in
                        switch phase {
                        case .success(let image):
                            image
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                                .frame(height: 200)
                                .clipShape(RoundedRectangle(cornerRadius: 12))
                        default:
                            RoundedRectangle(cornerRadius: 12)
                                .fill(Color(white: 0.15))
                                .frame(height: 200)
                        }
                    }

                    if isLoadingDetails {
                        ProgressView()
                            .tint(.white)
                            .padding()
                    } else if let details = cardDetails {
                        PriceView(
                            prices: details.prices,
                            purchaseUris: details.purchaseUris,
                            isFoil: card.isFoil
                        )

                        // Total Value
                        if let totalValue = card.totalValueUsd {
                            VStack(spacing: 8) {
                                Text("Your Total Value")
                                    .font(.system(size: 14))
                                    .foregroundColor(.gray)

                                Text(String(format: "$%.2f", totalValue))
                                    .font(.system(size: 32, weight: .bold))
                                    .foregroundColor(Color(red: 0.4, green: 0.85, blue: 0.4))

                                Text("(\(card.quantity) × $\(card.cachedPriceUsd ?? "0"))")
                                    .font(.system(size: 13))
                                    .foregroundColor(.gray)
                            }
                            .padding(20)
                            .frame(maxWidth: .infinity)
                            .background(
                                RoundedRectangle(cornerRadius: 20)
                                    .fill(Color(red: 0.12, green: 0.12, blue: 0.18))
                            )
                        }
                    } else {
                        // Fallback with cached prices
                        VStack(spacing: 16) {
                            Text("Cached Prices")
                                .font(.system(size: 18, weight: .bold))
                                .foregroundColor(.white)

                            HStack(spacing: 20) {
                                if let priceUsd = card.cachedPriceUsd {
                                    VStack(spacing: 4) {
                                        Text("$\(priceUsd)")
                                            .font(.system(size: 24, weight: .bold))
                                            .foregroundColor(Color(red: 0.4, green: 0.85, blue: 0.4))
                                        Text("USD")
                                            .font(.system(size: 12))
                                            .foregroundColor(.gray)
                                    }
                                }

                                if let priceEur = card.cachedPriceEur {
                                    VStack(spacing: 4) {
                                        Text("€\(priceEur)")
                                            .font(.system(size: 24, weight: .bold))
                                            .foregroundColor(Color(red: 0.9, green: 0.7, blue: 0.2))
                                        Text("EUR")
                                            .font(.system(size: 12))
                                            .foregroundColor(.gray)
                                    }
                                }
                            }

                            if let lastUpdate = card.lastPriceUpdate {
                                Text("Last updated: \(lastUpdate.formatted(date: .abbreviated, time: .shortened))")
                                    .font(.system(size: 12))
                                    .foregroundColor(.gray)
                            }
                        }
                        .padding(20)
                        .background(
                            RoundedRectangle(cornerRadius: 20)
                                .fill(Color(red: 0.12, green: 0.12, blue: 0.18))
                        )
                    }
                }
                .padding(20)
            }
            .background(Color(red: 0.05, green: 0.05, blue: 0.1).ignoresSafeArea())
            .navigationTitle("Market Prices")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") {
                        showingPrices = false
                    }
                }
            }
        }
        .presentationDetents([.large])
        .preferredColorScheme(.dark)
    }

    // MARK: - Load Card Details

    private func loadCardDetails() {
        guard cardDetails == nil else { return }

        isLoadingDetails = true
        Task {
            do {
                cardDetails = try await ScryfallService.shared.getCard(id: card.scryfallId)
            } catch {
                print("Failed to load card details: \(error)")
            }
            isLoadingDetails = false
        }
    }
}

// MARK: - Collection Card Extension for Identifiable

extension CollectionCard: Hashable {
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }

    static func == (lhs: CollectionCard, rhs: CollectionCard) -> Bool {
        lhs.id == rhs.id
    }
}
