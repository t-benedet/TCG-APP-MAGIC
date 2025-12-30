import Foundation

struct CardCollection: Codable, Identifiable {
    let id: UUID
    var name: String
    var cards: [CollectionCard]
    let dateCreated: Date
    var lastModified: Date
    var iconName: String

    init(name: String, iconName: String = "rectangle.stack.fill") {
        self.id = UUID()
        self.name = name
        self.cards = []
        self.dateCreated = Date()
        self.lastModified = Date()
        self.iconName = iconName
    }

    var totalCards: Int {
        cards.reduce(0) { $0 + $1.quantity }
    }

    var uniqueCards: Int {
        cards.count
    }

    var totalValueUsd: Double {
        cards.compactMap { $0.totalValueUsd }.reduce(0, +)
    }

    var totalValueEur: Double {
        cards.compactMap { $0.totalValueEur }.reduce(0, +)
    }

    var cardsByRarity: [String: Int] {
        var result: [String: Int] = [:]
        for card in cards {
            let rarity = card.rarity ?? "unknown"
            result[rarity, default: 0] += card.quantity
        }
        return result
    }

    var cardsByColor: [String: Int] {
        var result: [String: Int] = [:]
        for card in cards {
            if let manaCost = card.manaCost {
                for color in ManaColor.allCases {
                    if manaCost.contains(color.rawValue) {
                        result[color.displayName, default: 0] += card.quantity
                    }
                }
                if !ManaColor.allCases.dropLast().contains(where: { manaCost.contains($0.rawValue) }) {
                    result["Colorless", default: 0] += card.quantity
                }
            }
        }
        return result
    }

    mutating func addCard(_ card: CollectionCard) {
        if let index = cards.firstIndex(where: { $0.scryfallId == card.scryfallId && $0.isFoil == card.isFoil }) {
            cards[index].quantity += card.quantity
        } else {
            cards.append(card)
        }
        lastModified = Date()
    }

    mutating func removeCard(_ card: CollectionCard) {
        cards.removeAll { $0.id == card.id }
        lastModified = Date()
    }

    mutating func updateCardQuantity(_ card: CollectionCard, newQuantity: Int) {
        if let index = cards.firstIndex(where: { $0.id == card.id }) {
            if newQuantity <= 0 {
                cards.remove(at: index)
            } else {
                cards[index].quantity = newQuantity
            }
        }
        lastModified = Date()
    }
}

// MARK: - Filter & Sort Options

enum SortOption: String, CaseIterable {
    case name = "Name"
    case dateAdded = "Date Added"
    case priceAsc = "Price (Low to High)"
    case priceDesc = "Price (High to Low)"
    case rarity = "Rarity"
    case setName = "Set"

    var icon: String {
        switch self {
        case .name: return "textformat"
        case .dateAdded: return "calendar"
        case .priceAsc: return "arrow.up"
        case .priceDesc: return "arrow.down"
        case .rarity: return "star.fill"
        case .setName: return "rectangle.stack"
        }
    }
}

enum FilterOption: String, CaseIterable {
    case all = "All"
    case common = "Common"
    case uncommon = "Uncommon"
    case rare = "Rare"
    case mythic = "Mythic"
    case foil = "Foil Only"

    var icon: String {
        switch self {
        case .all: return "square.grid.2x2"
        case .common: return "circle"
        case .uncommon: return "diamond"
        case .rare: return "star"
        case .mythic: return "star.fill"
        case .foil: return "sparkles"
        }
    }
}

// MARK: - Statistics

struct CollectionStatistics {
    let totalCards: Int
    let uniqueCards: Int
    let totalValueUsd: Double
    let totalValueEur: Double
    let cardsByRarity: [String: Int]
    let cardsByColor: [String: Int]
    let mostValuableCards: [CollectionCard]
    let recentlyAdded: [CollectionCard]

    init(from collection: CardCollection) {
        self.totalCards = collection.totalCards
        self.uniqueCards = collection.uniqueCards
        self.totalValueUsd = collection.totalValueUsd
        self.totalValueEur = collection.totalValueEur
        self.cardsByRarity = collection.cardsByRarity
        self.cardsByColor = collection.cardsByColor
        self.mostValuableCards = collection.cards
            .sorted { ($0.totalValueUsd ?? 0) > ($1.totalValueUsd ?? 0) }
            .prefix(5)
            .map { $0 }
        self.recentlyAdded = collection.cards
            .sorted { $0.dateAdded > $1.dateAdded }
            .prefix(5)
            .map { $0 }
    }
}
