import Foundation
import SwiftUI

@MainActor
class CollectionViewModel: ObservableObject {
    @Published var searchText = ""
    @Published var selectedFilter: FilterOption = .all
    @Published var selectedSort: SortOption = .dateAdded
    @Published var showingFilterSheet = false
    @Published var showingSortSheet = false
    @Published var selectedCard: CollectionCard?
    @Published var showingCardDetail = false

    private let dataManager: DataManager

    init(dataManager: DataManager = .shared) {
        self.dataManager = dataManager
    }

    var filteredCards: [CollectionCard] {
        dataManager.filteredAndSortedCards(
            filter: selectedFilter,
            sort: selectedSort,
            searchText: searchText
        )
    }

    var totalCards: Int {
        dataManager.collection.totalCards
    }

    var uniqueCards: Int {
        dataManager.collection.uniqueCards
    }

    var totalValue: Double {
        dataManager.collection.totalValueUsd
    }

    var formattedTotalValue: String {
        String(format: "$%.2f", totalValue)
    }

    var isEmpty: Bool {
        dataManager.collection.cards.isEmpty
    }

    func selectCard(_ card: CollectionCard) {
        selectedCard = card
        showingCardDetail = true
    }

    func incrementQuantity(for card: CollectionCard) {
        dataManager.incrementQuantity(for: card)
    }

    func decrementQuantity(for card: CollectionCard) {
        dataManager.decrementQuantity(for: card)
    }

    func removeCard(_ card: CollectionCard) {
        dataManager.removeCard(card)
    }

    func refreshPrices() async {
        await dataManager.refreshPrices()
    }
}
