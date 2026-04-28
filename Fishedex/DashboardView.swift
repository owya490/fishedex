import SwiftUI

struct DashboardView: View {
    let fish: [Fish]

    private var caughtFish: [Fish] {
        fish.filter(\.caught)
    }

    private var featuredFish: Fish {
        caughtFish.first ?? fish[0]
    }

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 24) {
                header
                heroCard
                statsGrid
                recentCatches
            }
            .padding(.horizontal, 20)
            .padding(.top, 8)
            .padding(.bottom, 24)
        }
        .background(FishedexTheme.background.ignoresSafeArea())
        .navigationBarTitleDisplayMode(.inline)
        .toolbar(.hidden, for: .navigationBar)
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Your pocket guide")
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(FishedexTheme.ocean)

            Text("Track catches, discover species, and build your fish collection.")
                .font(.title.bold())
                .foregroundStyle(FishedexTheme.ink)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    private var heroCard: some View {
        NavigationLink(value: featuredFish) {
            ZStack(alignment: .bottomLeading) {
                RoundedRectangle(cornerRadius: 34, style: .continuous)
                    .fill(
                        LinearGradient(
                            colors: [
                                FishedexTheme.accent(for: featuredFish).opacity(0.96),
                                FishedexTheme.cream
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )

                Circle()
                    .fill(Color.white.opacity(0.26))
                    .frame(width: 230, height: 230)
                    .offset(x: 140, y: -78)

                VStack(alignment: .leading, spacing: 18) {
                    HStack {
                        VStack(alignment: .leading, spacing: 6) {
                            Text("Featured Catch")
                                .font(.caption.weight(.bold))
                                .textCase(.uppercase)
                                .foregroundStyle(Color.white.opacity(0.82))

                            Text(featuredFish.name)
                                .font(.title.bold())
                                .foregroundStyle(.white)
                        }

                        Spacer()

                        Text(featuredFish.number)
                            .font(.headline.weight(.bold))
                            .foregroundStyle(.white.opacity(0.82))
                    }

                    FishArtworkView(fish: featuredFish, height: 170)
                        .frame(maxWidth: .infinity)

                    HStack {
                        TraitPill(label: featuredFish.habitat, tint: .white)
                        TraitPill(label: featuredFish.rarity, tint: .white)
                        Spacer()
                        Image(systemName: "chevron.right")
                            .font(.headline.weight(.bold))
                            .foregroundStyle(.white)
                    }
                }
                .padding(22)
            }
            .frame(height: 320)
            .contentShape(RoundedRectangle(cornerRadius: 34, style: .continuous))
        }
        .buttonStyle(.plain)
    }

    private var statsGrid: some View {
        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 14) {
            DashboardStatCard(title: "Caught", value: "\(caughtFish.count)/\(fish.count)", caption: "species logged", icon: "checkmark.seal.fill", tint: FishedexTheme.ocean)
            DashboardStatCard(title: "Rarest", value: "Legendary", caption: "best find", icon: "sparkles", tint: FishedexTheme.coral)
            DashboardStatCard(title: "Hotspot", value: "Reef", caption: "most active", icon: "water.waves", tint: Color(red: 0.35, green: 0.65, blue: 0.90))
            DashboardStatCard(title: "Streak", value: "3 days", caption: "keep fishing", icon: "flame.fill", tint: Color(red: 0.95, green: 0.65, blue: 0.20))
        }
    }

    private var recentCatches: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Recent Catches")
                .font(.title3.bold())
                .foregroundStyle(FishedexTheme.ink)

            ForEach(caughtFish.prefix(3)) { fish in
                NavigationLink(value: fish) {
                    FishRowView(fish: fish)
                }
                .buttonStyle(.plain)
            }
        }
    }
}

private struct DashboardStatCard: View {
    let title: String
    let value: String
    let caption: String
    let icon: String
    let tint: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Image(systemName: icon)
                .font(.title3.weight(.bold))
                .foregroundStyle(tint)

            Text(value)
                .font(.title2.bold())
                .foregroundStyle(FishedexTheme.ink)

            Text(title)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(FishedexTheme.ink)

            Text(caption)
                .font(.caption)
                .foregroundStyle(FishedexTheme.muted)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(18)
        .fishedexCard(cornerRadius: 24)
    }
}
