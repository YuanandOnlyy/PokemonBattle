import Foundation

/// Extended flavor info for the Pokedex detail view's INFO tab. A port of `POKEDEX_DATA` in
/// Pokedex.tsx. Not every roster Pokemon has an entry (matches the original — those show
/// "DATA NOT FOUND" on the INFO tab).
struct PokedexEntry {
    var description: String
    var height: String
    var weight: String
    var ability: String
    var weaknesses: [PokemonType]
    var resistances: [PokemonType]
}

enum PokedexData {
    static let entries: [Int: PokedexEntry] = [
        25: PokedexEntry(
            description: "When several of these POKéMON gather, their electricity can build and cause lightning storms.",
            height: "0.4m", weight: "6.0kg", ability: "Static",
            weaknesses: [.ground], resistances: [.electric, .flying, .steel]
        ),
        6: PokedexEntry(
            description: "Spits fire that is hot enough to melt boulders. Known to cause forest fires unintentionally.",
            height: "1.7m", weight: "90.5kg", ability: "Blaze",
            weaknesses: [.water, .electric, .rock], resistances: [.fire, .grass, .fighting, .bug, .steel]
        ),
        9: PokedexEntry(
            description: "A brutal POKéMON with pressurized water jets on its shell. They are used for high-speed tackles.",
            height: "1.6m", weight: "85.5kg", ability: "Torrent",
            weaknesses: [.grass, .electric], resistances: [.fire, .water, .ice, .steel]
        ),
        3: PokedexEntry(
            description: "The plant blooms when it is absorbing solar energy. It stays on the move to seek sunlight.",
            height: "2.0m", weight: "100.0kg", ability: "Overgrow",
            weaknesses: [.fire, .ice, .flying, .psychic], resistances: [.water, .grass, .electric, .fighting]
        ),
        94: PokedexEntry(
            description: "Under a full moon, this POKéMON likes to mimic the shadows of humans and frighten them.",
            height: "1.5m", weight: "40.5kg", ability: "Cursed Body",
            weaknesses: [.ground, .psychic, .ghost, .dark], resistances: [.poison, .bug, .grass, .fairy]
        ),
        448: PokedexEntry(
            description: "It has the ability to sense the auras of all things. It understands human speech.",
            height: "1.2m", weight: "54.0kg", ability: "Steadfast",
            weaknesses: [.fire, .ground, .fighting],
            resistances: [.normal, .rock, .bug, .steel, .grass, .ice, .dragon, .dark]
        ),
        445: PokedexEntry(
            description: "Its body has been honed as a result of its struggles to survive in the fierce wild nature.",
            height: "1.9m", weight: "95.0kg", ability: "Sand Veil",
            weaknesses: [.ice, .dragon, .fairy], resistances: [.fire, .rock, .poison, .electric, .ground]
        ),
        658: PokedexEntry(
            description: "It creates throwing stars out of compressed water. When it spins them and throws them at high speed, these stars can cut metal.",
            height: "1.5m", weight: "40.0kg", ability: "Torrent",
            weaknesses: [.grass, .electric, .fighting, .bug, .fairy],
            resistances: [.fire, .water, .ice, .steel, .ghost, .dark]
        ),
        133: PokedexEntry(
            description: "Its genetic code is irregular. It may mutate if it is exposed to radiation from element STONEs.",
            height: "0.3m", weight: "6.5kg", ability: "Run Away",
            weaknesses: [.fighting], resistances: [.ghost]
        ),
        143: PokedexEntry(
            description: "Very lazy. Just eats and sleeps. As its rotund bulk builds, it becomes steadily more slothful.",
            height: "2.1m", weight: "460.0kg", ability: "Immunity",
            weaknesses: [.fighting], resistances: [.ghost]
        ),
        149: PokedexEntry(
            description: "An extremely rarely seen marine POKéMON. Its intelligence is said to match that of humans.",
            height: "2.2m", weight: "210.0kg", ability: "Inner Focus",
            weaknesses: [.ice, .rock, .dragon, .fairy], resistances: [.fire, .water, .bug, .fighting, .grass]
        ),
        150: PokedexEntry(
            description: "A POKéMON that was created by genetic manipulation. However, even though the scientific power of humans created this POKéMON's body, they failed to endow it with a compassionate heart.",
            height: "2.0m", weight: "122.0kg", ability: "Pressure",
            weaknesses: [.bug, .ghost, .dark], resistances: [.fighting, .psychic]
        ),
        1: PokedexEntry(
            description: "A strange seed was planted on its back at birth. The plant sprouts and grows with this POKéMON.",
            height: "0.7m", weight: "6.9kg", ability: "Overgrow",
            weaknesses: [.fire, .ice, .flying, .psychic], resistances: [.water, .grass, .electric, .fighting]
        ),
        4: PokedexEntry(
            description: "Obviously prefers hot places. When it rains, steam is said to spout from the tip of its tail.",
            height: "0.6m", weight: "8.5kg", ability: "Blaze",
            weaknesses: [.water, .ground, .rock], resistances: [.fire, .grass, .ice, .bug, .steel, .fairy]
        ),
        7: PokedexEntry(
            description: "After birth, its back swells and hardens into a shell. Powerfully sprays foam from its mouth.",
            height: "0.5m", weight: "9.0kg", ability: "Torrent",
            weaknesses: [.grass, .electric], resistances: [.fire, .water, .ice, .steel]
        ),
        26: PokedexEntry(
            description: "Its long tail serves as a ground to protect itself from its own high-voltage power.",
            height: "0.8m", weight: "30.0kg", ability: "Static",
            weaknesses: [.ground], resistances: [.electric, .flying, .steel]
        ),
        93: PokedexEntry(
            description: "Because of its ability to slip through block walls, it is said to be from another dimension.",
            height: "1.6m", weight: "0.1kg", ability: "Levitate",
            weaknesses: [.ground, .psychic, .ghost, .dark], resistances: [.poison, .bug, .grass, .fairy]
        ),
        447: PokedexEntry(
            description: "It's diligent about its training. Because it lives alongside humans, it has developed a gentle nature.",
            height: "0.7m", weight: "20.2kg", ability: "Inner Focus",
            weaknesses: [.fire, .ground, .fighting],
            resistances: [.normal, .rock, .bug, .steel, .grass, .ice]
        ),
        444: PokedexEntry(
            description: "It nests in the ground to steal the prey of other POKEMON. Its wings are not yet fully grown.",
            height: "1.4m", weight: "56.0kg", ability: "Sand Veil",
            weaknesses: [.ice, .dragon, .fairy], resistances: [.fire, .rock, .poison, .electric]
        ),
        656: PokedexEntry(
            description: "It secretes flexible bubbles from its chest and back. The bubbles reduce the damage it receives.",
            height: "0.3m", weight: "7.0kg", ability: "Torrent",
            weaknesses: [.grass, .electric], resistances: [.fire, .water, .ice, .steel]
        ),
    ]

    static func entry(for pokemonID: Int) -> PokedexEntry? {
        entries[pokemonID]
    }
}
