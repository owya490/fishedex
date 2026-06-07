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
            Rectangle()
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

            Rectangle()
                .stroke(Color.white.opacity(0.28), lineWidth: 3)
                .frame(width: 285, height: 285)
                .offset(y: 86)

            VStack(spacing: 18) {
                HStack {
                    Image(systemName: "circle.hexagongrid.circle.fill")
                        .font(.title2)
                        .foregroundStyle(.white.opacity(0.86))

                    Text(fish.name)
                        .font(FishedexFont.title)
                        .foregroundStyle(.white)

                    Spacer()

                    Text(fish.number)
                        .font(FishedexFont.title3)
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
        .fishedexSquare()
        .fishedexBorder()
        .padding(.horizontal, 10)
    }

    private var tabPicker: some View {
        HStack(spacing: 0) {
            ForEach(FishDetailTab.allCases) { tab in
                Button {
                    selectedTab = tab
                } label: {
                    Text(tab.rawValue)
                        .font(FishedexFont.headline)
                        .foregroundStyle(selectedTab == tab ? FishedexTheme.ink : FishedexTheme.muted)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(selectedTab == tab ? accent.opacity(0.88) : Color.clear)
                        .fishedexSquare()
                        .fishedexBorder(lineWidth: 1)
                }
            }
        }
        .background(FishedexTheme.cream.opacity(0.75))
        .fishedexSquare()
        .fishedexBorder()
    }

    private var aboutContent: some View {
        VStack(alignment: .leading, spacing: 18) {
            Text("\"\(fish.about)\"")
                .font(FishedexFont.body)
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
                    .font(FishedexFont.headline)
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
                .font(FishedexFont.title3)
                .foregroundStyle(FishedexTheme.ink)

            ForEach(fish.stats) { stat in
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text(stat.name)
                            .font(FishedexFont.subheadline)
                            .foregroundStyle(FishedexTheme.ink)

                        Spacer()

                        Text("\(stat.value)")
                            .font(FishedexFont.subheadline)
                            .foregroundStyle(FishedexTheme.muted)
                    }

                    GeometryReader { proxy in
                        Rectangle()
                            .fill(FishedexTheme.softLine)
                            .overlay(alignment: .leading) {
                                Rectangle()
                                    .fill(accent)
                                    .frame(width: proxy.size.width * CGFloat(stat.value) / 100)
                            }
                            .fishedexBorder(lineWidth: 1)
                    }
                    .frame(height: 10)
                }
            }
        }
    }

    private var movesContent: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Signature Moves")
                .font(FishedexFont.title3)
                .foregroundStyle(FishedexTheme.ink)

            ForEach(fish.moves, id: \.self) { move in
                HStack(spacing: 12) {
                    Image(systemName: "sparkle")
                        .font(.headline.weight(.bold))
                        .foregroundStyle(accent)
                        .frame(width: 34, height: 34)
                        .background(accent.opacity(0.14))
                        .fishedexSquare()
                        .fishedexBorder(lineWidth: 1)

                    Text(move)
                        .font(FishedexFont.headline)
                        .foregroundStyle(FishedexTheme.ink)

                    Spacer()
                }
                .padding(14)
                .background(FishedexTheme.background)
                .fishedexSquare()
                .fishedexBorder(lineWidth: 1)
            }
        }
    }
}

#Preview {
    NavigationStack {
        FishDetailView(fish: Fish.samples[0])
    }
}

private struct DetailFactRow: View {
    let label: String
    let value: String

    var body: some View {
        HStack {
            Text(label)
                .font(FishedexFont.subheadline)
                .foregroundStyle(FishedexTheme.muted.opacity(0.72))
                .frame(width: 92, alignment: .leading)

            Text(value)
                .font(FishedexFont.subheadline)
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
