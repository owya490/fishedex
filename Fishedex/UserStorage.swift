import Foundation
import Supabase

/// Supabase Storage layout per user:
/// - `catches` bucket → `{userId}/fish/{catchId}/{photoId}.jpg`
/// - `avatars` bucket → `{userId}/profile/avatar.jpg`
enum UserStorage {
    enum Bucket {
        static let catches = "catches"
        static let avatars = "avatars"
    }

    enum Folder {
        static let fish = "fish"
        static let profile = "profile"
    }

    static func fishPhotoPath(userId: UUID, catchId: UUID, photoId: UUID) -> String {
        "\(userId.storageFolder)/\(Folder.fish)/\(catchId.uuidString.lowercased())/\(photoId.uuidString.lowercased()).jpg"
    }

    static func profileAvatarPath(userId: UUID, fileExtension: String) -> String {
        "\(userId.storageFolder)/\(Folder.profile)/avatar.\(fileExtension)"
    }

    static func uploadImage(
        bucket: String,
        path: String,
        data: Data,
        contentType: String
    ) async throws -> URL {
        try await supabase.storage
            .from(bucket)
            .upload(
                path,
                data: data,
                options: FileOptions(contentType: contentType, upsert: true)
            )

        return try supabase.storage
            .from(bucket)
            .getPublicURL(path: path)
    }
}

extension UUID {
    /// Supabase storage RLS compares folder names to `auth.uid()::text` (lowercase).
    var storageFolder: String {
        uuidString.lowercased()
    }
}
