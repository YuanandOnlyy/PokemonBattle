import Foundation

/// Result of a single damage calculation. Mirrors `DamageResult` in types.ts.
struct DamageResult: Hashable {
    var damage: Int
    var isCrit: Bool
    var effectiveness: Double
    var message: String
    var abilityTriggered: String? = nil
}

/// A transient floating "-12" damage number over a sprite. Mirrors the inline type
/// used for `BattleState.floatingDamage` in types.ts.
struct FloatingDamage: Identifiable, Hashable {
    var value: String
    var id: Int
    /// `true` = float above the enemy sprite; `false` = above the player sprite.
    var onEnemy: Bool
}

/// One player Pokemon's XP award at the end of a battle. `xpGained` is a plain
/// `Record<string, number>` (insertion-ordered) in the original TS — an ordered array is used
/// here instead of `[String: Int]` so team order survives for display on Victory/Defeat.
struct XPEntry: Identifiable, Hashable {
    var name: String
    var amount: Int
    var id: String { name }
}

/// The full live battle state. Ephemeral (never persisted) — mirrors `BattleState` in types.ts,
/// with the `messages` / `battleLog` fields dropped since nothing in the original UI reads them
/// (only `currentMessage` / `displayedMessage` are ever rendered).
struct BattleState {
    var playerTeam: [BattlePokemon]
    var enemyTeam: [BattlePokemon]
    var activePlayerIndex: Int
    var activeEnemyIndex: Int
    var phase: BattlePhase
    var currentMessage: String
    var displayedMessage: String
    var turn: Int
    var startTime: Date
    var totalDamageDealt: Int
    var totalCritHits: Int
    var totalSuperEffective: Int
    var itemsUsed: Int
    var damageByPokemon: [String: Int]
    var isPlayerShaking: Bool
    var isEnemyShaking: Bool
    var isPlayerFlashing: Bool
    var isEnemyFlashing: Bool
    var isScreenShaking: Bool
    /// Player sprite lunges forward during an attack.
    var isPlayerLunging: Bool
    /// Enemy sprite lunges forward during an attack.
    var isEnemyLunging: Bool
    var floatingDamage: FloatingDamage?
    var xpGained: [XPEntry]
    var levelUps: [String]
    /// True once a Mega Evolution has been used this battle (one per battle, player-side only).
    var megaUsedThisBattle: Bool
}

/// Summary shown on the Victory/Defeat screens. Mirrors the inline `BattleResult` interface
/// declared at the top of GameContext.tsx.
struct BattleResult {
    var won: Bool
    var xpGained: [XPEntry]
    var levelUps: [String]
    var enemyDefeated: String?
    var mvpPokemon: String?
    var tip: String?
}
