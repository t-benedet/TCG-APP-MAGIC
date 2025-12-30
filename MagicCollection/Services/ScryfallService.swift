import Foundation

enum ScryfallError: Error, LocalizedError {
    case invalidURL
    case networkError(Error)
    case decodingError(Error)
    case noResults
    case rateLimited
    case serverError(Int)

    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "Invalid URL"
        case .networkError(let error):
            return "Network error: \(error.localizedDescription)"
        case .decodingError(let error):
            return "Failed to parse response: \(error.localizedDescription)"
        case .noResults:
            return "No cards found"
        case .rateLimited:
            return "Too many requests. Please wait a moment."
        case .serverError(let code):
            return "Server error: \(code)"
        }
    }
}

actor ScryfallService {
    static let shared = ScryfallService()

    private let baseURL = "https://api.scryfall.com"
    private let session: URLSession
    private var lastRequestTime: Date?
    private let minimumRequestInterval: TimeInterval = 0.1 // 100ms between requests

    private init() {
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 30
        config.timeoutIntervalForResource = 60
        self.session = URLSession(configuration: config)
    }

    // MARK: - Rate Limiting

    private func waitForRateLimit() async {
        if let lastRequest = lastRequestTime {
            let elapsed = Date().timeIntervalSince(lastRequest)
            if elapsed < minimumRequestInterval {
                try? await Task.sleep(nanoseconds: UInt64((minimumRequestInterval - elapsed) * 1_000_000_000))
            }
        }
        lastRequestTime = Date()
    }

    // MARK: - Search Cards

    func searchCards(query: String, page: Int = 1) async throws -> ScryfallSearchResponse {
        await waitForRateLimit()

        guard var components = URLComponents(string: "\(baseURL)/cards/search") else {
            throw ScryfallError.invalidURL
        }

        components.queryItems = [
            URLQueryItem(name: "q", value: query),
            URLQueryItem(name: "page", value: String(page)),
            URLQueryItem(name: "unique", value: "prints")
        ]

        guard let url = components.url else {
            throw ScryfallError.invalidURL
        }

        return try await performRequest(url: url)
    }

    // MARK: - Get Card by ID

    func getCard(id: String) async throws -> ScryfallCard {
        await waitForRateLimit()

        guard let url = URL(string: "\(baseURL)/cards/\(id)") else {
            throw ScryfallError.invalidURL
        }

        return try await performRequest(url: url)
    }

    // MARK: - Autocomplete

    func autocomplete(query: String) async throws -> [String] {
        await waitForRateLimit()

        guard var components = URLComponents(string: "\(baseURL)/cards/autocomplete") else {
            throw ScryfallError.invalidURL
        }

        components.queryItems = [
            URLQueryItem(name: "q", value: query)
        ]

        guard let url = components.url else {
            throw ScryfallError.invalidURL
        }

        struct AutocompleteResponse: Codable {
            let data: [String]
        }

        let response: AutocompleteResponse = try await performRequest(url: url)
        return response.data
    }

    // MARK: - Get Random Card

    func getRandomCard() async throws -> ScryfallCard {
        await waitForRateLimit()

        guard let url = URL(string: "\(baseURL)/cards/random") else {
            throw ScryfallError.invalidURL
        }

        return try await performRequest(url: url)
    }

    // MARK: - Get Card by Name (exact or fuzzy)

    func getCardByName(_ name: String, exact: Bool = false) async throws -> ScryfallCard {
        await waitForRateLimit()

        guard var components = URLComponents(string: "\(baseURL)/cards/named") else {
            throw ScryfallError.invalidURL
        }

        components.queryItems = [
            URLQueryItem(name: exact ? "exact" : "fuzzy", value: name)
        ]

        guard let url = components.url else {
            throw ScryfallError.invalidURL
        }

        return try await performRequest(url: url)
    }

    // MARK: - Refresh Card Prices

    func refreshPrices(for cards: [CollectionCard]) async throws -> [String: CardPrices] {
        var pricesMap: [String: CardPrices] = [:]

        // Process in batches to respect rate limits
        for card in cards {
            do {
                let updatedCard = try await getCard(id: card.scryfallId)
                if let prices = updatedCard.prices {
                    pricesMap[card.scryfallId] = prices
                }
            } catch {
                // Continue with other cards if one fails
                continue
            }
        }

        return pricesMap
    }

    // MARK: - Private Request Handler

    private func performRequest<T: Decodable>(url: URL) async throws -> T {
        var request = URLRequest(url: url)
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        request.setValue("MagicCollectionApp/1.0", forHTTPHeaderField: "User-Agent")

        do {
            let (data, response) = try await session.data(for: request)

            guard let httpResponse = response as? HTTPURLResponse else {
                throw ScryfallError.networkError(NSError(domain: "Invalid response", code: 0))
            }

            switch httpResponse.statusCode {
            case 200:
                do {
                    let decoder = JSONDecoder()
                    return try decoder.decode(T.self, from: data)
                } catch {
                    throw ScryfallError.decodingError(error)
                }
            case 404:
                throw ScryfallError.noResults
            case 429:
                throw ScryfallError.rateLimited
            default:
                throw ScryfallError.serverError(httpResponse.statusCode)
            }
        } catch let error as ScryfallError {
            throw error
        } catch {
            throw ScryfallError.networkError(error)
        }
    }
}

// MARK: - Price Platforms

enum PricePlatform: String, CaseIterable, Identifiable {
    case tcgplayer = "TCGPlayer"
    case cardmarket = "Cardmarket"
    case cardhoarder = "Cardhoarder"

    var id: String { rawValue }

    var iconName: String {
        switch self {
        case .tcgplayer: return "dollarsign.circle.fill"
        case .cardmarket: return "eurosign.circle.fill"
        case .cardhoarder: return "ticket.fill"
        }
    }

    var currency: String {
        switch self {
        case .tcgplayer: return "USD"
        case .cardmarket: return "EUR"
        case .cardhoarder: return "TIX"
        }
    }

    var currencySymbol: String {
        switch self {
        case .tcgplayer: return "$"
        case .cardmarket: return "€"
        case .cardhoarder: return ""
        }
    }

    func price(from prices: CardPrices?, isFoil: Bool) -> String? {
        guard let prices = prices else { return nil }
        switch self {
        case .tcgplayer:
            return isFoil ? prices.usdFoil : prices.usd
        case .cardmarket:
            return isFoil ? prices.eurFoil : prices.eur
        case .cardhoarder:
            return prices.tix
        }
    }

    func url(from purchaseUris: PurchaseUris?) -> URL? {
        guard let uris = purchaseUris else { return nil }
        switch self {
        case .tcgplayer:
            return uris.tcgplayer.flatMap { URL(string: $0) }
        case .cardmarket:
            return uris.cardmarket.flatMap { URL(string: $0) }
        case .cardhoarder:
            return uris.cardhoarder.flatMap { URL(string: $0) }
        }
    }
}
