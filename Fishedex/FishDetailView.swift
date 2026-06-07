import SwiftUI

struct FishDetailView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var session: SessionManager

    let fish: Fish
    @State private var selectedTab: FishDetailTab = .about
    @State private var viewerPhotoIndex: Int?

    private var accent: Color {
        FishedexTheme.accent(for: fish)
    }

    private var speciesCatches: [UserCatchRow] {
        session.catches
            .filter { $0.speciesId == fish.id }
            .sorted { $0.caughtAt > $1.caughtAt }
    }

    var body: some View {
        VStack(spacing: 0) {
            AppHeaderView(onBack: { dismiss() })

            ScrollView(showsIndicators: false) {
                VStack(spacing: 16) {
                    heroCard
                    tabPicker
                    tabContent
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 20)
            }
        }
        .background(Color(red: 0.95, green: 0.95, blue: 0.96).ignoresSafeArea())
        .navigationBarBackButtonHidden(true)
        .toolbar(.hidden, for: .navigationBar)
        .fullScreenCover(isPresented: viewerPresented) {
            PhotoViewerOverlay(
                photos: speciesPhotos,
                selectedIndex: $viewerPhotoIndex
            )
        }
    }

    private var speciesPhotos: [CatchPhotoRow] {
        session.photos(forSpecies: fish.id)
    }

    private var viewerPresented: Binding<Bool> {
        Binding(
            get: { viewerPhotoIndex != nil },
            set: { if !$0 { viewerPhotoIndex = nil } }
        )
    }

    private var heroCard: some View {
        VStack(spacing: 0) {
            FishArtworkView(fish: fish, height: 140, showsShadow: true)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 18)
                .background(accent.opacity(0.08))

            VStack(alignment: .leading, spacing: 8) {
                Text(fish.name.uppercased())
                    .font(FishedexFont.title2)
                    .foregroundStyle(FishedexTheme.ink)
                    .fixedSize(horizontal: false, vertical: true)

                Text(fish.number)
                    .font(FishedexFont.subheadline)
                    .foregroundStyle(FishedexTheme.tabBlue)

                TraitPill(label: fish.habitat.uppercased(), tint: accent)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(16)
        }
        .background(Color.white)
        .fishedexSquare()
        .fishedexBorder()
    }

    private var tabPicker: some View {
        HStack(spacing: 0) {
            ForEach(FishDetailTab.allCases) { tab in
                Button {
                    selectedTab = tab
                } label: {
                    Text(tab.rawValue.uppercased())
                        .font(FishedexFont.micro)
                        .foregroundStyle(selectedTab == tab ? .white : FishedexTheme.muted)
                        .lineLimit(1)
                        .minimumScaleFactor(0.7)
                        .frame(maxWidth: .infinity)
                        .frame(height: 40)
                        .background(selectedTab == tab ? FishedexTheme.tabBlue : Color.clear)
                        .fishedexSquare()
                        .fishedexBorder(lineWidth: 1)
                }
                .buttonStyle(.plain)
            }
        }
        .background(Color(red: 0.86, green: 0.86, blue: 0.87))
        .fishedexSquare()
        .fishedexBorder()
    }

    @ViewBuilder
    private var tabContent: some View {
        Group {
            switch selectedTab {
            case .about:
                aboutContent
            case .status:
                statusContent
            case .gallery:
                galleryContent
            case .myFish:
                myFishContent
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .background(Color.white)
        .fishedexSquare()
        .fishedexBorder()
    }

    private var aboutContent: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text(fish.about)
                .font(FishedexFont.body)
                .foregroundStyle(FishedexTheme.muted)
                .fixedSize(horizontal: false, vertical: true)

            VStack(spacing: 8) {
                DetailFactRow(label: "Height", value: fish.height)
                DetailFactRow(label: "Weight", value: fish.weight)
                DetailFactRow(label: "Water", value: fish.waterType)
                DetailFactRow(label: "Season", value: fish.season)
                DetailFactRow(label: "Depth", value: fish.depth)
            }

            if !fish.traits.isEmpty {
                VStack(alignment: .leading, spacing: 10) {
                    Text("TRAITS")
                        .font(FishedexFont.caption)
                        .foregroundStyle(FishedexTheme.muted)
                        .kerning(0.6)

                    HStack(spacing: 8) {
                        ForEach(fish.traits, id: \.self) { trait in
                            TraitPill(label: trait, tint: accent)
                        }
                    }
                }
            }
        }
    }

    private var statusContent: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("CATCH PROFILE")
                .font(FishedexFont.caption)
                .foregroundStyle(FishedexTheme.muted)
                .kerning(0.6)

            ForEach(fish.stats) { stat in
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text(stat.name.uppercased())
                            .font(FishedexFont.subheadline)
                            .foregroundStyle(FishedexTheme.ink)

                        Spacer()

                        Text("\(stat.value)")
                            .font(FishedexFont.subheadline)
                            .foregroundStyle(FishedexTheme.muted)
                    }

                    GeometryReader { proxy in
                        Rectangle()
                            .fill(Color(red: 0.86, green: 0.86, blue: 0.87))
                            .overlay(alignment: .leading) {
                                Rectangle()
                                    .fill(FishedexTheme.tabBlue)
                                    .frame(width: proxy.size.width * CGFloat(stat.value) / 100)
                            }
                            .fishedexBorder(lineWidth: 1)
                    }
                    .frame(height: 12)
                }
            }
        }
    }

    private var galleryContent: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("SPECIES GALLERY")
                .font(FishedexFont.caption)
                .foregroundStyle(FishedexTheme.muted)
                .kerning(0.6)

            Text("All photos from every catch of this species.")
                .font(FishedexFont.caption)
                .foregroundStyle(FishedexTheme.muted)
                .fixedSize(horizontal: false, vertical: true)

            if speciesPhotos.isEmpty {
                FishEmptyStateView(
                    message: "You have not caught any fish or uploaded any photos of this species."
                )
            } else {
                CatchPhotoGalleryGrid(
                    photos: speciesPhotos,
                    fish: fish,
                    onPhotoTap: { viewerPhotoIndex = $0 }
                )
            }
        }
    }

    private var myFishContent: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("MY FISH")
                .font(FishedexFont.caption)
                .foregroundStyle(FishedexTheme.muted)
                .kerning(0.6)

            if speciesCatches.isEmpty {
                FishEmptyStateView(
                    message: "You haven't caught this species yet."
                )
            } else {
                VStack(spacing: 8) {
                    ForEach(speciesCatches) { catchRow in
                        NavigationLink {
                            CatchDetailView(catchID: catchRow.id)
                        } label: {
                            YourFishCatchRow(catchRow: catchRow, fish: fish, session: session)
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }
    }
}

#Preview {
    NavigationStack {
        FishDetailView(fish: Fish.samples[0])
            .environmentObject(SessionManager())
    }
}

private struct FishEmptyStateView: View {
    let message: String

    var body: some View {
        VStack(spacing: 10) {
            PixelGrayFishIconView()

            Text(message)
                .font(FishedexFont.subheadline)
                .foregroundStyle(FishedexTheme.ink)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 20)
    }
}

private struct DetailFactRow: View {
    let label: String
    let value: String

    var body: some View {
        HStack {
            Text(label.uppercased())
                .font(FishedexFont.micro)
                .foregroundStyle(FishedexTheme.muted)
                .kerning(0.4)
                .frame(width: 72, alignment: .leading)

            Text(value)
                .font(FishedexFont.subheadline)
                .foregroundStyle(FishedexTheme.ink)

            Spacer()
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 8)
        .background(Color(red: 0.95, green: 0.95, blue: 0.96))
        .fishedexSquare()
        .fishedexBorder(lineWidth: 1)
    }
}

private struct YourFishCatchRow: View {
    let catchRow: UserCatchRow
    let fish: Fish
    let session: SessionManager

    var body: some View {
        HStack(spacing: 12) {
            FishArtworkView(fish: fish, height: 44, showsShadow: false)
                .frame(width: 48, height: 48)
                .fishedexSquare()
                .clipped()

            VStack(alignment: .leading, spacing: 4) {
                Text(session.catchTitle(for: catchRow).uppercased())
                    .font(FishedexFont.subheadline)
                    .foregroundStyle(FishedexTheme.ink)

                Text(session.catchSpeciesName(for: catchRow).uppercased())
                    .font(FishedexFont.caption)
                    .foregroundStyle(FishedexTheme.tabBlue)

                Text(catchRow.caughtAt.formatted(date: .abbreviated, time: .shortened))
                    .font(FishedexFont.caption)
                    .foregroundStyle(FishedexTheme.muted)
            }

            Spacer()

            if let weight = catchRow.weightKg {
                Text(String(format: "%.1f kg", weight))
                    .font(FishedexFont.subheadline)
                    .foregroundStyle(FishedexTheme.tabBlue)
            }
        }
        .padding(12)
        .background(Color(red: 0.95, green: 0.95, blue: 0.96))
        .fishedexSquare()
        .fishedexBorder(lineWidth: 1)
    }
}
