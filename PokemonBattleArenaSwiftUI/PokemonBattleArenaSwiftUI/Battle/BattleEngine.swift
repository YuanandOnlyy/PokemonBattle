import Foundation

/// Pure battle math: type effectiveness, damage calculation, enemy AI move choice, and status
/// effect application. A line-for-line port of `src/utils/battle.ts`. All functions are stateless;
/// callers pass `inout BattlePokemon` where the original JS mutated a (possibly throwaway) object copy,
/// which gives identical "persist vs. discard" semantics via Swift value types.
enum BattleEngine {
    private static let typeChart: [PokemonType: [PokemonType: Double]] = [
        .fire:     [.grass: 2, .ice: 2, .bug: 2, .steel: 2, .water: 0.5, .ground: 0.5, .rock: 0.5, .fire: 0.5, .dragon: 0.5],
        .water:    [.fire: 2, .ground: 2, .rock: 2, .water: 0.5, .grass: 0.5, .dragon: 0.5],
        .grass:    [.water: 2, .ground: 2, .rock: 2, .fire: 0.5, .ice: 0.5, .poison: 0.5, .flying: 0.5, .bug: 0.5, .grass: 0.5, .dragon: 0.5, .steel: 0.5],
        .electric: [.water: 2, .flying: 2, .grass: 0.5, .electric: 0.5, .dragon: 0.5, .ground: 0],
        .ice:      [.grass: 2, .ground: 2, .flying: 2, .dragon: 2, .fire: 0.5, .water: 0.5, .ice: 0.5, .steel: 0.5],
        .fighting: [.normal: 2, .ice: 2, .rock: 2, .dark: 2, .steel: 2, .poison: 0.5, .bug: 0.5, .psychic: 0.5, .flying: 0.5, .fairy: 0.5, .ghost: 0],
        .ground:   [.fire: 2, .electric: 2, .poison: 2, .rock: 2, .steel: 2, .grass: 0.5, .bug: 0.5, .flying: 0],
        .flying:   [.grass: 2, .fighting: 2, .bug: 2, .electric: 0.5, .rock: 0.5, .steel: 0.5],
        .psychic:  [.fighting: 2, .poison: 2, .psychic: 0.5, .steel: 0.5, .dark: 0, .ghost: 0],
        .ghost:    [.psychic: 2, .ghost: 2, .normal: 0, .fighting: 0, .dark: 0.5],
        .dragon:   [.dragon: 2, .steel: 0.5, .fairy: 0],
        .dark:     [.psychic: 2, .ghost: 2, .fighting: 0.5, .dark: 0.5, .fairy: 0.5],
        .steel:    [.ice: 2, .rock: 2, .fairy: 2, .fire: 0.5, .water: 0.5, .electric: 0.5, .steel: 0.5],
        .fairy:    [.fighting: 2, .dragon: 2, .dark: 2, .fire: 0.5, .poison: 0.5, .steel: 0.5],
        .normal:   [.rock: 0.5, .steel: 0.5, .ghost: 0],
        .poison:   [.grass: 2, .fairy: 2, .poison: 0.5, .ground: 0.5, .rock: 0.5, .ghost: 0.5, .steel: 0],
        .bug:      [.grass: 2, .psychic: 2, .dark: 2, .fire: 0.5, .fighting: 0.5, .flying: 0.5, .ghost: 0.5, .steel: 0.5, .fairy: 0.5],
        .rock:     [.fire: 2, .ice: 2, .flying: 2, .bug: 2, .fighting: 0.5, .ground: 0.5, .steel: 0.5],
    ]

    static func typeEffectiveness(moveType: PokemonType, defenderTypes: [PokemonType]) -> Double {
        var multiplier = 1.0
        for defType in defenderTypes {
            if let eff = typeChart[moveType]?[defType] {
                multiplier *= eff
            }
        }
        return multiplier
    }

    private static func hasAbilityImmunity(moveType: PokemonType, defender: BattlePokemon) -> Bool {
        defender.ability == "Levitate" && moveType == .ground
    }

    private static func abilityModifier(attacker: BattlePokemon, move: Move) -> Double {
        let hpRatio = attacker.maxHP > 0 ? Double(attacker.currentHP) / Double(attacker.maxHP) : 0
        guard hpRatio <= 0.33 else { return 1 }
        if attacker.ability == "Blaze" && move.type == .fire { return 1.5 }
        if attacker.ability == "Torrent" && move.type == .water { return 1.5 }
        if attacker.ability == "Overgrow" && move.type == .grass { return 1.5 }
        return 1
    }

    static func calculateDamage(attacker: BattlePokemon, move: Move, defender: BattlePokemon) -> DamageResult {
        var rng = SystemRandomNumberGenerator()
        return calculateDamage(attacker: attacker, move: move, defender: defender, rng: &rng)
    }

    /// Testable overload — pass a seeded generator to pin crit/variance rolls.
    static func calculateDamage<G: RandomNumberGenerator>(
        attacker: BattlePokemon,
        move: Move,
        defender: BattlePokemon,
        rng: inout G
    ) -> DamageResult {
        guard move.power > 0 else {
            return DamageResult(damage: 0, isCrit: false, effectiveness: 1, message: "")
        }

        if hasAbilityImmunity(moveType: move.type, defender: defender) {
            return DamageResult(damage: 0, isCrit: false, effectiveness: 0,
                                 message: "\(defender.name)'s Levitate makes it immune!")
        }

        let level = Double(attacker.level)
        let power = Double(move.power)

        let atkStat = (move.category == .physical ? Double(attacker.atk) : Double(attacker.spAtk)) * attacker.tempAtkBoost
        let defStat = (move.category == .physical ? Double(defender.def) : Double(defender.spDef)) * defender.tempDefBoost

        let burnMod = (attacker.status == .burn && move.category == .physical) ? 0.5 : 1.0
        let abilityMod = abilityModifier(attacker: attacker, move: move)

        let baseDamage = ((2 * level / 5 + 2) * power * (atkStat / defStat) / 50 + 2).rounded(.down)

        let isCrit = Double.random(in: 0..<1, using: &rng) < 0.0625
        let critMult = isCrit ? 1.5 : 1.0

        let stab = attacker.types.contains(move.type) ? 1.5 : 1.0
        let effectiveness = typeEffectiveness(moveType: move.type, defenderTypes: defender.types)
        let randomFactor = 0.85 + Double.random(in: 0..<1, using: &rng) * 0.15

        let finalDamage = max(1, Int((baseDamage * stab * effectiveness * critMult * randomFactor * burnMod * abilityMod).rounded(.down)))

        var message = ""
        var abilityTriggered: String?

        if effectiveness == 0 {
            message = "It doesn't affect \(defender.name)..."
        } else if effectiveness >= 4 {
            message = "It's SUPER EFFECTIVE!! (4\u{00D7})"
        } else if effectiveness > 1 {
            message = "It's super effective!"
        } else if effectiveness < 1 {
            message = "It's not very effective..."
        }

        if isCrit {
            message = message.isEmpty ? "A critical hit!" : message + " A critical hit!"
        }

        if abilityMod > 1 {
            abilityTriggered = "\(attacker.name)'s \(attacker.ability ?? "ability") activated!"
        }

        return DamageResult(damage: finalDamage, isCrit: isCrit, effectiveness: effectiveness,
                             message: message, abilityTriggered: abilityTriggered)
    }

    /// Deterministic damage with fixed unit rolls (crit roll, variance roll) for unit tests.
    static func calculateDamage(
        attacker: BattlePokemon,
        move: Move,
        defender: BattlePokemon,
        critRoll: Double,
        varianceRoll: Double
    ) -> DamageResult {
        calculateDamagePinned(
            attacker: attacker, move: move, defender: defender,
            isCrit: critRoll < 0.0625,
            randomFactor: 0.85 + varianceRoll * 0.15
        )
    }

    /// Exact HP math used by tests — pins crit + variance so `previousHP - damage` is deterministic.
    static func calculateDamagePinned(
        attacker: BattlePokemon,
        move: Move,
        defender: BattlePokemon,
        isCrit: Bool,
        randomFactor: Double
    ) -> DamageResult {
        guard move.power > 0 else {
            return DamageResult(damage: 0, isCrit: false, effectiveness: 1, message: "")
        }
        if hasAbilityImmunity(moveType: move.type, defender: defender) {
            return DamageResult(damage: 0, isCrit: false, effectiveness: 0,
                                 message: "\(defender.name)'s Levitate makes it immune!")
        }
        let level = Double(attacker.level)
        let power = Double(move.power)
        let atkStat = (move.category == .physical ? Double(attacker.atk) : Double(attacker.spAtk)) * attacker.tempAtkBoost
        let defStat = (move.category == .physical ? Double(defender.def) : Double(defender.spDef)) * defender.tempDefBoost
        let burnMod = (attacker.status == .burn && move.category == .physical) ? 0.5 : 1.0
        let abilityMod = abilityModifier(attacker: attacker, move: move)
        let baseDamage = ((2 * level / 5 + 2) * power * (atkStat / defStat) / 50 + 2).rounded(.down)
        let critMult = isCrit ? 1.5 : 1.0
        let stab = attacker.types.contains(move.type) ? 1.5 : 1.0
        let effectiveness = typeEffectiveness(moveType: move.type, defenderTypes: defender.types)
        let finalDamage = max(1, Int((baseDamage * stab * effectiveness * critMult * randomFactor * burnMod * abilityMod).rounded(.down)))
        var message = ""
        if effectiveness == 0 {
            message = "It doesn't affect \(defender.name)..."
        } else if effectiveness > 1 {
            message = "It's super effective!"
        } else if effectiveness < 1 {
            message = "It's not very effective..."
        }
        if isCrit {
            message = message.isEmpty ? "A critical hit!" : message + " A critical hit!"
        }
        return DamageResult(damage: finalDamage, isCrit: isCrit, effectiveness: effectiveness, message: message)
    }

    /// Applies damage to a battle Pokemon and returns the new HP. This is the same mutation the
    /// HP bar / numeric display read from `BattleState` after an attack resolves.
    @discardableResult
    static func applyDamage(to pokemon: inout BattlePokemon, damage: Int) -> Int {
        pokemon.currentHP = max(0, pokemon.currentHP - damage)
        if pokemon.currentHP == 0 { pokemon.isFainted = true }
        return pokemon.currentHP
    }

    /// Static's 30% on-contact paralysis proc for physical moves.
    static func checkStaticTrigger(defender: BattlePokemon, move: Move) -> Bool {
        defender.ability == "Static" && move.category == .physical && Double.random(in: 0..<1) < 0.3
    }

    static func chooseEnemyMove(enemy: BattlePokemon, player: BattlePokemon) -> Move {
        let available = enemy.moves.filter { $0.currentPP > 0 }
        guard !available.isEmpty else { return .struggle }

        var best = available[0]
        var bestScore = -Double.infinity

        for move in available {
            if move.power == 0 {
                if move.statusEffect != nil, player.status == nil, !move.isSelfStatus {
                    let score = 30.0
                    if score > bestScore { bestScore = score; best = move }
                }
                continue
            }

            let eff = hasAbilityImmunity(moveType: move.type, defender: player) ? 0 : typeEffectiveness(moveType: move.type, defenderTypes: player.types)
            let stab = enemy.types.contains(move.type) ? 1.5 : 1.0
            let abilityBoost = abilityModifier(attacker: enemy, move: move)
            let score = Double(move.power) * eff * stab * (Double(move.accuracy) / 100) * abilityBoost
            let jitter = 0.9 + Double.random(in: 0..<1) * 0.2
            let finalScore = score * jitter
            if finalScore > bestScore { bestScore = finalScore; best = move }
        }

        return best
    }

    /// Applies a status condition to `pokemon` in place. Returns the message to display, or ""
    /// if nothing happened (already statused / immune / no-op). Mutates `pokemon.status` and, for
    /// sleep, `sleepTurns`/`statusTurnsLeft` — mirrors applyStatusEffect(pokemon, status) in battle.ts.
    @discardableResult
    static func applyStatusEffect(_ pokemon: inout BattlePokemon, _ status: StatusEffect) -> String {
        if pokemon.ability == "Immunity" && (status == .poison || status == .burn) {
            return "\(pokemon.name)'s Immunity prevents status!"
        }
        if pokemon.status != nil {
            return "\(pokemon.name) already has a status condition!"
        }

        pokemon.status = status
        if status == .sleep {
            pokemon.sleepTurns = 2 + Int.random(in: 0..<4)
            pokemon.statusTurnsLeft = pokemon.sleepTurns
        }

        switch status {
        case .burn: return "\(pokemon.name) was burned!"
        case .poison: return "\(pokemon.name) was poisoned!"
        case .paralysis: return "\(pokemon.name) is paralyzed!"
        case .sleep: return "\(pokemon.name) fell asleep!"
        case .freeze: return "\(pokemon.name) was frozen solid!"
        }
    }

    struct StatusDamageResult {
        var damage: Int = 0
        var message: String = ""
        var shouldSkip: Bool = false
        var cured: Bool = false
    }

    /// Resolves one status "tick" for `pokemon` (burn/poison chip damage, paralysis/sleep/freeze
    /// turn-skip roll). Mutates `pokemon` in place — mirrors processStatusDamage(pokemon) in battle.ts.
    @discardableResult
    static func processStatusDamage(_ pokemon: inout BattlePokemon) -> StatusDamageResult {
        guard let status = pokemon.status else { return StatusDamageResult() }
        var result = StatusDamageResult()

        switch status {
        case .burn:
            result.damage = max(1, Int((Double(pokemon.maxHP) * 0.125).rounded(.down)))
            result.message = "\(pokemon.name) is hurt by its burn!"
        case .poison:
            result.damage = max(1, Int((Double(pokemon.maxHP) * 0.125).rounded(.down)))
            result.message = "\(pokemon.name) is hurt by poison!"
        case .paralysis:
            if Double.random(in: 0..<1) < 0.25 {
                result.shouldSkip = true
                result.message = "\(pokemon.name) is paralyzed! It can't move!"
            }
        case .sleep:
            result.shouldSkip = true
            if pokemon.statusTurnsLeft > 0 {
                pokemon.statusTurnsLeft -= 1
                result.message = "\(pokemon.name) is fast asleep."
            }
            if pokemon.statusTurnsLeft <= 0 {
                pokemon.status = nil
                pokemon.sleepTurns = 0
                result.shouldSkip = false
                result.cured = true
                result.message = "\(pokemon.name) woke up!"
            }
        case .freeze:
            if Double.random(in: 0..<1) < 0.2 {
                pokemon.status = nil
                result.cured = true
                result.message = "\(pokemon.name) thawed out!"
            } else {
                result.shouldSkip = true
                result.message = "\(pokemon.name) is frozen solid!"
            }
        }

        return result
    }

    static func createBattlePokemon(_ pokemon: Pokemon) -> BattlePokemon {
        BattlePokemon(
            id: pokemon.id, name: pokemon.name, types: pokemon.types, baseHP: pokemon.baseHP,
            atk: pokemon.atk, def: pokemon.def, spAtk: pokemon.spAtk, spDef: pokemon.spDef, spd: pokemon.spd,
            moves: pokemon.moves.map { move in
                var m = move
                m.currentPP = m.maxPP
                return m
            },
            level: pokemon.level, xp: pokemon.xp, xpToNext: pokemon.xpToNext, ability: pokemon.ability,
            evolvesInto: pokemon.evolvesInto, evolutionOf: pokemon.evolutionOf,
            evolutionLevel: pokemon.evolutionLevel, rarity: pokemon.rarity,
            currentHP: pokemon.baseHP, maxHP: pokemon.baseHP, status: nil,
            sleepTurns: 0, statusTurnsLeft: 0, isFainted: false, tempAtkBoost: 1, tempDefBoost: 1
        )
    }

    static func generateDefeatTip(enemyName: String, enemyTypes: [PokemonType]) -> String {
        let firstType = enemyTypes.first?.rawValue.capitalized ?? "that"
        let tips = [
            "Try using moves super effective against \(enemyName)'s type.",
            "Consider bringing a Pokémon that resists \(firstType) moves.",
            "Status effects like Sleep or Paralysis can turn the tide.",
            "Stock up on potions before challenging strong opponents.",
            "A faster Pokémon can strike first and control the pace.",
        ]
        return tips[Int.random(in: 0..<tips.count)]
    }
}
