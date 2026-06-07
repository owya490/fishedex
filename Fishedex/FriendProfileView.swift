import SwiftUI

struct FriendProfileView: View {
    @EnvironmentObject private var session: SessionManager
    @Environment(\.dismiss) private var dismiss

    let friendId: UUID

    @State private var profile: ProfileRow?
    @State private var topCatches: [UserCatchRow] = []
    @State private var allCatches: [UserCatchRow] = []
    @State private var isLoading = true
    @State private var loadError: String?

    private var stats: AnglerStats {
        session.friendStats(for: allCatches, totalSpecies: session.stats.totalSpecies)
    }

    var body: some View {
        VStack(spacing: 0) {
            AppHeaderView(onBack: { dismiss() }, showsProfileButton: false, showsProfileAvatar: false)

            if isLoading {
                Spacer()
                ProgressView()
                Spacer()
            } else if let loadError {
                Spacer()
                Text(loadError.uppercased())
                    .font(FishedexFont.caption)
                    .foregroundStyle(FishedexTheme.muted)
                    .multilineTextAlignment(.center)
                    .padding()
                Spacer()
            } else {
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 16) {
                        identityCard
                        collectionCard
                        topCatchesSection
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 20)
                }
            }
        }
        .background(Color(red: 0.95, green: 0.95, blue: 0.96).ignoresSafeArea())
        .navigationBarBackButtonHidden(true)
        .toolbar(.hidden, for: .navigationBar)
        .task { await loadFriendData() }
    }

    private var identityCard: some View {
        VStack(spacing: 0) {
            ProfileAvatarView(urlString: profile?.avatarUrl, size: 180)
                .padding(.top, 20)
                .padding(.bottom, 14)

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

            FishedexProgressBar(progress: stats.progress)

            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("TOTAL WEIGHT")
                        .font(FishedexFont.micro)
                        .foregroundStyle(FishedexTheme.muted)
                    Text(formattedWeight(stats.totalWeightKg))
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

    private var topCatchesSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("TOP 6 FISH CAUGHT")
                .font(FishedexFont.headline)
                .foregroundStyle(FishedexTheme.ink)

            if topCatches.isEmpty {
                Text("No catches logged yet.")
                    .font(FishedexFont.caption)
                    .foregroundStyle(FishedexTheme.muted)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.vertical, 24)
            } else {
                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                    ForEach(topCatches) { catchRow in
                        topCatchCard(catchRow)
                    }
                }
            }
        }
        .padding(18)
        .background(Color.white)
        .fishedexSquare()
        .fishedexBorder()
    }

    private func topCatchCard(_ catchRow: UserCatchRow) -> some View {
        VStack(spacing: 8) {
            Group {
                if catchRow.photoUrl != nil {
                    CachedRemoteImage(
                        urlString: catchRow.photoUrl,
                        content: { $0.resizable().scaledToFill() },
                        placeholder: { fishArtwork(for: catchRow) },
                        failure: { fishArtwork(for: catchRow) }
                    )
                } else {
                    fishArtwork(for: catchRow)
                }
            }
            .frame(height: 80)
            .frame(maxWidth: .infinity)
            .clipped()
            .fishedexSquare()
            .fishedexBorder(lineWidth: 1)

            Text(session.fishName(for: catchRow).uppercased())
                .font(FishedexFont.caption)
                .foregroundStyle(FishedexTheme.ink)
                .lineLimit(2)
                .multilineTextAlignment(.center)

            if let weight = catchRow.weightKg {
                Text(String(format: "%.1f KG", weight))
                    .font(FishedexFont.micro)
                    .foregroundStyle(FishedexTheme.ocean)
            }
        }
        .padding(10)
        .background(Color.white)
        .fishedexSquare()
        .fishedexBorder(lineWidth: 1)
    }

    @ViewBuilder
    private func fishArtwork(for catchRow: UserCatchRow) -> some View {
        Image(session.fishImageName(for: catchRow))
            .resizable()
            .interpolation(.none)
            .scaledToFit()
            .padding(8)
    }

    private func formattedWeight(_ kg: Double) -> String {
        if kg <= 0 { return "0 KG" }
        return String(format: "%.1f KG", kg)
    }

    private func loadFriendData() async {
        isLoading = true
        loadError = nil
        defer { isLoading = false }

        do {
            async let profileFetch = session.fetchFriendProfile(id: friendId)
            async let catchesFetch = session.fetchFriendCatches(userId: friendId)

            let (fetchedProfile, fetchedCatches) = try await (profileFetch, catchesFetch)
            profile = fetchedProfile
            allCatches = fetchedCatches
            topCatches = try await session.fetchFriendTopCatches(userId: friendId)
        } catch {
            loadError = error.localizedDescription
        }
    }
}

#Preview {
    NavigationStack {
        FriendProfileView(friendId: UUID())
            .environmentObject(SessionManager())
    }
}
