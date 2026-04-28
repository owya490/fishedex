import SwiftUI

struct FishDetailView: View {
    let fish: Fish
    @State private var selectedTab: FishDetailTab = .about

    private var accent: Color {
        FishedexTheme.accent(for: fish)
    }

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 0) {
                hero
                detailCard
                    .offset(y: -26)
            }
        }
        .background(FishedexTheme.background.ignoresSafeArea())
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(.hidden, for: .navigationBar)
    }

    private var hero: some View {
        ZStack(alignment: .top) {
            RoundedRectangle(cornerRadius: 36, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [
                            accent.opacity(0.98),
                            accent.opacity(0.78),
                            FishedexTheme.cream
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .frame(height: 430)
                .ignoresSafeArea(edges: .top)

            Circle()
                .stroke(Color.white.opacity(0.28), lineWidth: 42)
                .frame(width: 285, height: 285)
                .offset(y: 86)

            VStack(spacing: 18) {
                HStack {
                    Image(systemName: "circle.hexagongrid.circle.fill")
                        .font(.title2)
                        .foregroundStyle(.white.opacity(0.86))

                    Text(fish.name)
                        .font(.title2.bold())
                        .foregroundStyle(.white)

                    Spacer()

                    Text(fish.number)
                        .font(.title3.weight(.bold))
                        .foregroundStyle(.white.opacity(0.82))
                }
                .padding(.horizontal, 24)
                .padding(.top, 20)

                FishArtworkView(fish: fish, height: 245)
                    .padding(.top, 6)

                TraitPill(label: fish.habitat.lowercased(), tint: .white)
                    .padding(.top, 2)
            }
        }
    }

    private var detailCard: some View {
        VStack(spacing: 22) {
            tabPicker

            Group {
                switch selectedTab {
                case .about:
                    aboutContent
                case .status:
                    statusContent
                case .moves:
                    movesContent
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(22)
        .frame(maxWidth: .infinity)
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 36, style: .continuous))
        .shadow(color: Color.black.opacity(0.08), radius: 24, x: 0, y: -4)
        .padding(.horizontal, 10)
    }

    private var tabPicker: some View {
        HStack(spacing: 0) {
            ForEach(FishDetailTab.allCases) { tab in
                Button {
                    selectedTab = tab
                } label: {
                    Text(tab.rawValue)
                        .font(.headline.weight(.semibold))
                        .foregroundStyle(selectedTab == tab ? FishedexTheme.ink : FishedexTheme.muted)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(selectedTab == tab ? accent.opacity(0.88) : Color.clear)
                }
            }
        }
        .background(FishedexTheme.cream.opacity(0.75))
        .clipShape(Capsule())
    }

    private var aboutContent: some View {
        VStack(alignment: .leading, spacing: 18) {
            Text("\"\(fish.about)\"")
                .font(.body.italic())
                .foregroundStyle(FishedexTheme.muted)
                .fixedSize(horizontal: false, vertical: true)

            VStack(spacing: 12) {
                DetailFactRow(label: "Height", value: fish.height)
                DetailFactRow(label: "Weight", value: fish.weight)
                DetailFactRow(label: "Water", value: fish.waterType)
                DetailFactRow(label: "Season", value: fish.season)
                DetailFactRow(label: "Depth", value: fish.depth)
            }

            VStack(alignment: .leading, spacing: 10) {
                Text("Strong traits")
                    .font(.headline.weight(.bold))
                    .foregroundStyle(FishedexTheme.ink)

                FlowLayout(spacing: 8) {
                    ForEach(fish.traits, id: \.self) { trait in
                        TraitPill(label: trait, tint: accent)
                    }
                }
            }
            .padding(.top, 4)
        }
    }

    private var statusContent: some View {
        VStack(alignment: .leading, spacing: 18) {
            Text("Catch Profile")
                .font(.title3.bold())
                .foregroundStyle(FishedexTheme.ink)

            ForEach(fish.stats) { stat in
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text(stat.name)
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(FishedexTheme.ink)

                        Spacer()

                        Text("\(stat.value)")
                            .font(.subheadline.weight(.bold))
                            .foregroundStyle(FishedexTheme.muted)
                    }

                    GeometryReader { proxy in
                        RoundedRectangle(cornerRadius: 6, style: .continuous)
                            .fill(FishedexTheme.softLine)
                            .overlay(alignment: .leading) {
                                RoundedRectangle(cornerRadius: 6, style: .continuous)
                                    .fill(accent)
                                    .frame(width: proxy.size.width * CGFloat(stat.value) / 100)
                            }
                    }
                    .frame(height: 10)
                }
            }
        }
    }

    private var movesContent: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Signature Moves")
                .font(.title3.bold())
                .foregroundStyle(FishedexTheme.ink)

            ForEach(fish.moves, id: \.self) { move in
                HStack(spacing: 12) {
                    Image(systemName: "sparkle")
                        .font(.headline.weight(.bold))
                        .foregroundStyle(accent)
                        .frame(width: 34, height: 34)
                        .background(accent.opacity(0.14))
                        .clipShape(Circle())

                    Text(move)
                        .font(.headline.weight(.semibold))
                        .foregroundStyle(FishedexTheme.ink)

                    Spacer()
                }
                .padding(14)
                .background(FishedexTheme.background)
                .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
            }
        }
    }
}

private struct DetailFactRow: View {
    let label: String
    let value: String

    var body: some View {
        HStack {
            Text(label)
                .font(.headline.weight(.semibold))
                .foregroundStyle(FishedexTheme.muted.opacity(0.72))
                .frame(width: 92, alignment: .leading)

            Text(value)
                .font(.headline.weight(.bold))
                .foregroundStyle(FishedexTheme.ink)

            Spacer()
        }
    }
}

private struct FlowLayout<Content: View>: View {
    let spacing: CGFloat
    @ViewBuilder let content: Content

    var body: some View {
        HStack(spacing: spacing) {
            content
        }
    }
}
