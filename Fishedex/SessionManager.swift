import Foundation
import Supabase
import Auth
import UIKit

@MainActor
final class SessionManager: ObservableObject {
    @Published private(set) var isAuthenticated = false
    @Published private(set) var isLoading = true
    @Published private(set) var profile: ProfileRow?
    @Published private(set) var fish: [Fish] = Fish.samples
    @Published private(set) var catches: [UserCatchRow] = []
    @Published private(set) var catchPhotos: [CatchPhotoRow] = []
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
    @Published private(set) var friends: [FriendSummary] = []
    @Published private(set) var incomingFriendRequests: [FriendRequest] = []
    @Published private(set) var outgoingPendingFriends: [FriendSummary] = []
    @Published var showProfile = false
    @Published var isUploadingAvatar = false
    @Published var isLoggingCatch = false
    @Published var isUpdatingCatch = false
    @Published var uploadingCatchPhotoIDs: Set<UUID> = []
    @Published var highlightedCatchID: UUID?
    @Published var errorMessage: String? // surfaced on auth + profile screens

    private var authListenerTask: Task<Void, Never>?
    private var rareSpeciesIDs: Set<Int> = []

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
            catchPhotos = []
            recomputeStats(species: [], catches: [], achievements: [], unlocked: [])
        }
    }

    func signIn(email: String, password: String) async throws {
        errorMessage = nil
        try await supabase.auth.signIn(email: email, password: password)
    }

    func signUp(email: String, password: String, displayName: String) async throws {
        errorMessage = nil
        _ = try await supabase.auth.signUp(
            email: email,
            password: password,
            data: ["display_name": .string(displayName)]
        )
        try? await supabase.auth.signOut()
    }

    func logCatch(_ input: LogCatchInput) async throws -> UUID {
        guard isAuthenticated else { throw SessionError.notAuthenticated }

        isLoggingCatch = true
        defer { isLoggingCatch = false }

        let userID = try await supabase.auth.session.user.id
        let catchID = UUID()
        var photoURL: String?
        var initialPhotoID: UUID?

        if let photoData = input.photoData {
            let photoID = UUID()
            let uploaded = try await uploadCatchPhotoFile(
                photoData,
                userId: userID,
                catchId: catchID,
                photoId: photoID
            )
            photoURL = uploaded.photoURL
            initialPhotoID = photoID

            if let url = URL(string: uploaded.photoURL) {
                await ImageCache.shared.store(data: photoData, for: url)
            }
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
            let bait: String?
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
            bait: input.bait?
                .trimmingCharacters(in: .whitespacesAndNewlines)
                .nilIfEmpty,
            photo_url: photoURL,
            caught_at: input.caughtAt
        )

        try await supabase
            .from("user_catches")
            .insert(row)
            .execute()

        if let photoURL, let initialPhotoID {
            try await insertCatchPhotoRecord(
                id: initialPhotoID,
                catchId: catchID,
                userId: userID,
                photoURL: photoURL,
                storagePath: UserStorage.fishPhotoPath(
                    userId: userID,
                    catchId: catchID,
                    photoId: initialPhotoID
                ),
                sortOrder: 0
            )
        }

        await refreshUserData()
        highlightedCatchID = catchID
        errorMessage = nil
        return catchID
    }

    func updateCatch(id: UUID, input: UpdateCatchInput) async throws {
        guard isAuthenticated else { throw SessionError.notAuthenticated }

        isUpdatingCatch = true
        defer { isUpdatingCatch = false }

        struct CatchUpdate: Encodable {
            let custom_name: String?
            let weight_kg: Double?
            let length_cm: Double?
            let location_name: String?
            let bait: String?
            let notes: String?
            let caught_at: Date?
        }

        let update = CatchUpdate(
            custom_name: input.customName?
                .trimmingCharacters(in: .whitespacesAndNewlines)
                .nilIfEmpty,
            weight_kg: input.weightKg,
            length_cm: input.lengthCm,
            location_name: input.locationName?
                .trimmingCharacters(in: .whitespacesAndNewlines)
                .nilIfEmpty,
            bait: input.bait?
                .trimmingCharacters(in: .whitespacesAndNewlines)
                .nilIfEmpty,
            notes: input.notes?
                .trimmingCharacters(in: .whitespacesAndNewlines)
                .nilIfEmpty,
            caught_at: input.caughtAt
        )

        try await supabase
            .from("user_catches")
            .update(update)
            .eq("id", value: id.uuidString)
            .execute()

        await refreshUserData()
        errorMessage = nil
    }

    func fish(for catchRow: UserCatchRow) -> Fish? {
        guard let speciesId = catchRow.speciesId else { return nil }
        return fish.first { $0.id == speciesId }
    }

    func catchTitle(for catchRow: UserCatchRow) -> String {
        if let name = catchRow.customName?.trimmingCharacters(in: .whitespacesAndNewlines),
           !name.isEmpty {
            return name
        }
        return fish(for: catchRow)?.name ?? "Unnamed catch"
    }

    func catchSpeciesName(for catchRow: UserCatchRow) -> String {
        fish(for: catchRow)?.name ?? "Unknown species"
    }

    func clearHighlightedCatch() {
        highlightedCatchID = nil
    }

    func photos(for catchId: UUID) -> [CatchPhotoRow] {
        catchPhotos
            .filter { $0.catchId == catchId }
            .sorted { lhs, rhs in
                if lhs.sortOrder != rhs.sortOrder { return lhs.sortOrder < rhs.sortOrder }
                return lhs.createdAt < rhs.createdAt
            }
    }

    func photos(forSpecies speciesId: Int) -> [CatchPhotoRow] {
        let catchIDs = Set(catches.filter { $0.speciesId == speciesId }.map(\.id))
        return catchPhotos
            .filter { catchIDs.contains($0.catchId) }
            .sorted { $0.createdAt > $1.createdAt }
    }

    func primaryPhotoUrl(for catchRow: UserCatchRow) -> String? {
        photos(for: catchRow.id).first?.photoUrl ?? catchRow.photoUrl
    }

    func uploadCatchPhoto(catchId: UUID, imageData: Data) async throws {
        guard isAuthenticated else { throw SessionError.notAuthenticated }
        guard let photoData = ImageCompressor.compressedJPEGData(from: imageData) else {
            throw SessionError.invalidImage
        }

        uploadingCatchPhotoIDs.insert(catchId)
        defer { uploadingCatchPhotoIDs.remove(catchId) }

        let userID = try await supabase.auth.session.user.id
        let photoID = UUID()
        let sortOrder = photos(for: catchId).count

        let uploaded = try await uploadCatchPhotoFile(
            photoData,
            userId: userID,
            catchId: catchId,
            photoId: photoID
        )

        try await insertCatchPhotoRecord(
            id: photoID,
            catchId: catchId,
            userId: userID,
            photoURL: uploaded.photoURL,
            storagePath: uploaded.storagePath,
            sortOrder: sortOrder
        )

        if let url = URL(string: uploaded.photoURL) {
            await ImageCache.shared.store(data: photoData, for: url)
        }

        if photos(for: catchId).isEmpty {
            struct PhotoURLUpdate: Encodable {
                let photo_url: String
            }

            try await supabase
                .from("user_catches")
                .update(PhotoURLUpdate(photo_url: uploaded.photoURL))
                .eq("id", value: catchId.uuidString)
                .execute()
        }

        await refreshUserData()
        errorMessage = nil
    }

    private func uploadCatchPhotoFile(
        _ photoData: Data,
        userId: UUID,
        catchId: UUID,
        photoId: UUID
    ) async throws -> (photoURL: String, storagePath: String) {
        let path = UserStorage.fishPhotoPath(userId: userId, catchId: catchId, photoId: photoId)
        let publicURL = try await UserStorage.uploadImage(
            bucket: UserStorage.Bucket.catches,
            path: path,
            data: photoData,
            contentType: "image/jpeg"
        )
        return (publicURL.absoluteString, path)
    }

    private func insertCatchPhotoRecord(
        id: UUID,
        catchId: UUID,
        userId: UUID,
        photoURL: String,
        storagePath: String,
        sortOrder: Int
    ) async throws {
        struct CatchPhotoInsert: Encodable {
            let id: UUID
            let catch_id: UUID
            let user_id: UUID
            let photo_url: String
            let storage_path: String
            let sort_order: Int
        }

        try await supabase
            .from("catch_photos")
            .insert(
                CatchPhotoInsert(
                    id: id,
                    catch_id: catchId,
                    user_id: userId,
                    photo_url: photoURL,
                    storage_path: storagePath,
                    sort_order: sortOrder
                )
            )
            .execute()
    }

    private func resolveSpeciesId(for name: String?) -> Int? {
        guard let name, !name.isEmpty else { return nil }
        let normalized = name.lowercased()
        return fish.first { $0.name.lowercased() == normalized }?.id
    }

    var isAiFishDetectionEnabled: Bool {
        profile?.aiFishDetectionEnabled ?? false
    }

    func classifyFish(image: UIImage) async throws -> FishDetectionResult {
        guard isAuthenticated else { throw FishIdentificationError.notAuthenticated }
        guard isAiFishDetectionEnabled else { throw FishIdentificationError.notEnabled }
        return try await FishIdentificationService.classify(image: image)
    }

    func uploadAvatar(imageData: Data, contentType: String = "image/jpeg") async {
        guard isAuthenticated else { return }

        isUploadingAvatar = true
        defer { isUploadingAvatar = false }

        do {
            let userID = try await supabase.auth.session.user.id
            guard let photoData = ImageCompressor.compressedJPEGData(from: imageData) else {
                errorMessage = "Could not process image."
                return
            }
            let path = UserStorage.profileAvatarPath(userId: userID, fileExtension: "jpg")

            if let oldURLString = profile?.avatarUrl, let oldURL = URL(string: oldURLString) {
                await ImageCache.shared.remove(for: oldURL)
            }

            let publicURL = try await UserStorage.uploadImage(
                bucket: UserStorage.Bucket.avatars,
                path: path,
                data: photoData,
                contentType: "image/jpeg"
            )

            await ImageCache.shared.store(data: photoData, for: publicURL)

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

            async let catchPhotosFetch: [CatchPhotoRow] = supabase
                .from("catch_photos")
                .select()
                .eq("user_id", value: userID.uuidString)
                .order("sort_order")
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

            let (fetchedProfile, species, userCatches, userCatchPhotos, allAchievements, unlocked) = try await (
                profileFetch,
                speciesFetch,
                catchesFetch,
                catchPhotosFetch,
                achievementsFetch,
                unlockedFetch
            )

            profile = fetchedProfile
            achievements = allAchievements
            unlockedAchievementIDs = Set(unlocked.map(\.achievementId))

            rareSpeciesIDs = Set(species.filter(\.isRare).map(\.id))
            let caughtSpeciesIDs = Set(userCatches.compactMap(\.speciesId))

            fish = species.map { row in
                let speciesCatches = userCatches.filter { $0.speciesId == row.id }
                return Fish.from(
                    species: row,
                    caught: caughtSpeciesIDs.contains(row.id),
                    catchWeight: speciesCatches.count == 1 ? speciesCatches[0].weightKg : nil
                )
            }
            catches = userCatches
            catchPhotos = userCatchPhotos

            let achievementContext = AchievementContext(
                userID: userID,
                catches: userCatches,
                achievements: allAchievements,
                unlockedAchievementIDs: unlockedAchievementIDs
            )
            let newlyUnlocked = try await AchievementEvaluator.evaluateAndUnlock(
                context: achievementContext
            )
            if !newlyUnlocked.isEmpty {
                unlockedAchievementIDs.formUnion(newlyUnlocked.map(\.id))
            }

            recomputeStats(
                species: species,
                catches: userCatches,
                achievements: allAchievements,
                unlocked: unlocked + newlyUnlocked.map {
                    UserAchievementRow(
                        id: UUID(),
                        userId: userID,
                        achievementId: $0.id,
                        unlockedAt: Date()
                    )
                }
            )

            await refreshFriends()
            errorMessage = nil
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func searchUserByEmail(_ email: String) async throws -> ProfileRow? {
        guard isAuthenticated else { throw SessionError.notAuthenticated }

        let trimmed = email.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        guard !trimmed.isEmpty else { return nil }

        let results: [ProfileRow] = try await supabase
            .rpc("find_user_by_email", params: ["search_email": trimmed])
            .execute()
            .value

        return results.first
    }

    func friendshipRelation(with profileId: UUID) -> FriendshipRelation {
        if friends.contains(where: { $0.profile.id == profileId }) {
            return .accepted
        }
        if let request = incomingFriendRequests.first(where: { $0.requester.id == profileId }) {
            return .incomingPending(friendshipId: request.friendshipId)
        }
        if let pending = outgoingPendingFriends.first(where: { $0.profile.id == profileId }) {
            return .outgoingPending(friendshipId: pending.friendshipId)
        }
        return .none
    }

    func addFriend(profile: ProfileRow) async throws {
        guard isAuthenticated else { throw SessionError.notAuthenticated }

        let userID = try await supabase.auth.session.user.id
        guard profile.id != userID else { throw SessionError.cannotAddSelf }

        switch friendshipRelation(with: profile.id) {
        case .accepted:
            throw SessionError.alreadyFriends
        case .outgoingPending:
            throw SessionError.requestAlreadySent
        case .incomingPending(let friendshipId):
            try await acceptFriendRequest(friendshipId: friendshipId)
            return
        case .none:
            break
        }

        struct FriendshipInsert: Encodable {
            let user_id: UUID
            let friend_id: UUID
            let status: String
        }

        try await supabase
            .from("friendships")
            .insert(
                FriendshipInsert(
                    user_id: userID,
                    friend_id: profile.id,
                    status: FriendshipStatus.pending.rawValue
                )
            )
            .execute()

        await refreshFriends()
        errorMessage = nil
    }

    func acceptFriendRequest(friendshipId: UUID) async throws {
        guard isAuthenticated else { throw SessionError.notAuthenticated }

        let userID = try await supabase.auth.session.user.id

        struct StatusUpdate: Encodable {
            let status: String
        }

        try await supabase
            .from("friendships")
            .update(StatusUpdate(status: FriendshipStatus.accepted.rawValue))
            .eq("id", value: friendshipId.uuidString)
            .eq("friend_id", value: userID.uuidString)
            .eq("status", value: FriendshipStatus.pending.rawValue)
            .execute()

        await refreshFriends()
        errorMessage = nil
    }

    func declineFriendRequest(friendshipId: UUID) async throws {
        guard isAuthenticated else { throw SessionError.notAuthenticated }

        let userID = try await supabase.auth.session.user.id

        try await supabase
            .from("friendships")
            .delete()
            .eq("id", value: friendshipId.uuidString)
            .eq("friend_id", value: userID.uuidString)
            .eq("status", value: FriendshipStatus.pending.rawValue)
            .execute()

        await refreshFriends()
        errorMessage = nil
    }

    func fetchFriendProfile(id: UUID) async throws -> ProfileRow {
        try await supabase
            .from("profiles")
            .select()
            .eq("id", value: id.uuidString)
            .single()
            .execute()
            .value
    }

    func fetchFriendCatches(userId: UUID) async throws -> [UserCatchRow] {
        try await supabase
            .from("user_catches")
            .select()
            .eq("user_id", value: userId.uuidString)
            .execute()
            .value
    }

    func fetchFriendTopCatches(userId: UUID, limit: Int = 6) async throws -> [UserCatchRow] {
        let catches = try await fetchFriendCatches(userId: userId)
        return catches
            .sorted { lhs, rhs in
                let lhsWeight = lhs.weightKg ?? 0
                let rhsWeight = rhs.weightKg ?? 0
                if lhsWeight != rhsWeight { return lhsWeight > rhsWeight }
                return lhs.caughtAt > rhs.caughtAt
            }
            .prefix(limit)
            .map { $0 }
    }

    func friendStats(for catches: [UserCatchRow], totalSpecies: Int) -> AnglerStats {
        let caughtSpeciesIDs = Set(catches.compactMap(\.speciesId))
        let caughtRare = caughtSpeciesIDs.filter { rareSpeciesIDs.contains($0) }.count
        let totalWeight = catches.compactMap(\.weightKg).reduce(0, +)

        return AnglerStats(
            caughtCount: caughtSpeciesIDs.count,
            totalSpecies: totalSpecies,
            rareCaughtCount: caughtRare,
            totalWeightKg: totalWeight,
            unlockedAchievements: 0,
            totalAchievements: 0
        )
    }

    func fishName(for catchRow: UserCatchRow) -> String {
        if let name = catchRow.customName?.trimmingCharacters(in: .whitespacesAndNewlines),
           !name.isEmpty {
            return name
        }
        if let speciesId = catchRow.speciesId,
           let species = fish.first(where: { $0.id == speciesId }) {
            return species.name
        }
        return "Unknown fish"
    }

    func fishImageName(for catchRow: UserCatchRow) -> String {
        if let speciesId = catchRow.speciesId,
           let species = fish.first(where: { $0.id == speciesId }) {
            return species.imageName
        }
        return "MysteryFish"
    }

    private func refreshFriends() async {
        guard isAuthenticated else {
            friends = []
            incomingFriendRequests = []
            outgoingPendingFriends = []
            return
        }

        do {
            let userID = try await supabase.auth.session.user.id

            async let sentFetch: [FriendshipRow] = supabase
                .from("friendships")
                .select()
                .eq("user_id", value: userID.uuidString)
                .order("created_at", ascending: false)
                .execute()
                .value

            async let receivedFetch: [FriendshipRow] = supabase
                .from("friendships")
                .select()
                .eq("friend_id", value: userID.uuidString)
                .order("created_at", ascending: false)
                .execute()
                .value

            let (sent, received) = try await (sentFetch, receivedFetch)
            let friendships = sent + received

            guard !friendships.isEmpty else {
                friends = []
                incomingFriendRequests = []
                outgoingPendingFriends = []
                return
            }

            let profileIDs = Set(
                friendships.flatMap { friendship in
                    [friendship.userId, friendship.friendId]
                }
            )
            .subtracting([userID])

            let profiles: [ProfileRow] = try await supabase
                .from("profiles")
                .select()
                .in("id", values: profileIDs.map(\.uuidString))
                .execute()
                .value

            let profileByID = Dictionary(uniqueKeysWithValues: profiles.map { ($0.id, $0) })

            var accepted: [FriendSummary] = []
            var incoming: [FriendRequest] = []
            var outgoing: [FriendSummary] = []

            for friendship in friendships {
                switch friendship.status {
                case .accepted:
                    let otherID = friendship.userId == userID ? friendship.friendId : friendship.userId
                    guard let profile = profileByID[otherID] else { continue }
                    accepted.append(
                        FriendSummary(
                            friendshipId: friendship.id,
                            profile: profile,
                            status: .accepted
                        )
                    )
                case .pending:
                    if friendship.friendId == userID {
                        guard let requester = profileByID[friendship.userId] else { continue }
                        incoming.append(
                            FriendRequest(friendshipId: friendship.id, requester: requester)
                        )
                    } else {
                        guard let recipient = profileByID[friendship.friendId] else { continue }
                        outgoing.append(
                            FriendSummary(
                                friendshipId: friendship.id,
                                profile: recipient,
                                status: .pending
                            )
                        )
                    }
                }
            }

            friends = accepted
            incomingFriendRequests = incoming
            outgoingPendingFriends = outgoing
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
                catchPhotos = []
                friends = []
                incomingFriendRequests = []
                outgoingPendingFriends = []
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
        let caughtSpeciesIDs = Set(catches.compactMap(\.speciesId))
        let rareSpeciesIDs = Set(species.filter(\.isRare).map(\.id))
        let caughtRare = caughtSpeciesIDs.filter { rareSpeciesIDs.contains($0) }.count
        let totalWeight = catches.compactMap(\.weightKg).reduce(0, +)

        stats = AnglerStats(
            caughtCount: caughtSpeciesIDs.count,
            totalSpecies: max(species.count, fish.count),
            rareCaughtCount: caughtRare,
            totalWeightKg: totalWeight,
            unlockedAchievements: unlocked.count,
            totalAchievements: achievements.count
        )
    }
}

enum SessionError: Error, LocalizedError {
    case notAuthenticated
    case invalidImage
    case cannotAddSelf
    case alreadyFriends
    case requestAlreadySent

    var errorDescription: String? {
        switch self {
        case .notAuthenticated: return "You must be signed in."
        case .invalidImage: return "Could not process image."
        case .cannotAddSelf: return "You can't add yourself as a friend."
        case .alreadyFriends: return "This angler is already on your friends list."
        case .requestAlreadySent: return "Friend request already sent."
        }
    }
}

private extension String {
    var nilIfEmpty: String? {
        isEmpty ? nil : self
    }
}

