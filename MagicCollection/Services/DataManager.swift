import Foundation
import SwiftUI

@MainActor
class DataManager: ObservableObject {
    static let shared = DataManager()

    @Published var collection: CardCollection
    @Published var isLoading = false
    @Published var error: String?

    private let saveKey = "magic_collection"
    private let fileManager = FileManager.default

    private var documentsDirectory: URL {
        fileManager.urls(for: .documentDirectory, in: .userDomainMask)[0]
    }

    private var collectionFileURL: URL {
        documentsDirectory.appendingPathComponent("collection.json")
    }

    private init() {
        self.collection = CardCollection(name: "My Collection")
        loadCollection()
    }

    // MARK: - Persistence

    func loadCollection() {
        do {
            if fileManager.fileExists(atPath: collectionFileURL.path) {
                let data = try Data(contentsOf: collectionFileURL)
                let decoder = JSONDecoder()
                decoder.dateDecodingStrategy = .iso8601
                collection = try decoder.decode(CardCollection.self, from: data)
            }
        } catch {
            print("Failed to load collection: \(error)")
            // Try UserDefaults as fallback
            if let data = UserDefaults.standard.data(forKey: saveKey) {
                do {
                    let decoder = JSONDecoder()
                    decoder.dateDecodingStrategy = .iso8601
                    collection = try decoder.decode(CardCollection.self, from: data)
                } catch {
                    print("Failed to load from UserDefaults: \(error)")
                }
            }
        }
    }

    func saveCollection() {
        do {
            let encoder = JSONEncoder()
            encoder.dateEncodingStrategy = .iso8601
            encoder.outputFormatting = .prettyPrinted
            let data = try encoder.encode(collection)

            // Save to file
            try data.write(to: collectionFileURL)

            // Also save to UserDefaults as backup
            UserDefaults.standard.set(data, forKey: saveKey)
        } catch {
            print("Failed to save collection: \(error)")
            self.error = "Failed to save collection"
        }
    }

    // MARK: - Card Management

    func addCard(_ scryfallCard: ScryfallCard, quantity: Int = 1, isFoil: Bool = false) {
        let collectionCard = CollectionCard(from: scryfallCard, quantity: quantity, isFoil: isFoil)
        collection.addCard(collectionCard)
        saveCollection()
    }

    func removeCard(_ card: CollectionCard) {
        collection.removeCard(card)
        saveCollection()
    }

    func updateQuantity(for card: CollectionCard, newQuantity: Int) {
        collection.updateCardQuantity(card, newQuantity: newQuantity)
        saveCollection()
    }

    func incrementQuantity(for card: CollectionCard) {
        updateQuantity(for: card, newQuantity: card.quantity + 1)
    }

    func decrementQuantity(for card: CollectionCard) {
        updateQuantity(for: card, newQuantity: card.quantity - 1)
    }

    // MARK: - Filtering & Sorting

    func filteredAndSortedCards(filter: FilterOption, sort: SortOption, searchText: String = "") -> [CollectionCard] {
        var cards = collection.cards

        // Apply search
        if !searchText.isEmpty {
            cards = cards.filter { card in
                card.name.localizedCaseInsensitiveContains(searchText) ||
                (card.setName?.localizedCaseInsensitiveContains(searchText) ?? false) ||
                (card.typeLine?.localizedCaseInsensitiveContains(searchText) ?? false)
            }
        }

        // Apply filter
        switch filter {
        case .all:
            break
        case .common:
            cards = cards.filter { $0.rarity?.lowercased() == "common" }
        case .uncommon:
            cards = cards.filter { $0.rarity?.lowercased() == "uncommon" }
        case .rare:
            cards = cards.filter { $0.rarity?.lowercased() == "rare" }
        case .mythic:
            cards = cards.filter { $0.rarity?.lowercased() == "mythic" }
        case .foil:
            cards = cards.filter { $0.isFoil }
        }

        // Apply sort
        switch sort {
        case .name:
            cards.sort { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending }
        case .dateAdded:
            cards.sort { $0.dateAdded > $1.dateAdded }
        case .priceAsc:
            cards.sort { ($0.cachedPriceUsd.flatMap(Double.init) ?? 0) < ($1.cachedPriceUsd.flatMap(Double.init) ?? 0) }
        case .priceDesc:
            cards.sort { ($0.cachedPriceUsd.flatMap(Double.init) ?? 0) > ($1.cachedPriceUsd.flatMap(Double.init) ?? 0) }
        case .rarity:
            let rarityOrder = ["mythic": 0, "rare": 1, "uncommon": 2, "common": 3]
            cards.sort { (rarityOrder[$0.rarity?.lowercased() ?? ""] ?? 4) < (rarityOrder[$1.rarity?.lowercased() ?? ""] ?? 4) }
        case .setName:
            cards.sort { ($0.setName ?? "").localizedCaseInsensitiveCompare($1.setName ?? "") == .orderedAscending }
        }

        return cards
    }

    // MARK: - Price Refresh

    func refreshPrices() async {
        isLoading = true
        defer { isLoading = false }

        do {
            let pricesMap = try await ScryfallService.shared.refreshPrices(for: collection.cards)

            for (index, card) in collection.cards.enumerated() {
                if let prices = pricesMap[card.scryfallId] {
                    collection.cards[index].cachedPriceUsd = card.isFoil ? prices.usdFoil : prices.usd
                    collection.cards[index].cachedPriceEur = card.isFoil ? prices.eurFoil : prices.eur
                    collection.cards[index].lastPriceUpdate = Date()
                }
            }

            saveCollection()
        } catch {
            self.error = "Failed to refresh prices: \(error.localizedDescription)"
        }
    }

    // MARK: - Statistics

    var statistics: CollectionStatistics {
        CollectionStatistics(from: collection)
    }

    // MARK: - Export

    func exportToCSV() -> String {
        var csv = "Name,Set,Collector Number,Rarity,Quantity,Foil,Price (USD),Price (EUR),Date Added\n"

        for card in collection.cards {
            let row = [
                "\"\(card.name)\"",
                "\"\(card.setName ?? "")\"",
                "\"\(card.collectorNumber ?? "")\"",
                "\"\(card.rarity ?? "")\"",
                "\(card.quantity)",
                card.isFoil ? "Yes" : "No",
                card.cachedPriceUsd ?? "",
                card.cachedPriceEur ?? "",
                ISO8601DateFormatter().string(from: card.dateAdded)
            ].joined(separator: ",")
            csv += row + "\n"
        }

        return csv
    }
}
