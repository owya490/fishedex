import Foundation

enum FishDetailTab: String, CaseIterable, Identifiable {
    case about = "About"
    case status = "Status"
    case gallery = "Gallery"
    case myFish = "My Fish"

    var id: String { rawValue }
}

struct Fish: Identifiable, Hashable {
    let id: Int
    let name: String
    let scientificName: String
    let imageName: String
    let habitat: String
    let rarity: String
    let season: String
    let depth: String
    let height: String
    let weight: String
    let avgWeight: String
    let prefBait: String
    let location: String
    let rarityStars: Int
    let waterType: String
    let about: String
    let caught: Bool
    let traits: [String]
    let moves: [String]
    let stats: [FishStat]

    var number: String {
        "#\(String(format: "%03d", id))"
    }
}

struct FishStat: Identifiable, Hashable {
    let name: String
    let value: Int

    var id: String { name }
}

// MARK: - Supabase mapping

extension Fish {
    static func from(species row: FishSpeciesRow, caught: Bool, catchWeight: Double? = nil) -> Fish {
        let rarity = caught ? (row.isRare ? "Rare" : "Captured") : "Uncaptured"
        let weightText = catchWeight.map { String(format: "%.1f kg", $0) } ?? "TBC"
        return species(
            row.id,
            row.name,
            imageName: row.imageName,
            habitat: row.habitat,
            rarity: rarity,
            season: "All year",
            caught: caught,
            about: row.about ?? "\(row.name) is part of the Australian Fishédex catalog. Add artwork and catch notes as you unlock this species.",
            weight: weightText
        )
    }
}

// MARK: - Catalog

extension Fish {
    static let samples: [Fish] = catalog.enumerated().map { index, entry in
        let imageName = assetName(for: entry.name)
        return species(
            index + 1,
            entry.name,
            imageName: imageName,
            habitat: entry.habitat,
            rarity: imageName == "MysteryFish" ? "Uncaptured" : "Captured",
            season: "All year",
            caught: imageName != "MysteryFish"
        )
    }

    private static let catalog: [CatalogEntry] = [
        CatalogEntry("Albacore", "Offshore"),
        CatalogEntry("Amberjack", "Offshore"),
        CatalogEntry("Atlantic Salmon", "Coastal"),
        CatalogEntry("Australian Bass", "River"),
        CatalogEntry("Australian Salmon", "Surf beach"),
        CatalogEntry("Australian Sawtail", "Reef"),
        CatalogEntry("Balmain Bug", "Sand flats"),
        CatalogEntry("Banded Rock Cod (Bar Cod)", "Reef"),
        CatalogEntry("Bass Groper", "Deep reef"),
        CatalogEntry("Brook Trout", "Highland stream"),
        CatalogEntry("Brown Trout", "Highland stream"),
        CatalogEntry("Beach Worm", "Surf beach"),
        CatalogEntry("Bigeye Tuna", "Offshore"),
        CatalogEntry("Black Bream", "Estuary"),
        CatalogEntry("Blacklip Abalone", "Rock reef"),
        CatalogEntry("Blue-eye Trevalla", "Deep reef"),
        CatalogEntry("Blue Groper", "Rock reef"),
        CatalogEntry("Blue Swimmer Crab", "Bay"),
        CatalogEntry("Bluefish", "Surf beach"),
        CatalogEntry("Bonito", "Coastal"),
        CatalogEntry("Carp", "River"),
        CatalogEntry("Cobia", "Offshore"),
        CatalogEntry("Cockles", "Sand flats"),
        CatalogEntry("Commercial Scallop", "Bay"),
        CatalogEntry("Cunjevoi", "Rock reef"),
        CatalogEntry("Cuttlefish", "Reef"),
        CatalogEntry("Eastern Red Scorpionfish (Red Rock Cod)", "Rock reef"),
        CatalogEntry("Eastern Rock Lobster", "Rock reef"),
        CatalogEntry("Eastern School Whiting", "Sand flats"),
        CatalogEntry("Eels (Short and Long-finned)", "River"),
        CatalogEntry("Estuary Perch", "Estuary"),
        CatalogEntry("Flathead (Bluespotted)", "Sand flats"),
        CatalogEntry("Flathead (Dusky)", "Estuary"),
        CatalogEntry("Flathead (Tiger)", "Sand flats"),
        CatalogEntry("Flounder", "Sand flats"),
        CatalogEntry("Freshwater Catfish", "River"),
        CatalogEntry("Garfish", "Bay"),
        CatalogEntry("Gemfish", "Deep reef"),
        CatalogEntry("Golden Perch", "River"),
        CatalogEntry("Grey Morwong (Rubber Lip)", "Reef"),
        CatalogEntry("Hairtail", "Estuary"),
        CatalogEntry("Hapuku", "Deep reef"),
        CatalogEntry("Leatherjacket", "Reef"),
        CatalogEntry("Longtail Tuna", "Offshore"),
        CatalogEntry("Luderick", "Rock wash"),
        CatalogEntry("Mackerel (Narrow-barred Spanish)", "Offshore"),
        CatalogEntry("Mackerel (Spotted)", "Offshore"),
        CatalogEntry("Mahi Mahi (Dolphinfish)", "Bluewater"),
        CatalogEntry("Mangrove Jack", "Estuary"),
        CatalogEntry("Marlin (Black)", "Bluewater"),
        CatalogEntry("Marlin (Blue)", "Bluewater"),
        CatalogEntry("Marlin (Striped)", "Bluewater"),
        CatalogEntry("Morwong (Banded)", "Reef"),
        CatalogEntry("Morwong (Jackass)", "Reef"),
        CatalogEntry("Morwong (Red)", "Reef"),
        CatalogEntry("Moses Snapper", "Reef"),
        CatalogEntry("Mud Crab", "Estuary"),
        CatalogEntry("Mullet (Poddy)", "Estuary"),
        CatalogEntry("Mullet (Sea)", "Coastal"),
        CatalogEntry("Mulloway", "Estuary"),
        CatalogEntry("Murray Cod", "River"),
        CatalogEntry("Murray Crayfish", "River"),
        CatalogEntry("Native Oyster", "Estuary"),
        CatalogEntry("Octopus", "Reef"),
        CatalogEntry("Pacific Oyster", "Estuary"),
        CatalogEntry("Pearl Perch", "Reef"),
        CatalogEntry("Prawn - Black Tiger", "Estuary"),
        CatalogEntry("Prawn - School Prawn", "Estuary"),
        CatalogEntry("Purple Sea Urchin", "Reef"),
        CatalogEntry("Rainbow Trout", "Highland stream"),
        CatalogEntry("Redfin Perch", "Lake"),
        CatalogEntry("Rock Blackfish", "Rock wash"),
        CatalogEntry("Sailfish", "Bluewater"),
        CatalogEntry("Samsonfish", "Offshore"),
        CatalogEntry("Sand Whiting", "Sand flats"),
        CatalogEntry("Shark - Blue", "Offshore"),
        CatalogEntry("Shark - Hammerhead", "Offshore"),
        CatalogEntry("Shark - Mako", "Offshore"),
        CatalogEntry("Shark - School", "Offshore"),
        CatalogEntry("Shark - Whaler", "Offshore"),
        CatalogEntry("Shark - Wobbegong", "Reef"),
        CatalogEntry("Shortbill Spearfish", "Bluewater"),
        CatalogEntry("Silver Perch", "River"),
        CatalogEntry("Spiny Crayfish", "River"),
        CatalogEntry("Slipper Lobster", "Reef"),
        CatalogEntry("Snapper", "Reef"),
        CatalogEntry("Sole", "Sand flats"),
        CatalogEntry("Southern Bluefin Tuna", "Offshore"),
        CatalogEntry("Southern Rock Lobster", "Rock reef"),
        CatalogEntry("Spanner Crab", "Sand flats"),
        CatalogEntry("Squid", "Bay"),
        CatalogEntry("Swordfish", "Bluewater"),
        CatalogEntry("Sydney Rock Oyster", "Estuary"),
        CatalogEntry("Tailor", "Surf beach"),
        CatalogEntry("Tarwhine", "Estuary"),
        CatalogEntry("Teraglin", "Reef"),
        CatalogEntry("Trevallies", "Coastal"),
        CatalogEntry("Tropical Rock Lobster (Painted and Ornate)", "Tropical reef"),
        CatalogEntry("Turban Snails", "Rock reef"),
        CatalogEntry("Wahoo", "Bluewater"),
        CatalogEntry("Yabby", "River"),
        CatalogEntry("Yellowfin Bream", "Estuary"),
        CatalogEntry("Yellowfin Tuna", "Offshore"),
    ]

    private struct CatalogEntry {
        let name: String
        let habitat: String
        init(_ name: String, _ habitat: String) {
            self.name = name
            self.habitat = habitat
        }
    }

    private static func assetName(for name: String) -> String {
        switch name {
        case "Australian Salmon":         return "AustralianSalmon"
        case "Eels (Short and Long-finned)": return "ShortFinnedEel"
        case "Snapper":                   return "PinkSnapper"
        case "Yellowfin Bream":           return "YellowfinBream"
        default:                          return "MysteryFish"
        }
    }

    // MARK: - Derived metadata helpers

    private static func avgWeightEstimate(for habitat: String) -> String {
        if habitat.contains("Bluewater") { return "80+ kg" }
        if habitat.contains("Offshore") { return "18 kg" }
        if habitat.contains("Deep reef") { return "8.5 kg" }
        if habitat.contains("Reef") || habitat.contains("Rock") { return "2.3 kg" }
        if habitat.contains("Highland") { return "1.8 kg" }
        if habitat.contains("Estuary") { return "1.6 kg" }
        if habitat.contains("River") || habitat.contains("Lake") { return "1.2 kg" }
        if habitat.contains("Surf") || habitat.contains("Coastal") { return "2.1 kg" }
        return "1.5 kg"
    }

    private static func baitSuggestion(for habitat: String) -> String {
        if habitat.contains("Bluewater") || habitat.contains("Offshore") { return "Lure" }
        if habitat.contains("Reef") || habitat.contains("Rock") { return "Squid" }
        if habitat.contains("Estuary") { return "Prawn" }
        if habitat.contains("River") || habitat.contains("stream") || habitat.contains("Lake") { return "Worm" }
        if habitat.contains("Surf") || habitat.contains("beach") { return "Pilchard" }
        if habitat.contains("Bay") || habitat.contains("Sand") { return "Yabby" }
        return "Live bait"
    }

    private static func rarityStarCount(for habitat: String) -> Int {
        if habitat.contains("Bluewater") || habitat.contains("Deep reef") || habitat.contains("Tropical") { return 3 }
        if habitat.contains("Offshore") || habitat.contains("Highland") || habitat.contains("Rock wash") { return 2 }
        return 1
    }

    // MARK: - Factory

    private static func species(
        _ id: Int,
        _ name: String,
        imageName: String = "MysteryFish",
        habitat: String,
        rarity: String,
        season: String,
        caught: Bool,
        traits: [String]? = nil,
        about: String? = nil,
        weight: String = "TBC"
    ) -> Fish {
        Fish(
            id: id,
            name: name,
            scientificName: "Profile pending",
            imageName: imageName,
            habitat: habitat,
            rarity: rarity,
            season: season,
            depth: habitat.contains("Offshore") || habitat.contains("reef") ? "Deep" : "Shallow",
            height: "TBC",
            weight: weight,
            avgWeight: avgWeightEstimate(for: habitat),
            prefBait: baitSuggestion(for: habitat),
            location: habitat,
            rarityStars: rarityStarCount(for: habitat),
            waterType: habitat.contains("River") || habitat.contains("stream") || habitat.contains("Lake") ? "Freshwater" : "Saltwater",
            about: about ?? "\(name) is part of the Australian Fishédex catalog. Add artwork and catch notes as you unlock this species.",
            caught: caught,
            traits: traits ?? [habitat, rarity, season],
            moves: ["Cast", "Hook", "Land"],
            stats: [
                FishStat(name: "Speed",  value: caught ? 64 : 40),
                FishStat(name: "Rarity", value: rarity == "Legendary" ? 95 : rarity == "Epic" ? 82 : rarity == "Rare" ? 68 : 38),
                FishStat(name: "Fight",  value: caught ? 66 : 42),
            ]
        )
    }
}
