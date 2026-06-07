import Foundation

struct AchievementContext {
    let userID: UUID
    let catches: [UserCatchRow]
    let achievements: [AchievementRow]
    let unlockedAchievementIDs: Set<Int>

    func achievement(for slug: String) -> AchievementRow? {
        achievements.first { $0.slug == slug }
    }

    func isUnlocked(slug: String) -> Bool {
        guard let achievement = achievement(for: slug) else { return false }
        return unlockedAchievementIDs.contains(achievement.id)
    }
}
