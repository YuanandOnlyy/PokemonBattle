import Foundation

/// A battle-usable consumable. Mirrors `Item` in types.ts. Persisted as part of TrainerData.
struct Item: Identifiable, Codable, Hashable {
    enum Effect: String, Codable, Hashable {
        case healHalf = "heal_half"
        case healFull = "heal_full"
        case heal200 = "heal_200"
        case boostAtk = "boost_atk"
        case boostDef = "boost_def"
    }

    var name: String
    var description: String
    var count: Int
    var effect: Effect
    var value: Double

    var id: String { name }
}
