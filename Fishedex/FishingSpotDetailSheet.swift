import SwiftUI

struct FishingSpotDetailSheet: View {
    @EnvironmentObject private var session: SessionManager

    let spot: FishingSpot
    let fish: [Fish]
    let onStartFishing: () -> Void
    let onDismiss: () -> Void

    @State private var fishForDetail: Fish?

    private var localSpecies: [Fish] {
        spot.species(in: fish)
    }

    private var caughtCount: Int {
        localSpecies.filter(\.caught).count
    }

    private var speciesProgress: Double {
        guard !localSpecies.isEmpty else { return 0 }
        return Double(caughtCount) / Double(localSpecies.count)
    }

    private let speciesColumns = [
        GridItem(.flexible(), spacing: 10),
        GridItem(.flexible(), spacing: 10),
        GridItem(.flexible(), spacing: 10),
    ]

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    heroBanner
                    progressCard
                    aboutSection
                    speciesSection
                    tipsSection
                    startButton
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 24)
            }
            .background(FishedexTheme.background)
            .toolbar(.hidden, for: .navigationBar)
            .safeAreaInset(edge: .top, spacing: 0) {
                sheetHeader
            }
            .navigationDestination(item: $fishForDetail) { fish in
                FishDetailView(fish: fish)
            }
        }
        .presentationDetents([.medium, .large])
        .presentationDragIndicator(.visible)
    }

    // MARK: - Header

    private var sheetHeader: some View {
        HStack {
            Button(action: onDismiss) {
                Image(systemName: "xmark")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundStyle(FishedexTheme.ink)
                    .frame(width: 32, height: 32)
                    .background(FishedexTheme.card)
                    .fishedexSquare()
                    .fishedexBorder(lineWidth: 1)
            }
            .buttonStyle(.plain)

            Spacer()

            Text("LOCATION")
                .font(FishedexFont.caption)
                .foregroundStyle(FishedexTheme.muted)
                .kerning(1)
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 12)
        .background(Color.white)
    }

    // MARK: - Hero

    private var heroBanner: some View {
        ZStack(alignment: .bottomLeading) {
            FishingSpotSceneImageView(scene: spot.scene)
                .frame(maxWidth: .infinity)
                .frame(height: 168)
                .clipped()

            LinearGradient(
                colors: [.clear, .black.opacity(0.62)],
                startPoint: .center,
                endPoint: .bottom
            )

            VStack(alignment: .leading, spacing: 6) {
                TraitPill(label: spot.biomeLabel.uppercased(), tint: spot.biome.accentColor)

                Text(spot.name.uppercased())
                    .font(FishedexFont.pokemon(20))
                    .foregroundStyle(.white)
                    .kerning(0.6)
                    .shadow(color: .black.opacity(0.4), radius: 0, x: 1, y: 1)

                Text(spot.scene.displayName.uppercased())
                    .font(FishedexFont.micro)
                    .foregroundStyle(.white.opacity(0.82))
                    .kerning(0.8)
            }
            .padding(14)
        }
        .fishedexSquare()
        .fishedexBorder(lineWidth: 2)
        .padding(.top, 4)
    }

    private var progressCard: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("SPOT COLLECTION")
                    .font(FishedexFont.caption)
                    .foregroundStyle(FishedexTheme.muted)
                    .kerning(0.6)

                Spacer()

                Text("\(caughtCount) / \(localSpecies.count)")
                    .font(FishedexFont.headline)
                    .foregroundStyle(FishedexTheme.tabBlue)
            }

            FishedexProgressBar(progress: speciesProgress, height: 12)
        }
        .padding(14)
        .background(Color.white)
        .fishedexSquare()
        .fishedexBorder(lineWidth: 1)
    }

    // MARK: - Sections

    private var aboutSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            sectionTitle("ABOUT")

            Text(spot.about)
                .font(FishedexFont.body)
                .foregroundStyle(FishedexTheme.ink)
                .lineSpacing(3)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var speciesSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            sectionTitle("LOCAL SPECIES")

            if localSpecies.isEmpty {
                Text("Species data loading...")
                    .font(FishedexFont.caption)
                    .foregroundStyle(FishedexTheme.muted)
            } else {
                LazyVGrid(columns: speciesColumns, spacing: 10) {
                    ForEach(localSpecies) { fish in
                        SpeciesTile(
                            fish: fish,
                            accent: spot.biome.accentColor,
                            onTap: fish.caught ? { fishForDetail = fish } : nil
                        )
                    }
                }
            }

            Text("Tap a caught species to open its dex entry.")
                .font(FishedexFont.micro)
                .foregroundStyle(FishedexTheme.muted)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var tipsSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            sectionTitle("ANGLER TIP")

            HStack(alignment: .top, spacing: 10) {
                ZStack {
                    Rectangle()
                        .fill(spot.biome.accentColor)
                        .frame(width: 32, height: 32)
                    Image(systemName: "lightbulb.fill")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(FishedexTheme.cream)
                }
                .fishedexSquare()
                .fishedexBorder(lineWidth: 1)

                Text(spot.tips)
                    .font(FishedexFont.body)
                    .foregroundStyle(FishedexTheme.ink)
                    .lineSpacing(3)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .padding(12)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(FishedexTheme.cream.opacity(0.45))
            .fishedexSquare()
            .fishedexBorder(lineWidth: 1)
        }
    }

    private var startButton: some View {
        Button(action: onStartFishing) {
            HStack(spacing: 10) {
                PixelGlyphIcon(pixels: TabBarRodGlyph.pixels, tint: .white, pixelSize: 1.2)
                Text("START FISHING")
                    .font(FishedexFont.headline)
                    .kerning(0.8)
            }
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(FishedexTheme.tabGreen)
            .fishedexSquare()
            .fishedexBorder()
        }
        .buttonStyle(.plain)
    }

    private func sectionTitle(_ title: String) -> some View {
        Text(title)
            .font(FishedexFont.caption)
            .foregroundStyle(FishedexTheme.muted)
            .kerning(0.8)
    }
}

// MARK: - Species tile

private struct SpeciesTile: View {
    let fish: Fish
    let accent: Color
    var onTap: (() -> Void)?

    private let artBox: CGFloat = 52
    private let tileHeight: CGFloat = 118

    var body: some View {
        Group {
            if let onTap {
                Button(action: onTap) { tileContent }
                    .buttonStyle(.plain)
            } else {
                tileContent
            }
        }
    }

    private var tileContent: some View {
        VStack(spacing: 0) {
            ZStack {
                Rectangle()
                    .fill(fish.caught ? accent.opacity(0.12) : FishedexTheme.progressTrack.opacity(0.5))

                speciesArtwork
                    .frame(width: artBox, height: artBox)
            }
            .frame(height: 72)
            .fishedexBorder(
                lineWidth: 1,
                color: fish.caught ? accent.opacity(0.45) : FishedexTheme.muted.opacity(0.25)
            )

            VStack(spacing: 3) {
                Text(fish.name.uppercased())
                    .font(FishedexFont.micro)
                    .foregroundStyle(fish.caught ? FishedexTheme.ink : FishedexTheme.muted)
                    .lineLimit(2)
                    .multilineTextAlignment(.center)
                    .minimumScaleFactor(0.75)
                    .frame(maxWidth: .infinity)

                if fish.caught {
                    Text("VIEW")
                        .font(FishedexFont.micro)
                        .foregroundStyle(FishedexTheme.tabBlue)
                        .kerning(0.4)
                } else {
                    Text("???")
                        .font(FishedexFont.micro)
                        .foregroundStyle(FishedexTheme.muted.opacity(0.7))
                }
            }
            .padding(.horizontal, 6)
            .padding(.vertical, 8)
            .frame(maxWidth: .infinity)
            .background(Color.white)
        }
        .frame(height: tileHeight)
        .background(Color.white)
        .fishedexSquare()
        .fishedexBorder(lineWidth: fish.caught ? 2 : 1)
        .opacity(fish.caught ? 1 : 0.88)
    }

    @ViewBuilder
    private var speciesArtwork: some View {
        if fish.caught {
            Image(fish.imageName)
                .resizable()
                .interpolation(.none)
                .scaledToFit()
                .frame(width: artBox, height: artBox)
        } else {
            MysteryFishSilhouetteView(height: artBox, showsQuestionMark: true)
                .frame(width: artBox, height: artBox)
        }
    }
}

enum TabBarRodGlyph {
    static let pixels: Set<PixelCoord> = [
        PixelCoord(4, 13), PixelCoord(5, 12), PixelCoord(6, 11), PixelCoord(7, 10),
        PixelCoord(8, 9), PixelCoord(9, 8), PixelCoord(10, 7), PixelCoord(11, 6),
        PixelCoord(12, 5), PixelCoord(13, 4),
        PixelCoord(7, 10), PixelCoord(8, 10),
        PixelCoord(7, 11), PixelCoord(8, 11),
        PixelCoord(13, 5), PixelCoord(13, 6), PixelCoord(13, 7), PixelCoord(13, 8),
        PixelCoord(13, 9), PixelCoord(13, 10), PixelCoord(13, 11), PixelCoord(13, 12),
    ]
}
