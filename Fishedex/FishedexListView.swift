import SwiftUI

// MARK: - DEX Tab (split-panel gallery)

private enum DexMode { case dex, myFish }

private enum DexSortOption: String, CaseIterable, Identifiable {
    case fishNumber
    case alphabetical
    case discovered

    var id: String { rawValue }

    var title: String {
        switch self {
        case .fishNumber: return "Fish #"
        case .alphabetical: return "A–Z"
        case .discovered: return "Discovered"
        }
    }
}

private enum DexLayout {
    static let scrollBottomInset: CGFloat = 16
}

struct DexView: View {
    @EnvironmentObject private var session: SessionManager

    let fish: [Fish]
    @Binding var hidesBottomTabBar: Bool
    var onLogoTap: (() -> Void)? = nil

    @State private var searchText = ""
    @State private var dexMode: DexMode = .dex
    @State private var sortOption: DexSortOption = .fishNumber
    @State private var selectedFish: Fish?
    @State private var selectedCatchID: UUID?
    @State private var fishForDetail: Fish?
    @State private var catchIDForDetail: UUID?

    init(
        fish: [Fish],
        hidesBottomTabBar: Binding<Bool> = .constant(false),
        onLogoTap: (() -> Void)? = nil
    ) {
        self.fish = fish
        self.onLogoTap = onLogoTap
        _hidesBottomTabBar = hidesBottomTabBar
        _selectedFish = State(initialValue: fish.first)
    }

    private var displayedFish: [Fish] {
        guard !searchText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return fish }
        return fish.filter { $0.name.localizedCaseInsensitiveContains(searchText) }
    }

    private var sortedDisplayedFish: [Fish] {
        switch sortOption {
        case .fishNumber:
            return displayedFish.sorted { $0.id < $1.id }
        case .alphabetical:
            return displayedFish.sorted {
                $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending
            }
        case .discovered:
            return displayedFish.sorted {
                if $0.caught != $1.caught { return $0.caught && !$1.caught }
                return $0.id < $1.id
            }
        }
    }

    private var displayedCatches: [UserCatchRow] {
        let base = session.catches.sorted { $0.caughtAt > $1.caughtAt }
        let query = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !query.isEmpty else { return base }
        return base.filter { catchRow in
            session.catchTitle(for: catchRow).localizedCaseInsensitiveContains(query)
                || session.catchSpeciesName(for: catchRow).localizedCaseInsensitiveContains(query)
                || (catchRow.locationName?.localizedCaseInsensitiveContains(query) ?? false)
        }
    }

    private var selectedCatch: UserCatchRow? {
        if let selectedCatchID,
           let match = displayedCatches.first(where: { $0.id == selectedCatchID }) {
            return match
        }
        return displayedCatches.first
    }

    var body: some View {
        NavigationStack {
            dexRoot
                .background(Color(red: 0.95, green: 0.95, blue: 0.96).ignoresSafeArea())
                .navigationDestination(item: $fishForDetail) { fish in
                    FishDetailView(fish: fish)
                }
                .navigationDestination(item: $catchIDForDetail) { catchID in
                    CatchDetailDestination(catchID: catchID)
                }
                .onAppear { applyHighlightedCatchIfNeeded() }
                .onChange(of: dexMode, handleDexModeChange)
                .onChange(of: session.highlightedCatchID) { _, _ in applyHighlightedCatchIfNeeded() }
                .onChange(of: session.catches.count) { _, _ in syncSelectedCatch() }
                .onChange(of: fishForDetail, updateTabBarFromFishDetail)
                .onChange(of: catchIDForDetail, updateTabBarFromCatchDetail)
        }
    }

    private var dexRoot: some View {
        VStack(spacing: 0) {
            AppHeaderView(onLogoTap: onLogoTap)
            DexSearchBar(
                text: $searchText,
                placeholder: dexMode == .dex ? "Search Dex..." : "Search your catches..."
            )
            DexModeToggle(mode: $dexMode)
            if dexMode == .dex {
                DexSortBar(sort: $sortOption)
            }
            splitPanel
        }
    }

    private var splitPanel: some View {
        HStack(spacing: 0) {
            leftPanel.frame(width: 128)
            panelDivider
            rightPanel.frame(maxWidth: .infinity)
        }
        .frame(maxHeight: .infinity)
    }

    private var panelDivider: some View {
        Rectangle()
            .fill(Color(red: 0.86, green: 0.86, blue: 0.87))
            .frame(width: 1)
    }

    @ViewBuilder
    private var leftPanel: some View {
        if dexMode == .dex {
            DexFishList(fish: sortedDisplayedFish, selectedFish: $selectedFish)
        } else {
            DexCatchList(catches: displayedCatches, selectedCatchID: $selectedCatchID)
        }
    }

    @ViewBuilder
    private var rightPanel: some View {
        if dexMode == .dex {
            if let selectedFish {
                DexDetailPanel(fish: selectedFish) {
                    openFishDetail(for: selectedFish)
                }
            }
        } else if displayedCatches.isEmpty {
            DexMyFishEmptyState()
        } else if let selectedCatch {
            DexCatchDetailPanel(
                catchRow: selectedCatch,
                onOpenCatchDetail: { catchIDForDetail = selectedCatch.id },
                onOpenSpeciesDetail: {
                    if let fish = session.fish(for: selectedCatch) {
                        fishForDetail = fish
                    }
                }
            )
        }
    }

    private func openFishDetail(for fish: Fish) {
        if fish.caught { fishForDetail = fish }
    }

    private func handleDexModeChange(_: DexMode, _ mode: DexMode) {
        searchText = ""
        if mode == .dex {
            selectedFish = sortedDisplayedFish.first
        } else {
            syncSelectedCatch()
        }
    }

    private func updateTabBarFromFishDetail(_: Fish?, _ fish: Fish?) {
        updateTabBarHidden(fishDetail: fish, catchDetail: catchIDForDetail)
    }

    private func updateTabBarFromCatchDetail(_: UUID?, _ catchID: UUID?) {
        updateTabBarHidden(fishDetail: fishForDetail, catchDetail: catchID)
    }

    private func applyHighlightedCatchIfNeeded() {
        guard let catchID = session.highlightedCatchID else { return }
        dexMode = .myFish
        selectedCatchID = catchID
        session.clearHighlightedCatch()
    }

    private func syncSelectedCatch() {
        guard dexMode == .myFish else { return }
        if let selectedCatchID,
           displayedCatches.contains(where: { $0.id == selectedCatchID }) {
            return
        }
        selectedCatchID = displayedCatches.first?.id
    }

    private func updateTabBarHidden(fishDetail: Fish?, catchDetail: UUID?) {
        hidesBottomTabBar = fishDetail != nil || catchDetail != nil
    }
}

// MARK: - Search bar

private struct DexSearchBar: View {
    @Binding var text: String
    var placeholder: String = "Search Dex..."

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: "magnifyingglass")
                .foregroundStyle(FishedexTheme.muted)

            TextField(placeholder, text: $text)
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

// MARK: - Sort bar

private struct DexSortBar: View {
    @Binding var sort: DexSortOption

    private let trackColor = Color(red: 0.90, green: 0.90, blue: 0.91)
    private let selectedFill = Color(red: 0.78, green: 0.80, blue: 0.84)
    private let borderColor = Color.black.opacity(0.14)

    var body: some View {
        VStack(spacing: 0) {
            Rectangle()
                .fill(Color(red: 0.86, green: 0.86, blue: 0.87))
                .frame(height: 1)
                .padding(.horizontal, 16)

            HStack(spacing: 6) {
                Image(systemName: "arrow.up.arrow.down")
                    .font(.system(size: 9, weight: .medium))
                    .foregroundStyle(FishedexTheme.muted.opacity(0.75))

                Text("SORT")
                    .font(FishedexFont.micro)
                    .foregroundStyle(FishedexTheme.muted.opacity(0.75))

                HStack(spacing: 0) {
                    ForEach(DexSortOption.allCases) { option in
                        sortButton(option)
                    }
                }
                .background(trackColor)
                .fishedexSquare()
                .fishedexBorder(lineWidth: 1, color: borderColor)
            }
            .padding(.horizontal, 16)
            .padding(.top, 10)
            .padding(.bottom, 8)
        }
        .background(Color(red: 0.95, green: 0.95, blue: 0.96))
    }

    private func sortButton(_ option: DexSortOption) -> some View {
        Button { sort = option } label: {
            Text(option.title.uppercased())
                .font(FishedexFont.micro)
                .foregroundStyle(sort == option ? FishedexTheme.ink : FishedexTheme.muted.opacity(0.8))
                .frame(maxWidth: .infinity)
                .frame(height: 24)
                .background(sort == option ? selectedFill : Color.clear)
                .fishedexSquare()
                .fishedexBorder(lineWidth: 1, color: borderColor)
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Mode toggle

private struct DexModeToggle: View {
    @Binding var mode: DexMode

    var body: some View {
        HStack(spacing: 0) {
            fishedexModeButton(target: .dex)
            modeButton("MY FISH", target: .myFish)
        }
        .background(Color(red: 0.86, green: 0.86, blue: 0.87))
        .fishedexSquare()
        .fishedexBorder()
        .padding(.horizontal, 16)
        .padding(.bottom, 4)
        .background(Color(red: 0.95, green: 0.95, blue: 0.96))
    }

    private func fishedexModeButton(target: DexMode) -> some View {
        Button { mode = target } label: {
            Text("FISHÉDEX")
                .font(FishedexFont.subheadline)
                .italic()
                .foregroundStyle(mode == target ? .white : FishedexTheme.muted)
                .frame(maxWidth: .infinity)
                .frame(height: 40)
                .background(mode == target ? FishedexTheme.tabBlue : Color.clear)
                .fishedexSquare()
                .fishedexBorder(lineWidth: 1)
        }
        .buttonStyle(.plain)
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
        .contentMargins(.bottom, DexLayout.scrollBottomInset, for: .scrollContent)
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
                    FishArtworkView(fish: fish, height: 68, showsShadow: false)
                        .frame(maxWidth: .infinity)
                } else {
                    MysteryFishSilhouetteView()
                        .frame(maxWidth: .infinity)
                }
            }
            .padding(.top, 4)

            Text(fish.name.uppercased())
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

// MARK: - My Fish catch list

private struct DexCatchList: View {
    @EnvironmentObject private var session: SessionManager

    let catches: [UserCatchRow]
    @Binding var selectedCatchID: UUID?

    var body: some View {
        ScrollView(showsIndicators: false) {
            LazyVStack(spacing: 6) {
                ForEach(catches) { catchRow in
                    DexCatchCell(
                        catchRow: catchRow,
                        isSelected: selectedCatchID == catchRow.id
                    )
                    .onTapGesture {
                        withAnimation(.easeInOut(duration: 0.15)) {
                            selectedCatchID = catchRow.id
                        }
                    }
                }
            }
            .padding(8)
        }
        .contentMargins(.bottom, DexLayout.scrollBottomInset, for: .scrollContent)
        .background(Color(red: 0.95, green: 0.95, blue: 0.96))
    }
}

private struct DexCatchCell: View {
    @EnvironmentObject private var session: SessionManager

    let catchRow: UserCatchRow
    let isSelected: Bool

    private var fish: Fish? { session.fish(for: catchRow) }

    var body: some View {
        VStack(spacing: 4) {
            Group {
                if let fish {
                    FishArtworkView(fish: fish, height: 68, showsShadow: false)
                        .frame(maxWidth: .infinity)
                } else {
                    MysteryFishSilhouetteView()
                        .frame(maxWidth: .infinity)
                }
            }
            .padding(.top, 4)

            Text(session.catchTitle(for: catchRow).uppercased())
                .font(FishedexFont.micro)
                .foregroundStyle(isSelected ? .white : FishedexTheme.ink)
                .lineLimit(2)
                .multilineTextAlignment(.center)
                .minimumScaleFactor(0.75)
                .frame(maxWidth: .infinity)

            Text(session.catchSpeciesName(for: catchRow).uppercased())
                .font(FishedexFont.micro)
                .foregroundStyle(isSelected ? .white.opacity(0.78) : FishedexTheme.muted)
                .lineLimit(2)
                .multilineTextAlignment(.center)
                .minimumScaleFactor(0.75)
                .frame(maxWidth: .infinity)
        }
        .padding(.bottom, 8)
        .padding(.horizontal, 4)
        .background(isSelected ? FishedexTheme.ocean : Color.white)
        .fishedexSquare()
        .fishedexBorder(lineWidth: isSelected ? 2 : 1)
    }
}

// MARK: - My Fish catch detail panel

private struct DexCatchDetailPanel: View {
    @EnvironmentObject private var session: SessionManager

    let catchRow: UserCatchRow
    let onOpenCatchDetail: () -> Void
    let onOpenSpeciesDetail: () -> Void

    private var fish: Fish? { session.fish(for: catchRow) }
    private var accent: Color {
        fish.map { FishedexTheme.accent(for: $0) } ?? FishedexTheme.tabBlue
    }

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 0) {
                Button(action: onOpenSpeciesDetail) {
                    Group {
                        if let fish {
                            FishArtworkView(fish: fish, height: 120, showsShadow: true)
                        } else {
                            MysteryFishSilhouetteView()
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(accent.opacity(0.08))
                }
                .buttonStyle(.plain)
                .disabled(fish == nil)
                .padding(.top, 14)

                VStack(alignment: .leading, spacing: 12) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(session.catchTitle(for: catchRow).uppercased())
                            .font(FishedexFont.title2)
                            .foregroundStyle(FishedexTheme.ink)
                            .fixedSize(horizontal: false, vertical: true)

                        if fish != nil {
                            Button(action: onOpenSpeciesDetail) {
                                Text(session.catchSpeciesName(for: catchRow).uppercased())
                                    .font(FishedexFont.subheadline)
                                    .foregroundStyle(FishedexTheme.tabBlue)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                            }
                            .buttonStyle(.plain)
                        } else {
                            Text(session.catchSpeciesName(for: catchRow).uppercased())
                                .font(FishedexFont.subheadline)
                                .foregroundStyle(FishedexTheme.tabBlue)
                        }
                    }

                    VStack(spacing: 8) {
                        DexCatchFactLine(
                            label: "CAUGHT",
                            value: catchRow.caughtAt.formatted(date: .abbreviated, time: .shortened)
                        )
                        if let location = catchRow.locationName, !location.isEmpty {
                            DexCatchFactLine(label: "LOCATION", value: location)
                        }
                        if let weight = catchRow.weightKg {
                            DexCatchFactLine(label: "WEIGHT", value: String(format: "%.1f kg", weight))
                        }
                        if let length = catchRow.lengthCm {
                            DexCatchFactLine(label: "LENGTH", value: String(format: "%.0f cm", length))
                        }
                        if let bait = catchRow.bait, !bait.isEmpty {
                            DexCatchFactLine(label: "BAIT", value: bait)
                        }
                    }

                    if let notes = catchRow.notes, !notes.isEmpty {
                        Text(notes)
                            .font(FishedexFont.caption)
                            .foregroundStyle(FishedexTheme.muted)
                            .fixedSize(horizontal: false, vertical: true)
                    }

                    Button(action: onOpenCatchDetail) {
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
                .padding(.horizontal, 16)
                .padding(.bottom, 24)
            }
        }
        .contentMargins(.bottom, DexLayout.scrollBottomInset, for: .scrollContent)
        .background(Color.white)
    }
}

private struct DexCatchFactLine: View {
    let label: String
    let value: String

    var body: some View {
        HStack(alignment: .top, spacing: 8) {
            Text(label)
                .font(FishedexFont.micro)
                .foregroundStyle(FishedexTheme.muted)
                .lineLimit(1)
                .fixedSize(horizontal: true, vertical: false)

            Text(value.uppercased())
                .font(FishedexFont.caption)
                .foregroundStyle(FishedexTheme.ink)
                .multilineTextAlignment(.leading)
                .fixedSize(horizontal: false, vertical: true)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
    }
}

// MARK: - Right detail panel

private struct CatchDetailDestination: View {
    @EnvironmentObject private var session: SessionManager
    let catchID: UUID

    var body: some View {
        CatchDetailView(catchID: catchID)
    }
}

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
        .contentMargins(.bottom, DexLayout.scrollBottomInset, for: .scrollContent)
        .background(Color.white)
    }

    private var artworkCard: some View {
        Group {
            if fish.caught {
                FishArtworkView(fish: fish, height: 120, showsShadow: true)
            } else {
                MysteryFishSilhouetteView(height: 120)
            }
        }
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

            Rectangle()
                .fill(Color(red: 0.86, green: 0.86, blue: 0.87))
                .frame(height: 1)
                .padding(.top, 4)

            detailSection
        }
    }

    private var fishNameText: some View {
        Text(fish.name.uppercased())
            .font(FishedexFont.title2)
            .foregroundStyle(FishedexTheme.ink)
            .fixedSize(horizontal: false, vertical: true)
            .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var nameBlock: some View {
        VStack(alignment: .leading, spacing: 2) {
            if fish.caught {
                Button(action: onOpenDetail) {
                    fishNameText
                }
                .buttonStyle(.plain)
            } else {
                fishNameText
            }

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

    @ViewBuilder
    private var detailSection: some View {
        VStack(spacing: 10) {
            if fish.caught {
                Button(action: onOpenDetail) {
                    viewDetailsLabel(foreground: .white, background: FishedexTheme.tabBlue)
                }
                .buttonStyle(.plain)
            } else {
                viewDetailsLabel(
                    foreground: FishedexTheme.muted,
                    background: Color(red: 0.86, green: 0.86, blue: 0.87)
                )

                Text("Please discover this fish first to view details.")
                    .font(FishedexFont.caption)
                    .foregroundStyle(FishedexTheme.muted)
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
                    .frame(maxWidth: .infinity)
            }
        }
        .padding(.top, 4)
        .padding(.bottom, 2)
    }

    private func viewDetailsLabel(foreground: Color, background: Color) -> some View {
        Text("VIEW DETAILS")
            .font(FishedexFont.headline)
            .foregroundStyle(foreground)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .background(background)
            .fishedexSquare()
            .fishedexBorder()
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
            PixelGrayFishIconView()

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
