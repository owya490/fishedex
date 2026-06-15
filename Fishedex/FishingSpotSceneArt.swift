import SwiftUI

enum FishingSpotScene: String, CaseIterable {
    case lake
    case harbour
    case river
    case beach
    case pier

    var displayName: String {
        switch self {
        case .lake:    "Lake"
        case .harbour: "Harbour"
        case .river:   "River"
        case .beach:   "Beach"
        case .pier:    "Pier"
        }
    }

    var imageName: String {
        switch self {
        case .lake:    "SpotLake"
        case .harbour: "SpotHarbour"
        case .river:   "SpotRiver"
        case .beach:   "SpotBeach"
        case .pier:    "SpotPier"
        }
    }
}

struct FishingSpotSceneImageView: View {
    let scene: FishingSpotScene

    var body: some View {
        Image(scene.imageName)
            .resizable()
            .interpolation(.none)
            .scaledToFill()
            .accessibilityLabel(Text("\(scene.displayName) location artwork"))
    }
}
