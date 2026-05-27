import Foundation
import CoreLocation

struct FishingSpot: Identifiable {
    let id = UUID()
    let name: String
    let biome: String
    let coordinate: CLLocationCoordinate2D
}

extension FishingSpot {
    static let samples: [FishingSpot] = [
        .init(name: "Whispering Creek",
              biome: "Freshwater",
              coordinate: .init(latitude: -33.8640, longitude: 151.1922)),

        .init(name: "Pyrmont Bay",
              biome: "Estuary",
              coordinate: .init(latitude: -33.8730, longitude: 151.1948)),

        .init(name: "Walsh Bay",
              biome: "Saltwater",
              coordinate: .init(latitude: -33.8598, longitude: 151.2058)),

        .init(name: "Darling Harbour",
              biome: "Coastal",
              coordinate: .init(latitude: -33.8703, longitude: 151.2018)),

        .init(name: "Rushcutters Bay",
              biome: "Saltwater",
              coordinate: .init(latitude: -33.8737, longitude: 151.2298)),
    ]
}
