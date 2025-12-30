import SwiftUI

struct PriceView: View {
    let prices: CardPrices?
    let purchaseUris: PurchaseUris?
    let isFoil: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Market Prices")
                .font(.system(size: 20, weight: .bold))
                .foregroundColor(.white)

            VStack(spacing: 12) {
                ForEach(PricePlatform.allCases) { platform in
                    PricePlatformRow(
                        platform: platform,
                        price: platform.price(from: prices, isFoil: isFoil),
                        url: platform.url(from: purchaseUris)
                    )
                }
            }

            if isFoil {
                HStack(spacing: 6) {
                    Image(systemName: "sparkles")
                        .foregroundStyle(Color.goldGradient)
                    Text("Foil prices shown")
                        .font(.system(size: 12))
                        .foregroundColor(.gray)
                }
                .padding(.top, 4)
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color(red: 0.12, green: 0.12, blue: 0.18))
        )
    }
}

struct PricePlatformRow: View {
    let platform: PricePlatform
    let price: String?
    let url: URL?

    var body: some View {
        HStack {
            // Platform Icon & Name
            HStack(spacing: 10) {
                Image(systemName: platform.iconName)
                    .font(.system(size: 20))
                    .foregroundColor(platformColor)
                    .frame(width: 30)

                VStack(alignment: .leading, spacing: 2) {
                    Text(platform.rawValue)
                        .font(.system(size: 15, weight: .medium))
                        .foregroundColor(.white)

                    Text(platform.currency)
                        .font(.system(size: 11))
                        .foregroundColor(.gray)
                }
            }

            Spacer()

            // Price & Link
            if let price = price {
                HStack(spacing: 12) {
                    Text("\(platform.currencySymbol)\(price)")
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(Color(red: 0.4, green: 0.85, blue: 0.4))

                    if let url = url {
                        Link(destination: url) {
                            Image(systemName: "arrow.up.right.circle.fill")
                                .font(.system(size: 22))
                                .foregroundColor(Color(red: 0.6, green: 0.4, blue: 0.9))
                        }
                    }
                }
            } else {
                Text("N/A")
                    .font(.system(size: 15))
                    .foregroundColor(.gray)
            }
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(white: 0.1))
        )
    }

    private var platformColor: Color {
        switch platform {
        case .tcgplayer:
            return Color(red: 0.2, green: 0.6, blue: 0.9)
        case .cardmarket:
            return Color(red: 0.9, green: 0.7, blue: 0.2)
        case .cardhoarder:
            return Color(red: 0.6, green: 0.4, blue: 0.9)
        }
    }
}

// MARK: - Compact Price Badge

struct PriceBadge: View {
    let price: String?
    let currency: String

    var body: some View {
        if let price = price {
            HStack(spacing: 4) {
                Text(currency)
                    .font(.system(size: 10, weight: .medium))
                    .foregroundColor(.gray)
                Text(price)
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(Color(red: 0.4, green: 0.85, blue: 0.4))
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(
                Capsule()
                    .fill(Color(red: 0.15, green: 0.25, blue: 0.15))
            )
        }
    }
}

// MARK: - Total Value Display

struct TotalValueView: View {
    let totalUsd: Double
    let totalEur: Double

    var body: some View {
        VStack(spacing: 8) {
            Text("Collection Value")
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(.gray)

            HStack(spacing: 20) {
                VStack(spacing: 2) {
                    Text(String(format: "$%.2f", totalUsd))
                        .font(.system(size: 24, weight: .bold))
                        .foregroundColor(Color(red: 0.4, green: 0.85, blue: 0.4))
                    Text("USD")
                        .font(.system(size: 11))
                        .foregroundColor(.gray)
                }

                Rectangle()
                    .fill(Color.gray.opacity(0.3))
                    .frame(width: 1, height: 40)

                VStack(spacing: 2) {
                    Text(String(format: "€%.2f", totalEur))
                        .font(.system(size: 24, weight: .bold))
                        .foregroundColor(Color(red: 0.9, green: 0.7, blue: 0.2))
                    Text("EUR")
                        .font(.system(size: 11))
                        .foregroundColor(.gray)
                }
            }
        }
        .padding(20)
        .frame(maxWidth: .infinity)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color(red: 0.12, green: 0.12, blue: 0.18))
        )
    }
}

#Preview {
    VStack(spacing: 20) {
        PriceView(
            prices: CardPrices(
                usd: "25.99",
                usdFoil: "45.99",
                usdEtched: nil,
                eur: "22.50",
                eurFoil: "40.00",
                tix: "12.5"
            ),
            purchaseUris: nil,
            isFoil: false
        )

        TotalValueView(totalUsd: 1234.56, totalEur: 1100.00)
    }
    .padding()
    .background(Color(red: 0.08, green: 0.08, blue: 0.12))
}
