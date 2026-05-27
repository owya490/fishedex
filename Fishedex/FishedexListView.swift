import SwiftUI

// MARK: - DEX Tab (split-panel gallery)

private enum DexMode { case dex, myFish }

struct DexView: View {
    let fish: [Fish]

    @State private var searchText   = ""
    @State private var dexMode: DexMode = .dex
    @State private var selectedFish: Fish

    init(fish: [Fish]) {
        self.fish = fish
        let first = fish.first(where: \.caught) ?? fish[0]
        _selectedFish = State(initialValue: first)
    }

    private var displayedFish: [Fish] {
        let base = dexMode == .dex ? fish : fish.filter(\.caught)
        guard !searchText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return base }
        return base.filter { $0.name.localizedCaseInsensitiveContains(searchText) }
    }

    var body: some View {
        VStack(spacing: 0) {
            AppHeaderView()

            DexSearchBar(text: $searchText)

            DexModeToggle(mode: $dexMode)

            HStack(spacing: 0) {
                DexFishList(
                    fish: displayedFish,
                    selectedFish: $selectedFish
                )
                .frame(width: 128)

                Rectangle()
                    .fill(Color(red: 0.86, green: 0.86, blue: 0.87))
                    .frame(width: 1)

                DexDetailPanel(fish: selectedFish)
                    .frame(maxWidth: .infinity)
            }
            .frame(maxHeight: .infinity)
        }
        .background(Color(red: 0.95, green: 0.95, blue: 0.96).ignoresSafeArea())
    }
}

// MARK: - Search bar

private struct DexSearchBar: View {
    @Binding var text: String

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: "magnifyingglass")
                .foregroundStyle(FishedexTheme.muted)

            TextField("Search Dex...", text: $text)
                .font(.subheadline.weight(.semibold))
                .textInputAutocapitalization(.never)
                .disableAutocorrection(true)
        }
        .padding(.horizontal, 16)
        .frame(height: 46)
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .stroke(Color(red: 0.84, green: 0.84, blue: 0.85), lineWidth: 1)
        )
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
        .background(Color(red: 0.95, green: 0.95, blue: 0.96))
    }
}

// MARK: - Mode toggle

private struct DexModeToggle: View {
    @Binding var mode: DexMode

    var body: some View {
        HStack(spacing: 0) {
            modeButton("DEX MODE", target: .dex)
            modeButton("MY FISH",  target: .myFish)
        }
        .background(Color(red: 0.86, green: 0.86, blue: 0.87))
        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
        .padding(.horizontal, 16)
        .padding(.bottom, 8)
        .background(Color(red: 0.95, green: 0.95, blue: 0.96))
    }

    private func modeButton(_ title: String, target: DexMode) -> some View {
        Button { mode = target } label: {
            Text(title)
                .font(.subheadline.weight(.bold))
                .foregroundStyle(mode == target ? .white : FishedexTheme.muted)
                .frame(maxWidth: .infinity)
                .frame(height: 40)
                .background(mode == target ? FishedexTheme.tabBlue : Color.clear)
                .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Left fish list panel

private struct DexFishList: View {
    let fish: [Fish]
    @Binding var selectedFish: Fish

    var body: some View {
        ScrollView(showsIndicators: false) {
            LazyVStack(spacing: 6) {
                ForEach(fish) { f in
                    DexFishCell(fish: f, isSelected: selectedFish.id == f.id)
                        .onTapGesture {
                            withAnimation(.easeInOut(duration: 0.15)) {
                                selectedFish = f
                            }
                        }
                }
            }
            .padding(8)
        }
        .background(Color(red: 0.95, green: 0.95, blue: 0.96))
    }
}

// MARK: - Fish list cell

private struct DexFishCell: View {
    let fish: Fish
    let isSelected: Bool

    var body: some View {
        VStack(spacing: 4) {
            Group {
                if fish.caught {
                    FishArtworkView(fish: fish, height: 50, showsShadow: false)
                        .frame(maxWidth: .infinity)
                } else {
                    MysteryFishSilhouetteView()
                        .frame(maxWidth: .infinity)
                }
            }
            .padding(.top, 4)

            Text(fish.caught ? fish.name.uppercased() : "???")
                .font(.system(size: 9, weight: .bold))
                .foregroundStyle(isSelected ? .white : FishedexTheme.ink)
                .lineLimit(2)
                .multilineTextAlignment(.center)
                .minimumScaleFactor(0.75)
                .frame(maxWidth: .infinity)
        }
        .padding(.bottom, 8)
        .padding(.horizontal, 4)
        .overlay(alignment: .topLeading) {
            Text(fish.number)
                .font(.system(size: 8, weight: .bold))
                .foregroundStyle(isSelected ? .white.opacity(0.80) : FishedexTheme.muted)
                .padding(5)
        }
        .background(isSelected ? FishedexTheme.ocean : Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .stroke(
                    isSelected ? FishedexTheme.ocean : Color(red: 0.80, green: 0.80, blue: 0.81),
                    lineWidth: isSelected ? 2 : 1
                )
        )
    }
}

// MARK: - Right detail panel

private struct DexDetailPanel: View {
    let fish: Fish

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 0) {
                decorativeDots
                    .padding(.horizontal, 16)
                    .padding(.top, 14)

                artworkCard
                    .padding(.vertical, 8)

                infoBlock
                    .padding(.horizontal, 16)
                    .padding(.bottom, 24)
            }
        }
        .background(Color.white)
    }

    // Three coloured macOS-style dots for visual flourish
    private var decorativeDots: some View {
        HStack(spacing: 6) {
            Circle().fill(Color(red: 0.94, green: 0.35, blue: 0.32)).frame(width: 10, height: 10)
            Circle().fill(Color(red: 0.95, green: 0.70, blue: 0.22)).frame(width: 10, height: 10)
            Circle().fill(Color(red: 0.28, green: 0.78, blue: 0.36)).frame(width: 10, height: 10)
        }
    }

    private var artworkCard: some View {
        FishArtworkView(fish: fish, height: 120, showsShadow: true)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .background(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(FishedexTheme.accent(for: fish).opacity(0.08))
                    .padding(.horizontal, 14)
            )
    }

    private var infoBlock: some View {
        VStack(alignment: .leading, spacing: 12) {
            nameBlock
            factGrid
            descriptionText
        }
    }

    private var nameBlock: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(fish.name.uppercased())
                .font(.system(size: 17, weight: .heavy))
                .foregroundStyle(FishedexTheme.ink)
                .fixedSize(horizontal: false, vertical: true)

            Text(fish.number)
                .font(.subheadline.weight(.bold))
                .foregroundStyle(FishedexTheme.tabBlue)
        }
    }

    private var factGrid: some View {
        LazyVGrid(
            columns: [GridItem(.flexible(), spacing: 8), GridItem(.flexible(), spacing: 8)],
            spacing: 8
        ) {
            FactCard(label: "RARITY") {
                StarRating(stars: fish.rarityStars)
            }
            FactCard(label: "AVG. WEIGHT") {
                Text(fish.avgWeight)
                    .font(.system(size: 11, weight: .heavy))
                    .foregroundStyle(FishedexTheme.ink)
            }
            FactCard(label: "PREF. BAIT") {
                Text(fish.prefBait.uppercased())
                    .font(.system(size: 11, weight: .heavy))
                    .foregroundStyle(FishedexTheme.ink)
            }
            FactCard(label: "LOCATION") {
                Text(fish.location.uppercased())
                    .font(.system(size: 11, weight: .heavy))
                    .foregroundStyle(FishedexTheme.ink)
                    .lineLimit(2)
                    .minimumScaleFactor(0.75)
            }
        }
    }

    private var descriptionText: some View {
        Text(fish.about)
            .font(.caption)
            .foregroundStyle(FishedexTheme.muted)
            .fixedSize(horizontal: false, vertical: true)
    }
}

// MARK: - Fact card

private struct FactCard<Content: View>: View {
    let label: String
    let content: Content

    init(label: String, @ViewBuilder content: () -> Content) {
        self.label   = label
        self.content = content()
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(label)
                .font(.system(size: 8, weight: .bold))
                .foregroundStyle(FishedexTheme.muted)
                .kerning(0.4)

            content
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 10)
        .padding(.vertical, 8)
        .background(Color(red: 0.95, green: 0.95, blue: 0.96))
        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .stroke(Color(red: 0.82, green: 0.82, blue: 0.83), lineWidth: 1)
        )
    }
}

// MARK: - Star rating

private struct StarRating: View {
    let stars: Int

    var body: some View {
        HStack(spacing: 2) {
            ForEach(1...3, id: \.self) { i in
                Image(systemName: i <= stars ? "star.fill" : "star")
                    .font(.system(size: 10))
                    .foregroundStyle(i <= stars ? Color.yellow : Color.gray.opacity(0.35))
            }
        }
    }
}

// MARK: - Shared row used by other screens (kept for compatibility)

struct FishRowView: View {
    let fish: Fish

    var body: some View {
        HStack(spacing: 16) {
            ZStack {
                RoundedRectangle(cornerRadius: 22, style: .continuous)
                    .fill(FishedexTheme.accent(for: fish).opacity(0.16))

                FishArtworkView(fish: fish, height: 72)
            }
            .frame(width: 96, height: 86)

            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text(fish.name)
                        .font(.headline.weight(.bold))
                        .foregroundStyle(FishedexTheme.ink)

                    Spacer()

                    Text(fish.number)
                        .font(.caption.weight(.bold))
                        .foregroundStyle(FishedexTheme.muted)
                }

                Text(fish.scientificName)
                    .font(.caption)
                    .italic()
                    .foregroundStyle(FishedexTheme.muted)

                HStack(spacing: 8) {
                    TraitPill(label: fish.habitat, tint: FishedexTheme.accent(for: fish))
                    TraitPill(label: fish.rarity,  tint: fish.caught ? Color.green : Color.gray)
                }
            }

            Image(systemName: fish.caught ? "checkmark.circle.fill" : "circle.dashed")
                .foregroundStyle(fish.caught ? Color.green : FishedexTheme.muted.opacity(0.55))
        }
        .padding(14)
        .fishedexCard(cornerRadius: 28)
    }
}
