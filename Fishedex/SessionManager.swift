import Foundation
import Supabase
import Auth

@MainActor
final class SessionManager: ObservableObject {
    @Published private(set) var isAuthenticated = false
    @Published private(set) var isLoading = true
    @Published private(set) var profile: ProfileRow?
    @Published private(set) var fish: [Fish] = Fish.samples
    @Published private(set) var catches: [UserCatchRow] = []
    @Published private(set) var stats = AnglerStats(
        caughtCount: 0,
        totalSpecies: Fish.samples.count,
        rareCaughtCount: 0,
        totalWeightKg: 0,
        unlockedAchievements: 0,
        totalAchievements: 0
    )
    @Published private(set) var achievements: [AchievementRow] = []
    @Published private(set) var unlockedAchievementIDs: Set<Int> = []
    @Published var showProfile = false
    @Published var isUploadingAvatar = false
    @Published var isLoggingCatch = false
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
            catches = []
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

    func logCatch(_ input: LogCatchInput) async throws {
        guard isAuthenticated else { return }

        isLoggingCatch = true
        defer { isLoggingCatch = false }

        let userID = try await supabase.auth.session.user.id
        let catchID = UUID()
        var photoURL: String?

        if let photoData = input.photoData {
            let path = "\(userID.uuidString)/\(catchID.uuidString).jpg"
            try await supabase.storage
                .from("catches")
                .upload(
                    path,
                    data: photoData,
                    options: FileOptions(contentType: "image/jpeg", upsert: true)
                )

            photoURL = try supabase.storage
                .from("catches")
                .getPublicURL(path: path)
                .absoluteString
        }

        let trimmedName = input.fishName?
            .trimmingCharacters(in: .whitespacesAndNewlines)
        let speciesID = input.speciesId ?? resolveSpeciesId(for: trimmedName)

        struct CatchInsert: Encodable {
            let id: UUID
            let user_id: UUID
            let species_id: Int?
            let custom_name: String?
            let weight_kg: Double?
            let length_cm: Double?
            let location_name: String?
            let latitude: Double?
            let longitude: Double?
            let notes: String?
            let photo_url: String?
            let caught_at: Date
        }

        let row = CatchInsert(
            id: catchID,
            user_id: userID,
            species_id: speciesID,
            custom_name: trimmedName?.isEmpty == false ? trimmedName : nil,
            weight_kg: input.weightKg,
            length_cm: input.lengthCm,
            location_name: input.locationName?
                .trimmingCharacters(in: .whitespacesAndNewlines)
                .nilIfEmpty,
            latitude: input.latitude,
            longitude: input.longitude,
            notes: input.notes?
                .trimmingCharacters(in: .whitespacesAndNewlines)
                .nilIfEmpty,
            photo_url: photoURL,
            caught_at: input.caughtAt
        )

        try await supabase
            .from("user_catches")
            .insert(row)
            .execute()

        await refreshUserData()
        errorMessage = nil
    }

    private func resolveSpeciesId(for name: String?) -> Int? {
        guard let name, !name.isEmpty else { return nil }
        let normalized = name.lowercased()
        return fish.first { $0.name.lowercased() == normalized }?.id
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

            let (fetchedProfile, species, userCatches, allAchievements, unlocked) = try await (
                profileFetch,
                speciesFetch,
                catchesFetch,
                achievementsFetch,
                unlockedFetch
            )

            profile = fetchedProfile
            achievements = allAchievements
            unlockedAchievementIDs = Set(unlocked.map(\.achievementId))

            let caughtSpeciesIDs = Set(userCatches.compactMap(\.speciesId))
            let catchBySpecies = Dictionary(
                uniqueKeysWithValues: userCatches.compactMap { catchRow in
                    catchRow.speciesId.map { ($0, catchRow) }
                }
            )

            fish = species.map { row in
                let catchRow = catchBySpecies[row.id]
                return Fish.from(
                    species: row,
                    caught: caughtSpeciesIDs.contains(row.id),
                    catchWeight: catchRow?.weightKg
                )
            }
            catches = userCatches

            recomputeStats(
                species: species,
                catches: userCatches,
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
                catches = []
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
        let caughtRare = catches.filter { catchRow in
            guard let speciesId = catchRow.speciesId else { return false }
            return rareSpeciesIDs.contains(speciesId)
        }.count
        let totalWeight = catches.compactMap(\.weightKg).reduce(0, +)

        stats = AnglerStats(
            caughtCount: catches.count,
            totalSpecies: max(species.count, fish.count),
            rareCaughtCount: caughtRare,
            totalWeightKg: totalWeight,
            unlockedAchievements: unlocked.count,
            totalAchievements: achievements.count
        )
    }
}

private extension String {
    var nilIfEmpty: String? {
        isEmpty ? nil : self
    }
}
