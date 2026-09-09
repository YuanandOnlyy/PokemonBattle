import Foundation

/// The player's full persisted save. Mirrors `TrainerData` in types.ts and is stored as a single
/// JSON blob in UserDefaults under `GameViewModel.storageKey`, matching the original app's single
/// `localStorage` entry.
///
/// Decoding is defensive (every field falls back to `GameData.initialTrainer`'s value when absent),
/// which replaces the manual `{ ...INITIAL_TRAINER, ...data }` merge that `loadTrainer()` performed
/// in GameContext.tsx — Swift's `decodeIfPresent` gives the same forward-compatibility without needing
/// a separate merge step.
struct TrainerData: Codable, Hashable {
    var name: String
    var level: Int
    var xp: Int
    var xpToNext: Int
    var wins: Int
    var losses: Int
    var streak: Int
    var bestStreak: Int
    var totalBattles: Int
    var totalDamageDealt: Int
    var totalCritHits: Int
    var totalSuperEffective: Int
    var favoritePokemons: [String: Int]
    var battleHistory: [BattleRecord]
    var achievements: [Achievement]
    var items: [Item]
    var settings: GameSettings
    var consecutiveDefeats: Int
    var dailyQuests: [DailyQuest]
    var dailyQuestDate: String
    /// PokeAPI ids of the last team used in battle (up to 3). Powers Title → CONTINUE.
    var lastTeamIDs: [Int]

    init(
        name: String, level: Int, xp: Int, xpToNext: Int, wins: Int, losses: Int, streak: Int,
        bestStreak: Int, totalBattles: Int, totalDamageDealt: Int, totalCritHits: Int,
        totalSuperEffective: Int, favoritePokemons: [String: Int], battleHistory: [BattleRecord],
        achievements: [Achievement], items: [Item], settings: GameSettings, consecutiveDefeats: Int,
        dailyQuests: [DailyQuest], dailyQuestDate: String, lastTeamIDs: [Int] = []
    ) {
        self.name = name
        self.level = level
        self.xp = xp
        self.xpToNext = xpToNext
        self.wins = wins
        self.losses = losses
        self.streak = streak
        self.bestStreak = bestStreak
        self.totalBattles = totalBattles
        self.totalDamageDealt = totalDamageDealt
        self.totalCritHits = totalCritHits
        self.totalSuperEffective = totalSuperEffective
        self.favoritePokemons = favoritePokemons
        self.battleHistory = battleHistory
        self.achievements = achievements
        self.items = items
        self.settings = settings
        self.consecutiveDefeats = consecutiveDefeats
        self.dailyQuests = dailyQuests
        self.dailyQuestDate = dailyQuestDate
        self.lastTeamIDs = lastTeamIDs
    }

    enum CodingKeys: String, CodingKey {
        case name, level, xp, xpToNext, wins, losses, streak, bestStreak, totalBattles,
             totalDamageDealt, totalCritHits, totalSuperEffective, favoritePokemons, battleHistory,
             achievements, items, settings, consecutiveDefeats, dailyQuests, dailyQuestDate, lastTeamIDs
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let fallback = GameData.initialTrainer

        name = try container.decodeIfPresent(String.self, forKey: .name) ?? fallback.name
        level = try container.decodeIfPresent(Int.self, forKey: .level) ?? fallback.level
        xp = try container.decodeIfPresent(Int.self, forKey: .xp) ?? fallback.xp
        xpToNext = try container.decodeIfPresent(Int.self, forKey: .xpToNext) ?? fallback.xpToNext
        wins = try container.decodeIfPresent(Int.self, forKey: .wins) ?? fallback.wins
        losses = try container.decodeIfPresent(Int.self, forKey: .losses) ?? fallback.losses
        streak = try container.decodeIfPresent(Int.self, forKey: .streak) ?? fallback.streak
        bestStreak = try container.decodeIfPresent(Int.self, forKey: .bestStreak) ?? fallback.bestStreak
        totalBattles = try container.decodeIfPresent(Int.self, forKey: .totalBattles) ?? fallback.totalBattles
        totalDamageDealt = try container.decodeIfPresent(Int.self, forKey: .totalDamageDealt) ?? fallback.totalDamageDealt
        totalCritHits = try container.decodeIfPresent(Int.self, forKey: .totalCritHits) ?? fallback.totalCritHits
        totalSuperEffective = try container.decodeIfPresent(Int.self, forKey: .totalSuperEffective) ?? fallback.totalSuperEffective
        favoritePokemons = try container.decodeIfPresent([String: Int].self, forKey: .favoritePokemons) ?? fallback.favoritePokemons
        battleHistory = try container.decodeIfPresent([BattleRecord].self, forKey: .battleHistory) ?? fallback.battleHistory
        items = try container.decodeIfPresent([Item].self, forKey: .items) ?? fallback.items
        settings = try container.decodeIfPresent(GameSettings.self, forKey: .settings) ?? fallback.settings
        consecutiveDefeats = try container.decodeIfPresent(Int.self, forKey: .consecutiveDefeats) ?? fallback.consecutiveDefeats
        dailyQuests = try container.decodeIfPresent([DailyQuest].self, forKey: .dailyQuests) ?? fallback.dailyQuests
        dailyQuestDate = try container.decodeIfPresent(String.self, forKey: .dailyQuestDate) ?? fallback.dailyQuestDate
        lastTeamIDs = try container.decodeIfPresent([Int].self, forKey: .lastTeamIDs) ?? fallback.lastTeamIDs

        // Achievement defs (name/description/target) always come from the current build's list;
        // only progress/unlocked/unlockedDate carry over from the save. Matches the `achievements.map`
        // merge in GameContext.tsx's loadTrainer().
        let saved = try container.decodeIfPresent([Achievement].self, forKey: .achievements) ?? []
        let savedByID = Dictionary(uniqueKeysWithValues: saved.map { ($0.id, $0) })
        achievements = GameData.initialAchievements.map { base in
            guard let match = savedByID[base.id] else { return base }
            var merged = base
            merged.unlocked = match.unlocked
            merged.progress = match.progress
            merged.unlockedDate = match.unlockedDate
            return merged
        }
    }
}
