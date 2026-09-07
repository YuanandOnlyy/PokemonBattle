import Foundation

/// Mirrors `GameSettings` in types.ts. Persisted as part of TrainerData.
struct GameSettings: Codable, Hashable {
    enum AnimationSpeed: String, Codable, Hashable {
        case normal
        case fast
    }

    var soundEffects: Bool
    var music: Bool
    var vibration: Bool
    var animations: Bool
    var animationSpeed: AnimationSpeed
    var consoleSkin: ConsoleSkin
    var reducedMotion: Bool
    var battleAssist: Bool

    static let initial = GameSettings(
        soundEffects: true,
        music: true,
        vibration: true,
        animations: true,
        animationSpeed: .normal,
        consoleSkin: .dmg,
        reducedMotion: false,
        battleAssist: false
    )
}

/// The app's top-level screens. Mirrors `Screen` in types.ts.
enum Screen: String, Hashable {
    case title
    case teamBuilder
    case battle
    case victory
    case defeat
    case pokedex
    case achievements
    case trainerProfile
    case battleHistory
    case settings
}

/// The battle UI's local sub-phase (which action panel is showing). Mirrors `BattlePhase` in types.ts.
enum BattlePhase: String, Hashable {
    case menu
    case moveSelect
    case switchPokemon
    case bagOpen
    case animating
    case enemyTurn
    case showResult
    case battleEnd
}
