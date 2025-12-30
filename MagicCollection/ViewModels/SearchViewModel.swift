import Foundation
import SwiftUI
import Combine

@MainActor
class SearchViewModel: ObservableObject {
    @Published var searchText = ""
    @Published var searchResults: [ScryfallCard] = []
    @Published var suggestions: [String] = []
    @Published var isLoading = false
    @Published var error: String?
    @Published var hasMoreResults = false
    @Published var selectedCard: ScryfallCard?
    @Published var showingAddSheet = false

    private var currentPage = 1
    private var currentQuery = ""
    private var searchTask: Task<Void, Never>?
    private var autocompleteTask: Task<Void, Never>?

    private let dataManager: DataManager

    init(dataManager: DataManager = .shared) {
        self.dataManager = dataManager
    }

    func search() {
        guard !searchText.trimmingCharacters(in: .whitespaces).isEmpty else {
            searchResults = []
            suggestions = []
            return
        }

        searchTask?.cancel()
        currentQuery = searchText
        currentPage = 1

        searchTask = Task {
            isLoading = true
            error = nil

            do {
                let response = try await ScryfallService.shared.searchCards(query: searchText)
                if !Task.isCancelled {
                    searchResults = response.data
                    hasMoreResults = response.hasMore ?? false
                }
            } catch let scryfallError as ScryfallError {
                if !Task.isCancelled {
                    if case .noResults = scryfallError {
                        searchResults = []
                        error = nil
                    } else {
                        error = scryfallError.localizedDescription
                    }
                }
            } catch {
                if !Task.isCancelled {
                    self.error = error.localizedDescription
                }
            }

            if !Task.isCancelled {
                isLoading = false
            }
        }
    }

    func loadMoreResults() {
        guard hasMoreResults, !isLoading else { return }

        searchTask?.cancel()
        currentPage += 1

        searchTask = Task {
            isLoading = true

            do {
                let response = try await ScryfallService.shared.searchCards(query: currentQuery, page: currentPage)
                if !Task.isCancelled {
                    searchResults.append(contentsOf: response.data)
                    hasMoreResults = response.hasMore ?? false
                }
            } catch {
                if !Task.isCancelled {
                    currentPage -= 1
                }
            }

            if !Task.isCancelled {
                isLoading = false
            }
        }
    }

    func fetchAutocomplete() {
        guard searchText.count >= 2 else {
            suggestions = []
            return
        }

        autocompleteTask?.cancel()

        autocompleteTask = Task {
            do {
                let results = try await ScryfallService.shared.autocomplete(query: searchText)
                if !Task.isCancelled {
                    suggestions = Array(results.prefix(5))
                }
            } catch {
                if !Task.isCancelled {
                    suggestions = []
                }
            }
        }
    }

    func selectSuggestion(_ suggestion: String) {
        searchText = suggestion
        suggestions = []
        search()
    }

    func selectCard(_ card: ScryfallCard) {
        selectedCard = card
        showingAddSheet = true
    }

    func addCardToCollection(quantity: Int, isFoil: Bool) {
        guard let card = selectedCard else { return }
        dataManager.addCard(card, quantity: quantity, isFoil: isFoil)
        showingAddSheet = false
        selectedCard = nil
    }

    func clearSearch() {
        searchText = ""
        searchResults = []
        suggestions = []
        error = nil
    }

    func getRandomCard() {
        searchTask?.cancel()

        searchTask = Task {
            isLoading = true
            error = nil

            do {
                let card = try await ScryfallService.shared.getRandomCard()
                if !Task.isCancelled {
                    searchResults = [card]
                    hasMoreResults = false
                }
            } catch {
                if !Task.isCancelled {
                    self.error = error.localizedDescription
                }
            }

            if !Task.isCancelled {
                isLoading = false
            }
        }
    }
}
