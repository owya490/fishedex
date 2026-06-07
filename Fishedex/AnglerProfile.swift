import Foundation

struct ProfileRow: Codable, Identifiable {
    let id: UUID
    var displayName: String?
    var avatarUrl: String?
    var level: Int
    var statusTitle: String
    var rankLabel: String
    var currentBiome: String

    enum CodingKeys: String, CodingKey {
        case id
        case displayName = "display_name"
        case avatarUrl = "avatar_url"
        case level
        case statusTitle = "status_title"
        case rankLabel = "rank_label"
        case currentBiome = "current_biome"
    }
}

struct FishSpeciesRow: Codable, Identifiable {
    let id: Int
    let name: String
    let scientificName: String
    let imageName: String
    let habitat: String
    let rarityStars: Int
    let isRare: Bool
    let about: String?

    enum CodingKeys: String, CodingKey {
        case id, name, habitat, about
        case scientificName = "scientific_name"
        case imageName = "image_name"
        case rarityStars = "rarity_stars"
        case isRare = "is_rare"
    }
}

struct UserCatchRow: Codable, Identifiable {
    let id: UUID
    let userId: UUID
    let speciesId: Int?
    let customName: String?
    let weightKg: Double?
    let lengthCm: Double?
    let locationName: String?
    let latitude: Double?
    let longitude: Double?
    let notes: String?
    let bait: String?
    let photoUrl: String?
    let caughtAt: Date

    var displayName: String {
        if let customName, !customName.isEmpty { return customName }
        return "Unknown fish"
    }

    enum CodingKeys: String, CodingKey {
        case id
        case userId = "user_id"
        case speciesId = "species_id"
        case customName = "custom_name"
        case weightKg = "weight_kg"
        case lengthCm = "length_cm"
        case locationName = "location_name"
        case latitude, longitude, notes, bait
        case photoUrl = "photo_url"
        case caughtAt = "caught_at"
    }
}

struct CatchPhotoRow: Codable, Identifiable {
    let id: UUID
    let catchId: UUID
    let userId: UUID
    let photoUrl: String
    let storagePath: String
    let sortOrder: Int
    let createdAt: Date

    enum CodingKeys: String, CodingKey {
        case id
        case catchId = "catch_id"
        case userId = "user_id"
        case photoUrl = "photo_url"
        case storagePath = "storage_path"
        case sortOrder = "sort_order"
        case createdAt = "created_at"
    }
}

struct LogCatchInput {
    var speciesId: Int?
    var fishName: String?
    var weightKg: Double?
    var lengthCm: Double?
    var locationName: String?
    var latitude: Double?
    var longitude: Double?
    var caughtAt: Date
    var bait: String?
    var notes: String?
    var photoData: Data?
}

struct UpdateCatchInput {
    var customName: String?
    var weightKg: Double?
    var lengthCm: Double?
    var locationName: String?
    var bait: String?
    var notes: String?
    var caughtAt: Date?
}

struct AchievementRow: Codable, Identifiable {
    let id: Int
    let slug: String
    let title: String
    let description: String
    let sortOrder: Int

    enum CodingKeys: String, CodingKey {
        case id, slug, title, description
        case sortOrder = "sort_order"
    }
}

struct UserAchievementRow: Codable, Identifiable {
    let id: UUID
    let userId: UUID
    let achievementId: Int
    let unlockedAt: Date

    enum CodingKeys: String, CodingKey {
        case id
        case userId = "user_id"
        case achievementId = "achievement_id"
        case unlockedAt = "unlocked_at"
    }
}

struct AnglerStats {
    let caughtCount: Int
    let totalSpecies: Int
    let rareCaughtCount: Int
    let totalWeightKg: Double
    let unlockedAchievements: Int
    let totalAchievements: Int

    var progress: Double {
        guard totalSpecies > 0 else { return 0 }
        return Double(caughtCount) / Double(totalSpecies)
    }

    var progressPercentText: String {
        String(format: "%.1f%%", progress * 100)
    }

    var flavorText: String {
        switch progress {
        case 0.9...: return "Almost a King..."
        case 0.75..<0.9: return "Elite collector."
        case 0.5..<0.75: return "Seasoned angler."
        case 0.25..<0.5: return "Waters warming up."
        default: return "Cast your first line."
        }
    }
}
