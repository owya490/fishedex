import Foundation

struct FirstCatchAchievement: AchievementLogic {
    static let slug = "first_catch"

    func isEligible(context: AchievementContext) -> Bool {
        guard !isAlreadyUnlocked(in: context) else { return false }
        return !context.catches.isEmpty
    }
}
