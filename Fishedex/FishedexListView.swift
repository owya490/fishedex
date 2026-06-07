import SwiftUI

// MARK: - DEX Tab (split-panel gallery)

private enum DexMode { case dex, myFish }

struct DexView: View {
    let fish: [Fish]

    @State private var searchText   = ""
    @State private var dexMode: DexMode = .dex
    @State private var selectedFish: Fish?
    @State private var fishForDetail: Fish?

    init(fish: [Fish]) {
        self.fish = fish
        _selectedFish = State(initialValue: fish.first)
    }

    private var displayedFish: [Fish] {
        let base = dexMode == .dex ? fish : fish.filter(\.caught)
        guard !searchText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return base }
        return base.filter { $0.name.localizedCaseInsensitiveContains(searchText) }
    }

    var body: some View {
        NavigationStack {
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

                    if dexMode == .myFish && displayedFish.isEmpty {
                        DexMyFishEmptyState()
                            .frame(maxWidth: .infinity)
                    } else if let selectedFish {
                        DexDetailPanel(fish: selectedFish) {
                            fishForDetail = selectedFish
                        }
                        .frame(maxWidth: .infinity)
                    }
                }
                .frame(maxHeight: .infinity)
            }
            .background(Color(red: 0.95, green: 0.95, blue: 0.96).ignoresSafeArea())
            .navigationDestination(item: $fishForDetail) { fish in
                FishDetailView(fish: fish)
            }
            .onChange(of: dexMode) { _, _ in
                selectedFish = displayedFish.first
            }
        }
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
                .font(FishedexFont.subheadline)
                .textInputAutocapitalization(.never)
                .disableAutocorrection(true)
        }
        .padding(.horizontal, 16)
        .frame(height: 46)
        .background(Color.white)
        .fishedexSquare()
        .fishedexBorder(lineWidth: 1)
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
        .fishedexSquare()
        .fishedexBorder()
        .padding(.horizontal, 16)
        .padding(.bottom, 8)
        .background(Color(red: 0.95, green: 0.95, blue: 0.96))
    }

    private func modeButton(_ title: String, target: DexMode) -> some View {
        Button { mode = target } label: {
            Text(title)
                .font(FishedexFont.subheadline)
                .foregroundStyle(mode == target ? .white : FishedexTheme.muted)
                .frame(maxWidth: .infinity)
                .frame(height: 40)
                .background(mode == target ? FishedexTheme.tabBlue : Color.clear)
                .fishedexSquare()
                .fishedexBorder(lineWidth: 1)
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Left fish list panel

private struct DexFishList: View {
    let fish: [Fish]
    @Binding var selectedFish: Fish?

    var body: some View {
        ScrollView(showsIndicators: false) {
            LazyVStack(spacing: 6) {
                ForEach(fish) { f in
                    DexFishCell(fish: f, isSelected: selectedFish?.id == f.id)
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
                .font(FishedexFont.micro)
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
                .font(FishedexFont.micro)
                .foregroundStyle(isSelected ? .white.opacity(0.80) : FishedexTheme.muted)
                .padding(5)
        }
        .background(isSelected ? FishedexTheme.ocean : Color.white)
        .fishedexSquare()
        .fishedexBorder(lineWidth: isSelected ? 2 : 1)
    }
}

// MARK: - Right detail panel

private struct DexDetailPanel: View {
    let fish: Fish
    let onOpenDetail: () -> Void

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 0) {
                artworkCard
                    .padding(.top, 14)
                    .padding(.bottom, 8)

                infoBlock
                    .padding(.horizontal, 16)
                    .padding(.bottom, 24)
            }
        }
        .background(Color.white)
    }

    private var artworkCard: some View {
        FishArtworkView(fish: fish, height: 120, showsShadow: true)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .background(
                Rectangle()
                    .fill(FishedexTheme.accent(for: fish).opacity(0.08))
                    .padding(.horizontal, 14)
            )
    }

    private var infoBlock: some View {
        VStack(alignment: .leading, spacing: 12) {
            nameBlock
            factGrid
            descriptionText
            detailButton
        }
    }

    private var nameBlock: some View {
        VStack(alignment: .leading, spacing: 2) {
            Button(action: onOpenDetail) {
                Text(fish.name.uppercased())
                    .font(FishedexFont.title2)
                    .foregroundStyle(FishedexTheme.ink)
                    .fixedSize(horizontal: false, vertical: true)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            .buttonStyle(.plain)

            Text(fish.number)
                .font(FishedexFont.subheadline)
                .foregroundStyle(FishedexTheme.tabBlue)
        }
    }

    private var factGrid: some View {
        DexFactPair(rarityStars: fish.rarityStars, prefBait: fish.prefBait)
    }

    private var descriptionText: some View {
        Text(fish.about)
            .font(FishedexFont.caption)
            .foregroundStyle(FishedexTheme.muted)
            .fixedSize(horizontal: false, vertical: true)
    }

    private var detailButton: some View {
        Button(action: onOpenDetail) {
            Text("VIEW DETAILS")
                .font(FishedexFont.headline)
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
                .background(FishedexTheme.tabBlue)
                .fishedexSquare()
                .fishedexBorder()
        }
        .buttonStyle(.plain)
        .padding(.top, 4)
    }
}

// MARK: - Unified fact pair

private struct DexFactPair: View {
    let rarityStars: Int
    let prefBait: String

    private let cellBackground = Color(red: 0.95, green: 0.95, blue: 0.96)
    private let dividerColor = Color(red: 0.86, green: 0.86, blue: 0.87)

    var body: some View {
        HStack(spacing: 0) {
            factCell(label: "RARITY") {
                StarRating(stars: rarityStars)
            }

            Rectangle()
                .fill(dividerColor)
                .frame(width: 1)

            factCell(label: "PREF. BAIT") {
                Text(prefBait.uppercased())
                    .font(FishedexFont.body)
                    .foregroundStyle(FishedexTheme.ink)
                    .lineLimit(2)
                    .minimumScaleFactor(0.75)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
        .frame(height: 58)
        .background(cellBackground)
        .fishedexSquare()
        .fishedexBorder(lineWidth: 1)
    }

    private func factCell<Content: View>(label: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(label)
                .font(FishedexFont.micro)
                .foregroundStyle(FishedexTheme.muted)
                .kerning(0.4)

            content()
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 8)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

// MARK: - My Fish empty state

private struct DexMyFishEmptyState: View {
    var body: some View {
        VStack(spacing: 14) {
            Image(systemName: "fish")
                .font(.system(size: 36, weight: .semibold))
                .foregroundStyle(FishedexTheme.muted.opacity(0.45))

            Text("Catch your first fish!")
                .font(FishedexFont.headline)
                .foregroundStyle(FishedexTheme.ink)

            Text("Head to Catch and log a fish to start your collection.")
                .font(FishedexFont.caption)
                .foregroundStyle(FishedexTheme.muted)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(.horizontal, 24)
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

#Preview {
    DexView(fish: Fish.samples)
        .environmentObject(SessionManager())
}

// MARK: - Shared row used by other screens (kept for compatibility)

struct FishRowView: View {
    let fish: Fish

    var body: some View {
        HStack(spacing: 16) {
            ZStack {
                Rectangle()
                    .fill(FishedexTheme.accent(for: fish).opacity(0.16))
                    .fishedexBorder(lineWidth: 1)

                FishArtworkView(fish: fish, height: 72)
            }
            .frame(width: 96, height: 86)

            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text(fish.name)
                        .font(FishedexFont.headline)
                        .foregroundStyle(FishedexTheme.ink)

                    Spacer()

                    Text(fish.number)
                        .font(FishedexFont.caption)
                        .foregroundStyle(FishedexTheme.muted)
                }

                Text(fish.scientificName)
                    .font(FishedexFont.caption)
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
        .fishedexCard()
    }
}
