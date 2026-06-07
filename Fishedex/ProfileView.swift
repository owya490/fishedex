import SwiftUI

struct ProfileView: View {
    @EnvironmentObject private var session: SessionManager
    @Environment(\.dismiss) private var dismiss

    private var profile: ProfileRow? { session.profile }
    private var stats: AnglerStats { session.stats }

    var body: some View {
        VStack(spacing: 0) {
            AppHeaderView(onBack: { dismiss() }, showsProfileButton: false)

            ScrollView(showsIndicators: false) {
                VStack(spacing: 16) {
                    identityCard
                    collectionCard
                    achievementsSection
                    signOutButton
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 20)
            }
        }
        .background(Color(red: 0.95, green: 0.95, blue: 0.96).ignoresSafeArea())
    }

    private var identityCard: some View {
        VStack(spacing: 0) {
            ProfileAvatarView(urlString: profile?.avatarUrl, size: 180)
                .padding(.top, 20)

            Text((profile?.rankLabel ?? "NOVICE ANGLER").uppercased())
                .font(FishedexFont.caption)
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 8)
                .background(Color.black)

            VStack(spacing: 8) {
                Text((profile?.displayName ?? "ANGLER").uppercased())
                    .font(FishedexFont.pokemon(22))
                    .foregroundStyle(FishedexTheme.ink)
                    .multilineTextAlignment(.center)

                Text("LV. \(profile?.level ?? 1) \((profile?.statusTitle ?? "ROOKIE ANGLER").uppercased())")
                    .font(FishedexFont.subheadline)
                    .foregroundStyle(FishedexTheme.muted)

                Text("BIOME: \((profile?.currentBiome ?? "LOCAL WATERS").uppercased())")
                    .font(FishedexFont.micro)
                    .foregroundStyle(FishedexTheme.ink)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(Color.white)
                    .fishedexSquare()
                    .fishedexBorder(lineWidth: 1)
            }
            .padding(20)
        }
        .background(Color.white)
        .fishedexSquare()
        .fishedexBorder()
        .shadow(color: .black.opacity(0.12), radius: 0, x: 3, y: 3)
    }

    private var collectionCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("COLLECTION PROGRESS")
                    .font(FishedexFont.caption)
                    .foregroundStyle(FishedexTheme.muted)

                Spacer()

                Text("\(stats.caughtCount) / \(stats.totalSpecies) FISH")
                    .font(FishedexFont.subheadline)
                    .foregroundStyle(FishedexTheme.ocean)
            }

            HStack(alignment: .firstTextBaseline) {
                Text(stats.progressPercentText)
                    .font(FishedexFont.pokemon(28))
                    .foregroundStyle(FishedexTheme.ink)

                Spacer()

                VStack(alignment: .trailing, spacing: 2) {
                    Text("RARE FOUND")
                        .font(FishedexFont.micro)
                        .foregroundStyle(FishedexTheme.muted)
                    Text("\(stats.rareCaughtCount)")
                        .font(FishedexFont.headline)
                        .foregroundStyle(FishedexTheme.headerRed)
                }
            }

            ProfileProgressBlocks(progress: stats.progress, total: 10)

            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("TOTAL WEIGHT")
                        .font(FishedexFont.micro)
                        .foregroundStyle(FishedexTheme.muted)
                    Text(formattedWeight(stats.totalWeightLbs))
                        .font(FishedexFont.headline)
                        .foregroundStyle(FishedexTheme.ink)
                }

                Spacer()

                Text(stats.flavorText)
                    .font(FishedexFont.caption)
                    .italic()
                    .foregroundStyle(FishedexTheme.muted)
            }
        }
        .padding(18)
        .background(Color.white)
        .fishedexSquare()
        .fishedexBorder()
    }

    private var achievementsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("ACHIEVEMENTS")
                    .font(FishedexFont.headline)
                    .foregroundStyle(FishedexTheme.ink)

                Spacer()

                Text("\(stats.unlockedAchievements) / \(stats.totalAchievements) UNLOCKED")
                    .font(FishedexFont.caption)
                    .foregroundStyle(FishedexTheme.muted)
            }

            ProfileProgressBlocks(
                progress: stats.totalAchievements > 0
                    ? Double(stats.unlockedAchievements) / Double(stats.totalAchievements)
                    : 0,
                total: 10
            )

            ForEach(session.achievements.prefix(5)) { achievement in
                HStack {
                    Image(systemName: session.unlockedAchievementIDs.contains(achievement.id) ? "trophy.fill" : "lock.fill")
                        .foregroundStyle(
                            session.unlockedAchievementIDs.contains(achievement.id)
                                ? Color.yellow
                                : FishedexTheme.muted.opacity(0.5)
                        )

                    VStack(alignment: .leading, spacing: 2) {
                        Text(achievement.title.uppercased())
                            .font(FishedexFont.caption)
                            .foregroundStyle(FishedexTheme.ink)
                        Text(achievement.description)
                            .font(FishedexFont.micro)
                            .foregroundStyle(FishedexTheme.muted)
                    }

                    Spacer()
                }
                .padding(10)
                .background(Color.white)
                .fishedexSquare()
                .fishedexBorder(lineWidth: 1)
            }
        }
        .padding(18)
        .background(Color.white)
        .fishedexSquare()
        .fishedexBorder()
    }

    private var signOutButton: some View {
        Button {
            Task { await session.signOut() }
        } label: {
            Text("SIGN OUT")
                .font(FishedexFont.headline)
                .foregroundStyle(FishedexTheme.headerRed)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .background(Color.white)
                .fishedexSquare()
                .fishedexBorder(lineWidth: 1)
        }
        .buttonStyle(.plain)
    }

    private func formattedWeight(_ lbs: Double) -> String {
        if lbs <= 0 { return "0 LBS" }
        return "\(Int(lbs.rounded()).formatted()) LBS"
    }
}

struct ProfileAvatarView: View {
    let urlString: String?
    var size: CGFloat = 44

    var body: some View {
        Group {
            if let urlString, let url = URL(string: urlString) {
                AsyncImage(url: url) { phase in
                    switch phase {
                    case .success(let image):
                        image.resizable().scaledToFill()
                    default:
                        placeholder
                    }
                }
            } else {
                placeholder
            }
        }
        .frame(width: size, height: size)
        .fishedexSquare()
        .fishedexBorder()
        .clipped()
    }

    private var placeholder: some View {
        ZStack {
            Color.white
            Image(systemName: "person.fill")
                .font(.system(size: size * 0.4, weight: .semibold))
                .foregroundStyle(FishedexTheme.muted)
        }
    }
}

private struct ProfileProgressBlocks: View {
    let progress: Double
    let total: Int

    private var filled: Int { Int(Double(total) * min(max(progress, 0), 1)) }

    var body: some View {
        HStack(spacing: 4) {
            ForEach(0..<total, id: \.self) { index in
                Rectangle()
                    .fill(index < filled ? FishedexTheme.progressGreen : Color(red: 0.86, green: 0.86, blue: 0.87))
                    .frame(height: 14)
                    .frame(maxWidth: .infinity)
            }
        }
    }
}

#Preview {
    ProfileView()
        .environmentObject(SessionManager())
}
