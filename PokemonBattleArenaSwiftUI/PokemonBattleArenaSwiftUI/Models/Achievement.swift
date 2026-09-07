import Foundation

/// Mirrors `Achievement` in types.ts. Persisted as part of TrainerData.
struct Achievement: Identifiable, Codable, Hashable {
    var id: String
    var name: String
    var description: String
    var unlockCondition: String
    var unlocked: Bool
    var progress: Int
    var target: Int
    var unlockedDate: String? = nil
}

/// Mirrors `BattleRecord` in types.ts. Persisted as part of TrainerData.battleHistory.
struct BattleRecord: Identifiable, Codable, Hashable {
    enum Result: String, Codable, Hashable {
        case victory
        case defeat
    }

    var id: String
    var date: String
    var result: Result
    var playerTeam: [String]
    var enemyPokemon: String
    var xpGained: Int
    var duration: Int
    var damageDealt: Int
    var critHits: Int
}

/// Mirrors `DailyQuest` in types.ts. Persisted as part of TrainerData.
struct DailyQuest: Identifiable, Codable, Hashable {
    enum QuestType: String, Codable, Hashable {
        case winBattle = "win_battle"
        case landCrits = "land_crits"
        case useItem = "use_item"
        case superEffective = "super_effective"
        case surviveLowHP = "survive_low_hp"
    }

    var id: String
    var description: String
    var type: QuestType
    var target: Int
    var progress: Int
    var completed: Bool
    var rewardXP: Int
}
