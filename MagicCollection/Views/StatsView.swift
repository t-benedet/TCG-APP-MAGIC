import SwiftUI
import Charts

struct StatsView: View {
    @EnvironmentObject var dataManager: DataManager
    @Environment(\.dismiss) private var dismiss

    private var stats: CollectionStatistics {
        dataManager.statistics
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // Total Value
                    TotalValueView(
                        totalUsd: stats.totalValueUsd,
                        totalEur: stats.totalValueEur
                    )

                    // Cards Overview
                    overviewSection

                    // Rarity Breakdown
                    raritySection

                    // Most Valuable Cards
                    if !stats.mostValuableCards.isEmpty {
                        mostValuableSection
                    }

                    // Recently Added
                    if !stats.recentlyAdded.isEmpty {
                        recentlyAddedSection
                    }
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
            .navigationTitle("Collection Stats")
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

    // MARK: - Overview Section

    private var overviewSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Overview")
                .font(.system(size: 18, weight: .bold))
                .foregroundColor(.white)

            HStack(spacing: 16) {
                StatCard(
                    icon: "rectangle.stack.fill",
                    title: "Total Cards",
                    value: "\(stats.totalCards)",
                    color: Color(red: 0.6, green: 0.4, blue: 0.9)
                )

                StatCard(
                    icon: "sparkles",
                    title: "Unique",
                    value: "\(stats.uniqueCards)",
                    color: Color(red: 0.4, green: 0.7, blue: 0.9)
                )
            }
        }
    }

    // MARK: - Rarity Section

    private var raritySection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("By Rarity")
                .font(.system(size: 18, weight: .bold))
                .foregroundColor(.white)

            VStack(spacing: 12) {
                ForEach(["mythic", "rare", "uncommon", "common"], id: \.self) { rarity in
                    if let count = stats.cardsByRarity[rarity], count > 0 {
                        RarityBar(
                            rarity: rarity,
                            count: count,
                            total: stats.totalCards
                        )
                    }
                }
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color(red: 0.12, green: 0.12, blue: 0.18))
            )
        }
    }

    // MARK: - Most Valuable Section

    private var mostValuableSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("Most Valuable")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(.white)

                Spacer()

                Image(systemName: "dollarsign.circle.fill")
                    .foregroundColor(Color(red: 0.4, green: 0.85, blue: 0.4))
            }

            VStack(spacing: 8) {
                ForEach(Array(stats.mostValuableCards.enumerated()), id: \.element.id) { index, card in
                    HStack(spacing: 12) {
                        Text("#\(index + 1)")
                            .font(.system(size: 14, weight: .bold))
                            .foregroundColor(.gray)
                            .frame(width: 30)

                        AsyncImage(url: URL(string: card.thumbnailUrl ?? "")) { phase in
                            if case .success(let image) = phase {
                                image
                                    .resizable()
                                    .aspectRatio(contentMode: .fill)
                                    .frame(width: 40, height: 56)
                                    .clipShape(RoundedRectangle(cornerRadius: 6))
                            } else {
                                RoundedRectangle(cornerRadius: 6)
                                    .fill(Color(white: 0.2))
                                    .frame(width: 40, height: 56)
                            }
                        }

                        VStack(alignment: .leading, spacing: 2) {
                            Text(card.name)
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(.white)
                                .lineLimit(1)

                            Text("×\(card.quantity)")
                                .font(.system(size: 12))
                                .foregroundColor(.gray)
                        }

                        Spacer()

                        if let value = card.totalValueUsd {
                            Text(String(format: "$%.2f", value))
                                .font(.system(size: 15, weight: .bold))
                                .foregroundColor(Color(red: 0.4, green: 0.85, blue: 0.4))
                        }
                    }
                    .padding(10)
                    .background(
                        RoundedRectangle(cornerRadius: 10)
                            .fill(Color(white: 0.1))
                    )
                }
            }
        }
    }

    // MARK: - Recently Added Section

    private var recentlyAddedSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("Recently Added")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(.white)

                Spacer()

                Image(systemName: "clock.fill")
                    .foregroundColor(Color(red: 0.6, green: 0.4, blue: 0.9))
            }

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(stats.recentlyAdded) { card in
                        VStack(spacing: 8) {
                            AsyncImage(url: URL(string: card.thumbnailUrl ?? "")) { phase in
                                if case .success(let image) = phase {
                                    image
                                        .resizable()
                                        .aspectRatio(contentMode: .fit)
                                        .frame(width: 80, height: 112)
                                        .clipShape(RoundedRectangle(cornerRadius: 8))
                                } else {
                                    RoundedRectangle(cornerRadius: 8)
                                        .fill(Color(white: 0.2))
                                        .frame(width: 80, height: 112)
                                }
                            }

                            Text(card.name)
                                .font(.system(size: 11))
                                .foregroundColor(.white)
                                .lineLimit(1)
                                .frame(width: 80)
                        }
                    }
                }
            }
        }
    }
}

// MARK: - Stat Card

struct StatCard: View {
    let icon: String
    let title: String
    let value: String
    let color: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 24))
                .foregroundColor(color)

            VStack(alignment: .leading, spacing: 2) {
                Text(value)
                    .font(.system(size: 28, weight: .bold))
                    .foregroundColor(.white)

                Text(title)
                    .font(.system(size: 13))
                    .foregroundColor(.gray)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(red: 0.12, green: 0.12, blue: 0.18))
        )
    }
}

// MARK: - Rarity Bar

struct RarityBar: View {
    let rarity: String
    let count: Int
    let total: Int

    private var percentage: CGFloat {
        guard total > 0 else { return 0 }
        return CGFloat(count) / CGFloat(total)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Circle()
                    .fill(Color.rarityColor(for: rarity))
                    .frame(width: 10, height: 10)

                Text(rarity.capitalized)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.white)

                Spacer()

                Text("\(count)")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(.white)

                Text("(\(Int(percentage * 100))%)")
                    .font(.system(size: 12))
                    .foregroundColor(.gray)
            }

            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color(white: 0.2))
                        .frame(height: 8)

                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color.rarityColor(for: rarity))
                        .frame(width: geometry.size.width * percentage, height: 8)
                }
            }
            .frame(height: 8)
        }
    }
}

#Preview {
    StatsView()
        .environmentObject(DataManager.shared)
}
