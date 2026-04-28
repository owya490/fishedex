import SwiftUI

struct FishedexListView: View {
    let fish: [Fish]
    @State private var searchText = ""
    @State private var selectedFilter: FishCollectionFilter = .all

    private let columns = Array(repeating: GridItem(.flexible(), spacing: 12), count: 4)

    private var caughtCount: Int {
        fish.filter(\.caught).count
    }

    private var caughtProgress: Double {
        guard !fish.isEmpty else {
            return 0
        }

        return Double(caughtCount) / Double(fish.count)
    }

    private var filteredFish: [Fish] {
        let filteredByStatus = fish.filter { fish in
            switch selectedFilter {
            case .all:
                return true
            case .caught:
                return fish.caught
            case .locked:
                return !fish.caught
            }
        }

        guard !searchText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            return filteredByStatus
        }

        return filteredByStatus.filter { fish in
            fish.searchableText.localizedCaseInsensitiveContains(searchText)
        }
    }

    var body: some View {
        ZStack {
            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 18) {
                    header
                    fishGrid
                }
                .padding(.horizontal, 18)
                .padding(.top, 8)
                .padding(.bottom, 108)
            }
        }
        .background(FishedexTheme.background.ignoresSafeArea())
        .navigationBarTitleDisplayMode(.inline)
        .toolbar(.hidden, for: .navigationBar)
        .safeAreaInset(edge: .bottom) {
            bottomSearchBar
        }
        .overlay {
            if filteredFish.isEmpty {
                ContentUnavailableView(
                    "No fish found",
                    systemImage: "magnifyingglass",
                    description: Text("Try another search or filter.")
                )
            }
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Fishédex")
                .font(.title.bold())
                .foregroundStyle(FishedexTheme.ink)

            Text("\(caughtCount) of \(fish.count) Australian species captured")
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(FishedexTheme.muted)

            ProgressView(value: caughtProgress)
                .tint(FishedexTheme.ink)
                .padding(.top, 8)
        }
    }

    private var fishGrid: some View {
        LazyVGrid(columns: columns, spacing: 16) {
            ForEach(filteredFish) { fish in
                if fish.caught {
                    NavigationLink(value: fish) {
                        FishGridCell(fish: fish)
                    }
                    .buttonStyle(.plain)
                } else {
                    FishGridCell(fish: fish)
                }
            }
        }
    }

    private var bottomSearchBar: some View {
        HStack(spacing: 12) {
            HStack(spacing: 10) {
                Image(systemName: "magnifyingglass")
                    .foregroundStyle(FishedexTheme.muted)

                TextField("Search Fishédex", text: $searchText)
                    .font(.subheadline.weight(.semibold))
                    .textInputAutocapitalization(.never)
                    .disableAutocorrection(true)
            }
            .padding(.horizontal, 16)
            .frame(height: 54)
            .background(Color.white)
            .clipShape(Capsule())
            .shadow(color: Color.black.opacity(0.08), radius: 16, x: 0, y: 8)

            Menu {
                ForEach(FishCollectionFilter.allCases) { filter in
                    Button {
                        selectedFilter = filter
                    } label: {
                        Label(filter.title, systemImage: selectedFilter == filter ? "checkmark" : filter.icon)
                    }
                }
            } label: {
                Image(systemName: selectedFilter.icon)
                    .font(.headline.weight(.bold))
                    .foregroundStyle(FishedexTheme.ink)
                    .frame(width: 54, height: 54)
                    .background(Color.white)
                    .clipShape(Circle())
                    .shadow(color: Color.black.opacity(0.08), radius: 16, x: 0, y: 8)
            }
        }
        .padding(.horizontal, 18)
        .padding(.top, 12)
        .padding(.bottom, 8)
        .background(.ultraThinMaterial)
    }
}

private enum FishCollectionFilter: String, CaseIterable, Identifiable {
    case all
    case caught
    case locked

    var id: String { rawValue }

    var title: String {
        switch self {
        case .all:
            return "All Fish"
        case .caught:
            return "Caught"
        case .locked:
            return "Locked"
        }
    }

    var icon: String {
        switch self {
        case .all:
            return "line.3.horizontal.decrease.circle"
        case .caught:
            return "checkmark.circle"
        case .locked:
            return "lock.circle"
        }
    }
}

private extension Fish {
    var displayName: String {
        name
    }

    var searchableText: String {
        "\(name) \(scientificName) \(habitat) \(rarity) \(number)"
    }
}

private struct FishGridCell: View {
    let fish: Fish

    var body: some View {
        VStack(spacing: 8) {
            ZStack {
                if fish.caught {
                    FishArtworkView(fish: fish, height: 62, showsShadow: false)
                } else {
                    MysteryFishSilhouetteView()
                }

            }
            .frame(height: 74)

            VStack(spacing: 2) {
                Text(fish.displayName)
                    .font(.caption.weight(.bold))
                    .foregroundStyle(FishedexTheme.ink)
                    .lineLimit(1)
                    .minimumScaleFactor(0.72)

                Text(fish.number)
                    .font(.caption2.weight(.semibold))
                    .foregroundStyle(FishedexTheme.muted)
            }
        }
        .frame(maxWidth: .infinity)
        .contentShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
    }
}

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
                    TraitPill(label: fish.rarity, tint: fish.caught ? Color.green : Color.gray)
                }
            }

            Image(systemName: fish.caught ? "checkmark.circle.fill" : "circle.dashed")
                .foregroundStyle(fish.caught ? Color.green : FishedexTheme.muted.opacity(0.55))
        }
        .padding(14)
        .fishedexCard(cornerRadius: 28)
    }
}
