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
    private static let catalog: [CatalogEntry] = [
        CatalogEntry("Yellowfin Bream", "Estuary"),
        CatalogEntry("Australian Salmon", "Surf beach"),
        CatalogEntry("Mackerel (Narrow-barred Spanish)", "Offshore"),
        CatalogEntry("Flathead (Tiger)", "Sand flats"),
        CatalogEntry("Pacific Oyster", "Estuary"),
        CatalogEntry("Brown Trout", "Highland stream"),
        CatalogEntry("Prawn - School Prawn", "Estuary"),
        CatalogEntry("Flathead (Bluespotted)", "Sand flats"),
        CatalogEntry("Amberjack", "Offshore"),
        CatalogEntry("Shark - Whaler", "Offshore"),
        CatalogEntry("Blue Groper", "Rock reef"),
        CatalogEntry("Shark - Wobbegong", "Reef"),
        CatalogEntry("Sand Whiting", "Sand flats"),
        CatalogEntry("Beach Worm", "Surf beach"),
        CatalogEntry("Yellowfin Tuna", "Offshore"),
        CatalogEntry("Longtail Tuna", "Offshore"),
        CatalogEntry("Mud Crab", "Estuary"),
        CatalogEntry("Leatherjacket", "Reef"),
        CatalogEntry("Marlin (Blue)", "Bluewater"),
        CatalogEntry("Trevallies", "Coastal"),
        CatalogEntry("Shark - Blue", "Offshore"),
        CatalogEntry("Mullet (Poddy)", "Estuary"),
        CatalogEntry("Mulloway", "Estuary"),
        CatalogEntry("Brook Trout", "Highland stream"),
        CatalogEntry("Cockles", "Sand flats"),
        CatalogEntry("Flounder", "Sand flats"),
        CatalogEntry("Shortbill Spearfish", "Bluewater"),
        CatalogEntry("Prawn - Black Tiger", "Estuary"),
        CatalogEntry("Morwong (Jackass)", "Reef"),
        CatalogEntry("Snapper", "Reef"),
        CatalogEntry("Eastern Rock Lobster", "Rock reef"),
        CatalogEntry("Rock Blackfish", "Rock wash"),
        CatalogEntry("Marlin (Striped)", "Bluewater"),
        CatalogEntry("Tarwhine", "Estuary"),
        CatalogEntry("Marlin (Black)", "Bluewater"),
        CatalogEntry("Murray Crayfish", "River"),
        CatalogEntry("Golden Perch", "River"),
        CatalogEntry("Mangrove Jack", "Estuary"),
        CatalogEntry("Mackerel (Spotted)", "Offshore"),
        CatalogEntry("Yabby", "River"),
        CatalogEntry("Spanner Crab", "Sand flats"),
        CatalogEntry("Sydney Rock Oyster", "Estuary"),
        CatalogEntry("Black Bream", "Estuary"),
        CatalogEntry("Gemfish", "Deep reef"),
        CatalogEntry("Cunjevoi", "Rock reef"),
        CatalogEntry("Hairtail", "Estuary"),
        CatalogEntry("Hapuku", "Deep reef"),
        CatalogEntry("Bonito", "Coastal"),
        CatalogEntry("Purple Sea Urchin", "Reef"),
        CatalogEntry("Octopus", "Reef"),
        CatalogEntry("Native Oyster", "Estuary"),
        CatalogEntry("Bass Groper", "Deep reef"),
        CatalogEntry("Freshwater Catfish", "River"),
        CatalogEntry("Spiny Crayfish", "River"),
        CatalogEntry("Mahi Mahi (Dolphinfish)", "Bluewater"),
        CatalogEntry("Atlantic Salmon", "Coastal"),
        CatalogEntry("Morwong (Banded)", "Reef"),
        CatalogEntry("Blue Swimmer Crab", "Bay"),
        CatalogEntry("Grey Morwong (Rubber Lip)", "Reef"),
        CatalogEntry("Murray Cod", "River"),
        CatalogEntry("Shark - Mako", "Offshore"),
        CatalogEntry("Commercial Scallop", "Bay"),
        CatalogEntry("Banded Rock Cod (Bar Cod)", "Reef"),
        CatalogEntry("Cuttlefish", "Reef"),
        CatalogEntry("Balmain Bug", "Sand flats"),
        CatalogEntry("Tailor", "Surf beach"),
        CatalogEntry("Rainbow Trout", "Highland stream"),
        CatalogEntry("Slipper Lobster", "Reef"),
        CatalogEntry("Carp", "River"),
        CatalogEntry("Samsonfish", "Offshore"),
        CatalogEntry("Luderick", "Rock wash"),
        CatalogEntry("Southern Rock Lobster", "Rock reef"),
        CatalogEntry("Cobia", "Offshore"),
        CatalogEntry("Albacore", "Offshore"),
        CatalogEntry("Tropical Rock Lobster (Painted and Ornate)", "Tropical reef"),
        CatalogEntry("Mullet (Sea)", "Coastal"),
        CatalogEntry("Turban Snails", "Rock reef"),
        CatalogEntry("Morwong (Red)", "Reef"),
        CatalogEntry("Swordfish", "Bluewater"),
        CatalogEntry("Eastern Red Scorpionfish (Red Rock Cod)", "Rock reef"),
        CatalogEntry("Sailfish", "Bluewater"),
        CatalogEntry("Sole", "Sand flats"),
        CatalogEntry("Shark - School", "Offshore"),
        CatalogEntry("Pearl Perch", "Reef"),
        CatalogEntry("Estuary Perch", "Estuary"),
        CatalogEntry("Eastern School Whiting", "Sand flats"),
        CatalogEntry("Squid", "Bay"),
        CatalogEntry("Wahoo", "Bluewater"),
        CatalogEntry("Australian Sawtail", "Reef"),
        CatalogEntry("Moses Snapper", "Reef"),
        CatalogEntry("Shark - Hammerhead", "Offshore"),
        CatalogEntry("Bigeye Tuna", "Offshore"),
        CatalogEntry("Redfin Perch", "Lake"),
        CatalogEntry("Southern Bluefin Tuna", "Offshore"),
        CatalogEntry("Blacklip Abalone", "Rock reef"),
        CatalogEntry("Bluefish", "Surf beach"),
        CatalogEntry("Eels (Short and Long-finned)", "River"),
        CatalogEntry("Flathead (Dusky)", "Estuary"),
        CatalogEntry("Garfish", "Bay"),
        CatalogEntry("Teraglin", "Reef"),
        CatalogEntry("Australian Bass", "River"),
        CatalogEntry("Blue-eye Trevalla", "Deep reef"),
        CatalogEntry("Silver Perch", "River"),
    ]

    /// All species names from the local Dex catalog — used to validate fishing-spot refs.
    static let catalogSpeciesNames: Set<String> = Set(catalog.map(\.name))

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
