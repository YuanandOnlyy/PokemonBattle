import Foundation

/// Stats and metadata for a Mega Evolution form. Stored on `Pokemon.megaData`; copied into
/// `BattlePokemon.megaData` at battle start so the engine can read it without touching GameData.
struct MegaEvolution: Hashable {
    var megaName: String
    var types: [PokemonType]
    var atk: Int
    var def: Int
    var spAtk: Int
    var spDef: Int
    var spd: Int
    var ability: String?
}

/// A roster definition (base stats, moves, evolution info). Mirrors `Pokemon` in types.ts.
/// Not persisted directly — battles work off a `BattlePokemon` snapshot instead.
struct Pokemon: Identifiable, Hashable {
    var id: Int
    var name: String
    var types: [PokemonType]
    var baseHP: Int
    var atk: Int
    var def: Int
    var spAtk: Int
    var spDef: Int
    var spd: Int
    var moves: [Move]
    var level: Int
    var xp: Int
    var xpToNext: Int
    var ability: String? = nil
    var evolvesInto: Int? = nil
    var evolutionOf: Int? = nil
    var evolutionLevel: Int? = nil
    var rarity: Rarity? = nil
    var megaData: MegaEvolution? = nil

    static func == (lhs: Pokemon, rhs: Pokemon) -> Bool { lhs.id == rhs.id }
    func hash(into hasher: inout Hasher) { hasher.combine(id) }
}

/// A live, in-battle copy of a Pokemon (current HP, status, PP, temp stat boosts).
/// Mirrors `BattlePokemon` in types.ts, flattened rather than "extends Pokemon" since Swift
/// structs don't support interface inheritance.
struct BattlePokemon: Identifiable, Hashable {
    var id: Int
    var name: String
    var types: [PokemonType]
    var baseHP: Int
    var atk: Int
    var def: Int
    var spAtk: Int
    var spDef: Int
    var spd: Int
    var moves: [Move]
    var level: Int
    var xp: Int
    var xpToNext: Int
    var ability: String?
    var evolvesInto: Int?
    var evolutionOf: Int?
    var evolutionLevel: Int?
    var rarity: Rarity?
    var megaData: MegaEvolution?
    var isMegaEvolved: Bool

    var currentHP: Int
    var maxHP: Int
    var status: StatusEffect?
    var sleepTurns: Int
    var statusTurnsLeft: Int
    var isFainted: Bool
    var tempAtkBoost: Double
    var tempDefBoost: Double

    // Synthesized Equatable/Hashable (all fields). An earlier id-only `==` made SwiftUI treat
    // HP/status mutations as "unchanged," so HPBarView never saw `current` change and attack
    // impact state on the panels looked frozen even though battle math had applied damage.
}
