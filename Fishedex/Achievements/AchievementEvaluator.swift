import Foundation
import Supabase

enum AchievementEvaluator {
    private static let logics: [any AchievementLogic] = [
        FirstCatchAchievement(),
    ]

    @discardableResult
    static func evaluateAndUnlock(context: AchievementContext) async throws -> [AchievementRow] {
        var newlyUnlocked: [AchievementRow] = []

        for logic in logics {
            guard logic.isEligible(context: context) else { continue }
            guard let achievement = context.achievement(for: type(of: logic).slug) else { continue }
            guard !context.unlockedAchievementIDs.contains(achievement.id) else { continue }

            struct Insert: Encodable {
                let user_id: UUID
                let achievement_id: Int
            }

            try await supabase
                .from("user_achievements")
                .insert(Insert(user_id: context.userID, achievement_id: achievement.id))
                .execute()

            newlyUnlocked.append(achievement)
        }

        return newlyUnlocked
    }
}
