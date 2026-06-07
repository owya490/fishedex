import Foundation
import Supabase
import Auth

@MainActor
final class SessionManager: ObservableObject {
    @Published private(set) var isAuthenticated = false
    @Published private(set) var isLoading = true
    @Published private(set) var profile: ProfileRow?
    @Published private(set) var fish: [Fish] = Fish.samples
    @Published private(set) var stats = AnglerStats(
        caughtCount: 0,
        totalSpecies: Fish.samples.count,
        rareCaughtCount: 0,
        totalWeightLbs: 0,
        unlockedAchievements: 0,
        totalAchievements: 0
    )
    @Published private(set) var achievements: [AchievementRow] = []
    @Published private(set) var unlockedAchievementIDs: Set<Int> = []
    @Published var showProfile = false
    @Published var isUploadingAvatar = false
    @Published var errorMessage: String? // surfaced on auth + profile screens

    private var authListenerTask: Task<Void, Never>?

    init() {
        authListenerTask = Task { await listenForAuthChanges() }
    }

    deinit {
        authListenerTask?.cancel()
    }

    func bootstrap() async {
        isLoading = true
        defer { isLoading = false }

        do {
            _ = try await supabase.auth.session
            isAuthenticated = true
            await refreshUserData()
        } catch {
            isAuthenticated = false
            profile = nil
            fish = Fish.samples
            recomputeStats(species: [], catches: [], achievements: [], unlocked: [])
        }
    }

    func signIn(email: String, password: String) async throws {
        errorMessage = nil
        try await supabase.auth.signIn(email: email, password: password)
    }

    func signUp(email: String, password: String, displayName: String) async throws {
        errorMessage = nil
        try await supabase.auth.signUp(
            email: email,
            password: password,
            data: ["display_name": .string(displayName)]
        )
    }

    func uploadAvatar(imageData: Data, contentType: String = "image/jpeg") async {
        guard isAuthenticated else { return }

        isUploadingAvatar = true
        defer { isUploadingAvatar = false }

        do {
            let userID = try await supabase.auth.session.user.id
            let ext = contentType.contains("png") ? "png" : "jpg"
            let path = "\(userID.uuidString)/avatar.\(ext)"

            try await supabase.storage
                .from("avatars")
                .upload(
                    path,
                    data: imageData,
                    options: FileOptions(contentType: contentType, upsert: true)
                )

            let publicURL = try supabase.storage
                .from("avatars")
                .getPublicURL(path: path)

            struct AvatarUpdate: Encodable {
                let avatar_url: String
            }

            try await supabase
                .from("profiles")
                .update(AvatarUpdate(avatar_url: publicURL.absoluteString))
                .eq("id", value: userID.uuidString)
                .execute()

            await refreshUserData()
            errorMessage = nil
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func signOut() async {
        errorMessage = nil
        showProfile = false
        do {
            try await supabase.auth.signOut()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func refreshUserData() async {
        guard isAuthenticated else { return }

        do {
            let userID = try await supabase.auth.session.user.id

            async let profileFetch: ProfileRow = supabase
                .from("profiles")
                .select()
                .eq("id", value: userID.uuidString)
                .single()
                .execute()
                .value

            async let speciesFetch: [FishSpeciesRow] = supabase
                .from("fish_species")
                .select()
                .order("id")
                .execute()
                .value

            async let catchesFetch: [UserCatchRow] = supabase
                .from("user_catches")
                .select()
                .eq("user_id", value: userID.uuidString)
                .execute()
                .value

            async let achievementsFetch: [AchievementRow] = supabase
                .from("achievements")
                .select()
                .order("sort_order")
                .execute()
                .value

            async let unlockedFetch: [UserAchievementRow] = supabase
                .from("user_achievements")
                .select()
                .eq("user_id", value: userID.uuidString)
                .execute()
                .value

            let (fetchedProfile, species, catches, allAchievements, unlocked) = try await (
                profileFetch,
                speciesFetch,
                catchesFetch,
                achievementsFetch,
                unlockedFetch
            )

            profile = fetchedProfile
            achievements = allAchievements
            unlockedAchievementIDs = Set(unlocked.map(\.achievementId))

            let caughtSpeciesIDs = Set(catches.map(\.speciesId))
            let catchBySpecies = Dictionary(uniqueKeysWithValues: catches.map { ($0.speciesId, $0) })

            fish = species.map { row in
                let catchRow = catchBySpecies[row.id]
                return Fish.from(
                    species: row,
                    caught: caughtSpeciesIDs.contains(row.id),
                    catchWeight: catchRow?.weightLbs
                )
            }

            recomputeStats(
                species: species,
                catches: catches,
                achievements: allAchievements,
                unlocked: unlocked
            )
            errorMessage = nil
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    private func listenForAuthChanges() async {
        for await (event, session) in supabase.auth.authStateChanges {
            switch event {
            case .initialSession, .signedIn, .tokenRefreshed, .userUpdated:
                isAuthenticated = session != nil
                if isAuthenticated {
                    await refreshUserData()
                }
            case .signedOut:
                isAuthenticated = false
                profile = nil
                fish = Fish.samples
                recomputeStats(species: [], catches: [], achievements: [], unlocked: [])
            default:
                break
            }
            isLoading = false
        }
    }

    private func recomputeStats(
        species: [FishSpeciesRow],
        catches: [UserCatchRow],
        achievements: [AchievementRow],
        unlocked: [UserAchievementRow]
    ) {
        let rareSpeciesIDs = Set(species.filter(\.isRare).map(\.id))
        let caughtRare = catches.filter { rareSpeciesIDs.contains($0.speciesId) }.count
        let totalWeight = catches.compactMap(\.weightLbs).reduce(0, +)

        stats = AnglerStats(
            caughtCount: catches.count,
            totalSpecies: max(species.count, fish.count),
            rareCaughtCount: caughtRare,
            totalWeightLbs: totalWeight,
            unlockedAchievements: unlocked.count,
            totalAchievements: achievements.count
        )
    }
}
