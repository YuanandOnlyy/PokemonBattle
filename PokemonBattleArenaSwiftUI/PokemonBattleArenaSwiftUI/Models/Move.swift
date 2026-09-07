import Foundation

/// A single battle move. Mirrors `Move` in types.ts.
struct Move: Identifiable, Hashable {
    var name: String
    var type: PokemonType
    var power: Int
    var accuracy: Int
    var maxPP: Int
    var currentPP: Int
    var statusEffect: StatusEffect?
    var isSelfStatus: Bool = false
    var healPercent: Int?
    var category: MoveCategory

    var id: String { name }

    /// Builds a move, auto-deriving category from power/type exactly like mkMove() in gameData.ts,
    /// unless `category` is explicitly overridden by a caller (physicalMove/specialMove/statusMove).
    init(
        name: String,
        type: PokemonType,
        power: Int,
        accuracy: Int,
        maxPP: Int,
        statusEffect: StatusEffect? = nil,
        isSelfStatus: Bool = false,
        healPercent: Int? = nil,
        category: MoveCategory? = nil
    ) {
        self.name = name
        self.type = type
        self.power = power
        self.accuracy = accuracy
        self.maxPP = maxPP
        self.currentPP = maxPP
        self.statusEffect = statusEffect
        self.isSelfStatus = isSelfStatus
        self.healPercent = healPercent
        if let category {
            self.category = category
        } else if power == 0 {
            self.category = .status
        } else {
            self.category = PokemonType.physicalCategoryTypes.contains(type) ? .physical : .special
        }
    }

    static func physical(
        _ name: String, _ type: PokemonType, _ power: Int, _ accuracy: Int, _ maxPP: Int,
        statusEffect: StatusEffect? = nil, isSelfStatus: Bool = false, healPercent: Int? = nil
    ) -> Move {
        Move(name: name, type: type, power: power, accuracy: accuracy, maxPP: maxPP,
             statusEffect: statusEffect, isSelfStatus: isSelfStatus, healPercent: healPercent, category: .physical)
    }

    static func special(
        _ name: String, _ type: PokemonType, _ power: Int, _ accuracy: Int, _ maxPP: Int,
        statusEffect: StatusEffect? = nil, isSelfStatus: Bool = false, healPercent: Int? = nil
    ) -> Move {
        Move(name: name, type: type, power: power, accuracy: accuracy, maxPP: maxPP,
             statusEffect: statusEffect, isSelfStatus: isSelfStatus, healPercent: healPercent, category: .special)
    }

    static func status(
        _ name: String, _ type: PokemonType, _ accuracy: Int, _ maxPP: Int,
        statusEffect: StatusEffect? = nil, isSelfStatus: Bool = false, healPercent: Int? = nil
    ) -> Move {
        Move(name: name, type: type, power: 0, accuracy: accuracy, maxPP: maxPP,
             statusEffect: statusEffect, isSelfStatus: isSelfStatus, healPercent: healPercent, category: .status)
    }

    /// A fallback move used when a Pokemon has no PP left on anything (matches chooseEnemyMove's Struggle fallback).
    static let struggle = Move(name: "Struggle", type: .normal, power: 50, accuracy: 100, maxPP: 1, category: .physical)
}
