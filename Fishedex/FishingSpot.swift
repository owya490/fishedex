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
    let speciesNames: [String]

    var biomeLabel: String { biome.displayName }

    func species(from catalog: [Fish]) -> [Fish] {
        speciesNames.compactMap { name in
            catalog.first {
                $0.name.compare(name, options: [.caseInsensitive, .diacriticInsensitive]) == .orderedSame
            }
        }
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }

    static func == (lhs: FishingSpot, rhs: FishingSpot) -> Bool {
        lhs.id == rhs.id
    }
}

extension FishingSpot {
    static let samples: [FishingSpot] = [
        .init(
            id: "whispering-creek",
            name: "Whispering Creek",
            biome: .freshwater,
            scene: .river,
            coordinate: .init(latitude: -33.8640, longitude: 151.1922),
            about: "A shaded urban creek pocket where bass ambush bait along reed edges. Calm mornings are best for sight-casting.",
            tips: "Try worms or small hard-body lures near structure.",
            speciesNames: [
                "Australian Bass",
                "Murray Cod",
                "Eels (Short and Long-finned)",
                "Brown Trout",
                "Carp",
            ]
        ),
        .init(
            id: "pyrmont-bay",
            name: "Pyrmont Bay",
            biome: .estuary,
            scene: .lake,
            coordinate: .init(latitude: -33.8730, longitude: 151.1948),
            about: "Sheltered harbour water mixing fresh runoff with salt. Bream and flathead patrol the pylons at high tide.",
            tips: "Fish the tide change with peeled prawn or soft plastics.",
            speciesNames: [
                "Yellowfin Bream",
                "Mulloway",
                "Luderick",
                "Flathead (Dusky)",
                "Mud Crab",
            ]
        ),
        .init(
            id: "walsh-bay",
            name: "Walsh Bay",
            biome: .saltwater,
            scene: .pier,
            coordinate: .init(latitude: -33.8598, longitude: 151.2058),
            about: "Deep wharf shadows and current lines attract pelagics and reef fish. Evening sessions can turn on fast.",
            tips: "Work metal slices along the wall on a run-out tide.",
            speciesNames: [
                "Snapper",
                "Yellowfin Tuna",
                "Australian Salmon",
                "Bonito",
                "Samsonfish",
            ]
        ),
        .init(
            id: "darling-harbour",
            name: "Darling Harbour",
            biome: .coastal,
            scene: .harbour,
            coordinate: .init(latitude: -33.8703, longitude: 151.2018),
            about: "Busy waterfront with jetties and bait-rich edges. Trevally and squid hunt the lights after dusk.",
            tips: "Squid jigs work well once the boardwalk lights switch on.",
            speciesNames: [
                "Trevallies",
                "Squid",
                "Blue Swimmer Crab",
                "Garfish",
                "Tailor",
            ]
        ),
        .init(
            id: "rushcutters-bay",
            name: "Rushcutters Bay",
            biome: .saltwater,
            scene: .beach,
            coordinate: .init(latitude: -33.8737, longitude: 151.2298),
            about: "Open bay flats and weed beds hold flathead and bream. Light wind days are ideal for wading the shallows.",
            tips: "Drag a soft plastic across sand patches between weed.",
            speciesNames: [
                "Flathead (Tiger)",
                "Yellowfin Bream",
                "Luderick",
                "Tailor",
                "Sand Whiting",
            ]
        ),
    ]
}
