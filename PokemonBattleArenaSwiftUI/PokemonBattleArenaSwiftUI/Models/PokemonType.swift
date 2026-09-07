import Foundation
import SwiftUI

/// Elemental type of a Pokemon or move. Mirrors `PokemonType` from the original app's types.ts.
enum PokemonType: String, CaseIterable, Codable, Hashable {
    case normal = "NORMAL"
    case fire = "FIRE"
    case water = "WATER"
    case grass = "GRASS"
    case electric = "ELECTRIC"
    case ice = "ICE"
    case fighting = "FIGHTING"
    case poison = "POISON"
    case ground = "GROUND"
    case flying = "FLYING"
    case psychic = "PSYCHIC"
    case bug = "BUG"
    case rock = "ROCK"
    case ghost = "GHOST"
    case dragon = "DRAGON"
    case dark = "DARK"
    case steel = "STEEL"
    case fairy = "FAIRY"

    /// 3-letter abbreviation shown on TypeBadge (matches TYPE_ABBREV in ui.tsx).
    var abbreviation: String {
        switch self {
        case .normal: return "NRM"
        case .fire: return "FIR"
        case .water: return "WAT"
        case .grass: return "GRS"
        case .electric: return "ELC"
        case .ice: return "ICE"
        case .fighting: return "FGT"
        case .poison: return "PSN"
        case .ground: return "GRD"
        case .flying: return "FLY"
        case .psychic: return "PSY"
        case .bug: return "BUG"
        case .rock: return "RCK"
        case .ghost: return "GHO"
        case .dragon: return "DRG"
        case .dark: return "DRK"
        case .steel: return "STL"
        case .fairy: return "FAI"
        }
    }

    /// Background/foreground colors for the type badge (matches .type-XXXX rules in index.css).
    var badgeColors: (background: Color, foreground: Color) {
        switch self {
        case .normal:   return (Color(hex: "#a0a0a0"), Color(hex: "#0f380f"))
        case .fire:     return (Color(hex: "#c04000"), Color(hex: "#e0f8d0"))
        case .water:    return (Color(hex: "#0060c0"), Color(hex: "#e0f8d0"))
        case .grass:    return (Color(hex: "#306230"), Color(hex: "#e0f8d0"))
        case .electric: return (Color(hex: "#c0a000"), Color(hex: "#0f380f"))
        case .ice:      return (Color(hex: "#80c0c0"), Color(hex: "#0f380f"))
        case .fighting: return (Color(hex: "#800000"), Color(hex: "#e0f8d0"))
        case .poison:   return (Color(hex: "#600060"), Color(hex: "#e0f8d0"))
        case .ground:   return (Color(hex: "#a08000"), Color(hex: "#0f380f"))
        case .flying:   return (Color(hex: "#6080c0"), Color(hex: "#e0f8d0"))
        case .psychic:  return (Color(hex: "#c00060"), Color(hex: "#e0f8d0"))
        case .bug:      return (Color(hex: "#608000"), Color(hex: "#e0f8d0"))
        case .rock:     return (Color(hex: "#806020"), Color(hex: "#e0f8d0"))
        case .ghost:    return (Color(hex: "#402060"), Color(hex: "#e0f8d0"))
        case .dragon:   return (Color(hex: "#4000a0"), Color(hex: "#e0f8d0"))
        case .dark:     return (Color(hex: "#403020"), Color(hex: "#e0f8d0"))
        case .steel:    return (Color(hex: "#8080a0"), Color(hex: "#0f380f"))
        case .fairy:    return (Color(hex: "#c080c0"), Color(hex: "#0f380f"))
        }
    }

    /// Physical-category types per the original mkMove() categorization rule in gameData.ts.
    static let physicalCategoryTypes: Set<PokemonType> = [
        .fighting, .normal, .ground, .flying, .steel, .dragon, .dark, .ghost, .bug, .rock, .ice, .poison,
    ]
}
