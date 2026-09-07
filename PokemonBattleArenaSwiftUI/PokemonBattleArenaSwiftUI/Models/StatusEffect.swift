import Foundation

/// A volatile battle status condition. `nil` means "no status" (matches `StatusEffect | null` in types.ts).
enum StatusEffect: String, Codable, Hashable {
    case burn
    case poison
    case paralysis
    case sleep
    case freeze

    /// 3-letter abbreviation shown on StatusBadge (matches STATUS_ABBREV in ui.tsx).
    var abbreviation: String {
        switch self {
        case .burn: return "BRN"
        case .poison: return "PSN"
        case .paralysis: return "PAR"
        case .sleep: return "SLP"
        case .freeze: return "FRZ"
        }
    }
}

/// Whether a move is a physical hit, a special hit, or a non-damaging status move.
enum MoveCategory: String, Codable, Hashable {
    case physical
    case special
    case status
}

/// Rarity tier shown in the Pokedex / team builder (informational only).
enum Rarity: String, Codable, Hashable {
    case common = "Common"
    case uncommon = "Uncommon"
    case rare = "Rare"
    case legendary = "Legendary"
}
