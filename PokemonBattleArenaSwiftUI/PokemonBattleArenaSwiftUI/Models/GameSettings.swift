import Foundation

/// Mirrors `GameSettings` in types.ts. Persisted as part of TrainerData.
struct GameSettings: Codable, Hashable {
    enum AnimationSpeed: String, Codable, Hashable {
        case normal
        case fast
    }

    enum BattleDifficulty: String, Codable, Hashable, CaseIterable {
        case easy
        case normal
        case hard
        case expert

        var displayName: String {
            switch self {
            case .easy:   return "Easy"
            case .normal: return "Normal"
            case .hard:   return "Hard"
            case .expert: return "Expert"
            }
        }

        var description: String {
            switch self {
            case .easy:   return "Enemy picks moves randomly"
            case .normal: return "Standard enemy AI"
            case .hard:   return "Enemy targets weaknesses"
            case .expert: return "Enemy plays optimally"
            }
        }
    }

    enum ChallengeMode: String, Codable, Hashable, CaseIterable {
        case none
        case nuzlocke
        case monotype
        case noItems
        case speedrun

        var displayName: String {
            switch self {
            case .none:     return "None"
            case .nuzlocke: return "Nuzlocke"
            case .monotype: return "Monotype"
            case .noItems:  return "No Items"
            case .speedrun: return "Speedrun"
            }
        }

        var description: String {
            switch self {
            case .none:     return "Normal play, no restrictions"
            case .nuzlocke: return "Fainted Pokemon are gone forever"
            case .monotype: return "All 3 Pokemon must share one type"
            case .noItems:  return "Bag is locked during battle"
            case .speedrun: return "Live timer — beat your best time"
            }
        }
    }

    var soundEffects: Bool
    var music: Bool
    var vibration: Bool
    var animations: Bool
    var animationSpeed: AnimationSpeed
    var consoleSkin: ConsoleSkin
    var reducedMotion: Bool
    var battleAssist: Bool
    var difficulty: BattleDifficulty
    var challengeMode: ChallengeMode
    var monoType: PokemonType?

    static let initial = GameSettings(
        soundEffects: true,
        music: true,
        vibration: true,
        animations: true,
        animationSpeed: .normal,
        consoleSkin: .dmg,
        reducedMotion: false,
        battleAssist: false,
        difficulty: .normal,
        challengeMode: .none,
        monoType: nil
    )

    // Custom Codable so old saves missing the new fields fall back to defaults.
    enum CodingKeys: String, CodingKey {
        case soundEffects, music, vibration, animations, animationSpeed, consoleSkin,
             reducedMotion, battleAssist, difficulty, challengeMode, monoType
    }

    init(
        soundEffects: Bool, music: Bool, vibration: Bool, animations: Bool,
        animationSpeed: AnimationSpeed, consoleSkin: ConsoleSkin,
        reducedMotion: Bool, battleAssist: Bool,
        difficulty: BattleDifficulty = .normal,
        challengeMode: ChallengeMode = .none,
        monoType: PokemonType? = nil
    ) {
        self.soundEffects = soundEffects
        self.music = music
        self.vibration = vibration
        self.animations = animations
        self.animationSpeed = animationSpeed
        self.consoleSkin = consoleSkin
        self.reducedMotion = reducedMotion
        self.battleAssist = battleAssist
        self.difficulty = difficulty
        self.challengeMode = challengeMode
        self.monoType = monoType
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        soundEffects  = (try? c.decodeIfPresent(Bool.self,            forKey: .soundEffects))  ?? true
        music         = (try? c.decodeIfPresent(Bool.self,            forKey: .music))         ?? true
        vibration     = (try? c.decodeIfPresent(Bool.self,            forKey: .vibration))     ?? true
        animations    = (try? c.decodeIfPresent(Bool.self,            forKey: .animations))    ?? true
        reducedMotion = (try? c.decodeIfPresent(Bool.self,            forKey: .reducedMotion)) ?? false
        battleAssist  = (try? c.decodeIfPresent(Bool.self,            forKey: .battleAssist))  ?? false
        animationSpeed = (try? c.decodeIfPresent(AnimationSpeed.self, forKey: .animationSpeed)) ?? .normal
        consoleSkin    = (try? c.decodeIfPresent(ConsoleSkin.self,    forKey: .consoleSkin))    ?? .dmg
        difficulty     = (try? c.decodeIfPresent(BattleDifficulty.self, forKey: .difficulty))  ?? .normal
        challengeMode  = (try? c.decodeIfPresent(ChallengeMode.self,  forKey: .challengeMode)) ?? .none
        monoType       = try? c.decodeIfPresent(PokemonType.self,     forKey: .monoType)
    }
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
