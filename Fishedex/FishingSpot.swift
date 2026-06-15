import Foundation
import CoreLocation
import SwiftUI

enum FishingSpotBiome: String, CaseIterable {
    case freshwater
    case estuary
    case saltwater
    case coastal

    var displayName: String {
        switch self {
        case .freshwater: "Freshwater"
        case .estuary:    "Estuary"
        case .saltwater:  "Saltwater"
        case .coastal:    "Coastal"
        }
    }

    var pinTint: Color {
        switch self {
        case .freshwater: Color(red: 0.22, green: 0.62, blue: 0.42)
        case .estuary:    Color(red: 0.55, green: 0.48, blue: 0.28)
        case .saltwater:  FishedexTheme.ocean
        case .coastal:    Color(red: 0.24, green: 0.48, blue: 0.85)
        }
    }

    var accentColor: Color {
        switch self {
        case .freshwater: Color(red: 0.18, green: 0.55, blue: 0.36)
        case .estuary:    Color(red: 0.72, green: 0.58, blue: 0.22)
        case .saltwater:  Color(red: 0.14, green: 0.46, blue: 0.62)
        case .coastal:    FishedexTheme.tabBlue
        }
    }
}

struct FishingSpot: Identifiable, Hashable {
    let id: String
    let name: String
    let biome: FishingSpotBiome
    let scene: FishingSpotScene
    let coordinate: CLLocationCoordinate2D
    let about: String
    let tips: String
    let species: [FishSpeciesRef]

    var biomeLabel: String { biome.displayName }

    func species(in catalog: [Fish]) -> [Fish] {
        species.compactMap { $0.resolve(in: catalog) }
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }

    static func == (lhs: FishingSpot, rhs: FishingSpot) -> Bool {
        lhs.id == rhs.id
    }
}

// MARK: - Default location catalog
//
// Every entry below becomes a pin on the MAP tab. To add a location, append one
// row to `catalogEntries` — no other files need to change.
//
//   id            Stable slug (use kebab-case; don't rename after release)
//   name          Shown on the map pin modal and catch log
//   biome         .freshwater | .estuary | .saltwater | .coastal
//   scene         .river | .lake | .harbour | .pier | .beach — picks pixel art
//   latitude      Pin latitude  (e.g. -33.867 for Sydney)
//   longitude     Pin longitude (e.g. 151.201)
//   about         Description in the location info modal
//   tips          Angler tip shown in the modal
//   species       `FishSpeciesRef` members (autocomplete from FishCatalogSpecies.swift)

extension FishingSpot {
    /// All default fishing locations shown on the map.
    static let catalog: [FishingSpot] = catalogEntries.map(makeSpot)

    /// Back-compat alias — prefer `catalog`.
    static let samples: [FishingSpot] = catalog

    private static let catalogEntries: [CatalogEntry] = [
        CatalogEntry(
            id: "whispering-creek",
            name: "Whispering Creek",
            biome: .freshwater,
            scene: .river,
            latitude: -33.8640,
            longitude: 151.1922,
            about: "A shaded urban creek pocket where bass ambush bait along reed edges. Calm mornings are best for sight-casting.",
            tips: "Try worms or small hard-body lures near structure.",
            species: [
                .australianBass,
                .murrayCod,
                .eelsShortAndLongFinned,
                .brownTrout,
                .carp,
            ]
        ),
        CatalogEntry(
            id: "pyrmont-bay",
            name: "Pyrmont Bay",
            biome: .estuary,
            scene: .lake,
            latitude: -33.8730,
            longitude: 151.1948,
            about: "Sheltered harbour water mixing fresh runoff with salt. Bream and flathead patrol the pylons at high tide.",
            tips: "Fish the tide change with peeled prawn or soft plastics.",
            species: [
                .yellowfinBream,
                .mulloway,
                .luderick,
                .flatheadDusky,
                .mudCrab,
            ]
        ),
        CatalogEntry(
            id: "walsh-bay",
            name: "Walsh Bay",
            biome: .saltwater,
            scene: .pier,
            latitude: -33.8598,
            longitude: 151.2058,
            about: "Deep wharf shadows and current lines attract pelagics and reef fish. Evening sessions can turn on fast.",
            tips: "Work metal slices along the wall on a run-out tide.",
            species: [
                .snapper,
                .yellowfinTuna,
                .australianSalmon,
                .bonito,
                .samsonfish,
            ]
        ),
        CatalogEntry(
            id: "darling-harbour",
            name: "Darling Harbour",
            biome: .coastal,
            scene: .harbour,
            latitude: -33.8703,
            longitude: 151.2018,
            about: "Busy waterfront with jetties and bait-rich edges. Trevally and squid hunt the lights after dusk.",
            tips: "Squid jigs work well once the boardwalk lights switch on.",
            species: [
                .trevallies,
                .squid,
                .blueSwimmerCrab,
                .garfish,
                .tailor,
            ]
        ),
        CatalogEntry(
            id: "rushcutters-bay",
            name: "Rushcutters Bay",
            biome: .saltwater,
            scene: .beach,
            latitude: -33.8737,
            longitude: 151.2298,
            about: "Open bay flats and weed beds hold flathead and bream. Light wind days are ideal for wading the shallows.",
            tips: "Drag a soft plastic across sand patches between weed.",
            species: [
                .flatheadTiger,
                .yellowfinBream,
                .luderick,
                .tailor,
                .sandWhiting,
            ]
        ),
    ]

    private struct CatalogEntry {
        let id: String
        let name: String
        let biome: FishingSpotBiome
        let scene: FishingSpotScene
        let latitude: Double
        let longitude: Double
        let about: String
        let tips: String
        let species: [FishSpeciesRef]
    }

    private static func makeSpot(_ entry: CatalogEntry) -> FishingSpot {
        FishingSpot(
            id: entry.id,
            name: entry.name,
            biome: entry.biome,
            scene: entry.scene,
            coordinate: CLLocationCoordinate2D(latitude: entry.latitude, longitude: entry.longitude),
            about: entry.about,
            tips: entry.tips,
            species: entry.species
        )
    }
}
