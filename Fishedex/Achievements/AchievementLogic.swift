import Foundation

protocol AchievementLogic {
    static var slug: String { get }
    func isEligible(context: AchievementContext) -> Bool
}

extension AchievementLogic {
    func isAlreadyUnlocked(in context: AchievementContext) -> Bool {
        context.isUnlocked(slug: Self.slug)
    }
}
