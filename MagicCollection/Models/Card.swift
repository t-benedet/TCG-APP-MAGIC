import Foundation

// MARK: - Scryfall API Response Models

struct ScryfallSearchResponse: Codable {
    let object: String
    let totalCards: Int?
    let hasMore: Bool?
    let data: [ScryfallCard]

    enum CodingKeys: String, CodingKey {
        case object
        case totalCards = "total_cards"
        case hasMore = "has_more"
        case data
    }
}

struct ScryfallCard: Codable, Identifiable {
    let id: String
    let oracleId: String?
    let name: String
    let lang: String?
    let releasedAt: String?
    let uri: String?
    let scryfallUri: String?
    let layout: String?
    let manaCost: String?
    let cmc: Double?
    let typeLine: String?
    let oracleText: String?
    let power: String?
    let toughness: String?
    let colors: [String]?
    let colorIdentity: [String]?
    let keywords: [String]?
    let setCode: String?
    let setName: String?
    let collectorNumber: String?
    let rarity: String?
    let flavorText: String?
    let artist: String?
    let prices: CardPrices?
    let imageUris: ImageUris?
    let cardFaces: [CardFace]?
    let purchaseUris: PurchaseUris?

    enum CodingKeys: String, CodingKey {
        case id
        case oracleId = "oracle_id"
        case name, lang
        case releasedAt = "released_at"
        case uri
        case scryfallUri = "scryfall_uri"
        case layout
        case manaCost = "mana_cost"
        case cmc
        case typeLine = "type_line"
        case oracleText = "oracle_text"
        case power, toughness, colors
        case colorIdentity = "color_identity"
        case keywords
        case setCode = "set"
        case setName = "set_name"
        case collectorNumber = "collector_number"
        case rarity
        case flavorText = "flavor_text"
        case artist, prices
        case imageUris = "image_uris"
        case cardFaces = "card_faces"
        case purchaseUris = "purchase_uris"
    }

    var displayImageUrl: String? {
        if let imageUris = imageUris {
            return imageUris.large ?? imageUris.normal ?? imageUris.small
        }
        if let faces = cardFaces, let firstFace = faces.first {
            return firstFace.imageUris?.large ?? firstFace.imageUris?.normal ?? firstFace.imageUris?.small
        }
        return nil
    }

    var thumbnailUrl: String? {
        if let imageUris = imageUris {
            return imageUris.small ?? imageUris.normal
        }
        if let faces = cardFaces, let firstFace = faces.first {
            return firstFace.imageUris?.small ?? firstFace.imageUris?.normal
        }
        return nil
    }

    var formattedRarity: String {
        guard let rarity = rarity else { return "Unknown" }
        return rarity.capitalized
    }

    var rarityColor: String {
        switch rarity?.lowercased() {
        case "common": return "rarityCommon"
        case "uncommon": return "rarityUncommon"
        case "rare": return "rarityRare"
        case "mythic": return "rarityMythic"
        default: return "rarityCommon"
        }
    }
}

struct ImageUris: Codable {
    let small: String?
    let normal: String?
    let large: String?
    let png: String?
    let artCrop: String?
    let borderCrop: String?

    enum CodingKeys: String, CodingKey {
        case small, normal, large, png
        case artCrop = "art_crop"
        case borderCrop = "border_crop"
    }
}

struct CardFace: Codable {
    let name: String?
    let manaCost: String?
    let typeLine: String?
    let oracleText: String?
    let flavorText: String?
    let artist: String?
    let imageUris: ImageUris?

    enum CodingKeys: String, CodingKey {
        case name
        case manaCost = "mana_cost"
        case typeLine = "type_line"
        case oracleText = "oracle_text"
        case flavorText = "flavor_text"
        case artist
        case imageUris = "image_uris"
    }
}

struct CardPrices: Codable {
    let usd: String?
    let usdFoil: String?
    let usdEtched: String?
    let eur: String?
    let eurFoil: String?
    let tix: String?

    enum CodingKeys: String, CodingKey {
        case usd
        case usdFoil = "usd_foil"
        case usdEtched = "usd_etched"
        case eur
        case eurFoil = "eur_foil"
        case tix
    }

    var hasAnyPrice: Bool {
        usd != nil || usdFoil != nil || eur != nil || eurFoil != nil || tix != nil
    }
}

struct PurchaseUris: Codable {
    let tcgplayer: String?
    let cardmarket: String?
    let cardhoarder: String?
}

// MARK: - Collection Card Model (for persistence)

struct CollectionCard: Codable, Identifiable {
    let id: UUID
    let scryfallId: String
    let name: String
    let setCode: String?
    let setName: String?
    let collectorNumber: String?
    let rarity: String?
    let imageUrl: String?
    let thumbnailUrl: String?
    var quantity: Int
    var isFoil: Bool
    let dateAdded: Date
    let manaCost: String?
    let typeLine: String?
    let artist: String?

    // Cached prices (updated on demand)
    var cachedPriceUsd: String?
    var cachedPriceEur: String?
    var lastPriceUpdate: Date?

    init(from scryfallCard: ScryfallCard, quantity: Int = 1, isFoil: Bool = false) {
        self.id = UUID()
        self.scryfallId = scryfallCard.id
        self.name = scryfallCard.name
        self.setCode = scryfallCard.setCode
        self.setName = scryfallCard.setName
        self.collectorNumber = scryfallCard.collectorNumber
        self.rarity = scryfallCard.rarity
        self.imageUrl = scryfallCard.displayImageUrl
        self.thumbnailUrl = scryfallCard.thumbnailUrl
        self.quantity = quantity
        self.isFoil = isFoil
        self.dateAdded = Date()
        self.manaCost = scryfallCard.manaCost
        self.typeLine = scryfallCard.typeLine
        self.artist = scryfallCard.artist
        self.cachedPriceUsd = isFoil ? scryfallCard.prices?.usdFoil : scryfallCard.prices?.usd
        self.cachedPriceEur = isFoil ? scryfallCard.prices?.eurFoil : scryfallCard.prices?.eur
        self.lastPriceUpdate = Date()
    }

    var formattedRarity: String {
        guard let rarity = rarity else { return "Unknown" }
        return rarity.capitalized
    }

    var rarityColor: String {
        switch rarity?.lowercased() {
        case "common": return "rarityCommon"
        case "uncommon": return "rarityUncommon"
        case "rare": return "rarityRare"
        case "mythic": return "rarityMythic"
        default: return "rarityCommon"
        }
    }

    var totalValueUsd: Double? {
        guard let priceStr = cachedPriceUsd, let price = Double(priceStr) else { return nil }
        return price * Double(quantity)
    }

    var totalValueEur: Double? {
        guard let priceStr = cachedPriceEur, let price = Double(priceStr) else { return nil }
        return price * Double(quantity)
    }
}

// MARK: - Mana Symbol Helper

enum ManaColor: String, CaseIterable {
    case white = "W"
    case blue = "U"
    case black = "B"
    case red = "R"
    case green = "G"
    case colorless = "C"

    var displayName: String {
        switch self {
        case .white: return "White"
        case .blue: return "Blue"
        case .black: return "Black"
        case .red: return "Red"
        case .green: return "Green"
        case .colorless: return "Colorless"
        }
    }

    var symbolColor: String {
        switch self {
        case .white: return "manaWhite"
        case .blue: return "manaBlue"
        case .black: return "manaBlack"
        case .red: return "manaRed"
        case .green: return "manaGreen"
        case .colorless: return "manaColorless"
        }
    }
}
