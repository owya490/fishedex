import SwiftUI

struct FishArtworkView: View {
    let fish: Fish
    var height: CGFloat
    var showsShadow = true

    var body: some View {
        if showsShadow {
            artwork
                .shadow(color: FishedexTheme.accent(for: fish).opacity(0.22), radius: 18, x: 0, y: 12)
        } else {
            artwork
        }
    }

    private var artwork: some View {
        Image(fish.imageName)
            .resizable()
            .interpolation(.none)
            .scaledToFit()
            .frame(height: height)
            .accessibilityLabel(Text("\(fish.name) pixel art"))
    }
}

struct TraitPill: View {
    let label: String
    let tint: Color

    var body: some View {
        Text(label)
            .font(.caption.weight(.semibold))
            .foregroundStyle(FishedexTheme.ink)
            .padding(.horizontal, 14)
            .padding(.vertical, 7)
            .background(tint.opacity(0.22))
            .fishedexSquare()
            .fishedexBorder(lineWidth: 1)
    }
}

struct MysteryFishSilhouetteView: View {
    var height: CGFloat = 80
    var showsQuestionMark = false

    var body: some View {
        ZStack {
            Image("MysteryFish")
                .resizable()
                .interpolation(.none)
                .scaledToFit()

            if showsQuestionMark {
                Text("?")
                    .font(FishedexFont.pokemon(height * 0.30))
                    .foregroundStyle(.white)
            }
        }
        .frame(height: height)
        .accessibilityLabel(Text("Mystery fish silhouette"))
    }
}

struct PixelGrayFishIconView: View {
    var size: CGFloat = 72

    var body: some View {
        Image("PixelGrayFish")
            .resizable()
            .interpolation(.none)
            .scaledToFit()
            .frame(width: size, height: size)
            .accessibilityLabel(Text("Uncaught fish"))
    }
}
