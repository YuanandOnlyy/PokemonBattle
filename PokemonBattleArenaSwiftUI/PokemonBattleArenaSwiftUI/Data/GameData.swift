import Foundation

/// Static game content: the Pokemon roster, starting items/achievements, and daily quest pool.
/// A line-for-line port of `src/data/gameData.ts`.
enum GameData {
    static let allPokemon: [Pokemon] = [
        // MARK: Gen 1 starters & classics
        Pokemon(
            id: 1, name: "Bulbasaur", types: [.grass, .poison], baseHP: 90,
            atk: 49, def: 49, spAtk: 65, spDef: 65, spd: 45,
            moves: [
                .physical("Vine Whip", .grass, 45, 100, 25),
                .physical("Tackle", .normal, 40, 100, 35),
                .special("Razor Leaf", .grass, 55, 95, 25),
                .status("Sleep Powder", .grass, 75, 15, statusEffect: .sleep),
            ],
            level: 50, xp: 0, xpToNext: 100, ability: "Overgrow",
            evolvesInto: 3, evolutionLevel: 32, rarity: .common
        ),
        Pokemon(
            id: 3, name: "Venusaur", types: [.grass, .poison], baseHP: 120,
            atk: 82, def: 83, spAtk: 100, spDef: 100, spd: 80,
            moves: [
                .physical("Vine Whip", .grass, 45, 100, 25),
                .special("Solar Beam", .grass, 120, 100, 10),
                .physical("Razor Leaf", .grass, 55, 95, 25),
                .status("Sleep Powder", .grass, 75, 15, statusEffect: .sleep),
            ],
            level: 50, xp: 0, xpToNext: 100, ability: "Overgrow",
            evolutionOf: 1, rarity: .rare
        ),
        Pokemon(
            id: 4, name: "Charmander", types: [.fire], baseHP: 78,
            atk: 52, def: 43, spAtk: 60, spDef: 50, spd: 65,
            moves: [
                .special("Ember", .fire, 40, 100, 25),
                .physical("Scratch", .normal, 40, 100, 35),
                .physical("Dragon Rage", .dragon, 40, 100, 10),
                .status("Smokescreen", .normal, 100, 20),
            ],
            level: 50, xp: 0, xpToNext: 100, ability: "Blaze",
            evolvesInto: 6, evolutionLevel: 36, rarity: .common
        ),
        Pokemon(
            id: 6, name: "Charizard", types: [.fire, .flying], baseHP: 120,
            atk: 84, def: 78, spAtk: 109, spDef: 85, spd: 100,
            moves: [
                .special("Flamethrower", .fire, 90, 100, 15),
                .special("Fire Spin", .fire, 35, 85, 15),
                .physical("Dragon Claw", .dragon, 80, 100, 15),
                .physical("Wing Attack", .flying, 60, 100, 35),
            ],
            level: 50, xp: 0, xpToNext: 100, ability: "Blaze",
            evolutionOf: 4, rarity: .rare
        ),
        Pokemon(
            id: 7, name: "Squirtle", types: [.water], baseHP: 88,
            atk: 48, def: 65, spAtk: 50, spDef: 64, spd: 43,
            moves: [
                .special("Water Gun", .water, 40, 100, 25),
                .physical("Tackle", .normal, 40, 100, 35),
                .physical("Bite", .dark, 60, 100, 25),
                .special("Bubble Beam", .water, 65, 100, 20),
            ],
            level: 50, xp: 0, xpToNext: 100, ability: "Torrent",
            evolvesInto: 9, evolutionLevel: 36, rarity: .common
        ),
        Pokemon(
            id: 9, name: "Blastoise", types: [.water], baseHP: 110,
            atk: 83, def: 100, spAtk: 85, spDef: 105, spd: 78,
            moves: [
                .special("Water Gun", .water, 40, 100, 25),
                .special("Hydro Pump", .water, 110, 80, 5),
                .physical("Skull Bash", .normal, 130, 100, 10),
                .special("Ice Beam", .ice, 90, 100, 10),
            ],
            level: 50, xp: 0, xpToNext: 100, ability: "Torrent",
            evolutionOf: 7, rarity: .rare
        ),
        Pokemon(
            id: 25, name: "Pikachu", types: [.electric], baseHP: 100,
            atk: 55, def: 40, spAtk: 50, spDef: 50, spd: 90,
            moves: [
                .special("Thundershock", .electric, 40, 100, 25),
                .physical("Quick Attack", .normal, 40, 100, 30),
                .special("Electro Ball", .electric, 80, 100, 10),
                .physical("Iron Tail", .steel, 100, 75, 15),
            ],
            level: 50, xp: 0, xpToNext: 100, ability: "Static",
            evolvesInto: 26, rarity: .uncommon
        ),
        Pokemon(
            id: 26, name: "Raichu", types: [.electric], baseHP: 110,
            atk: 90, def: 55, spAtk: 90, spDef: 80, spd: 110,
            moves: [
                .special("Thunderbolt", .electric, 90, 100, 15),
                .physical("Quick Attack", .normal, 40, 100, 30),
                .special("Thunder", .electric, 110, 70, 10),
                .physical("Iron Tail", .steel, 100, 75, 15),
            ],
            level: 50, xp: 0, xpToNext: 100, ability: "Static",
            evolutionOf: 25, rarity: .uncommon
        ),

        // MARK: Ghost line
        Pokemon(
            id: 93, name: "Haunter", types: [.ghost, .poison], baseHP: 85,
            atk: 50, def: 45, spAtk: 115, spDef: 55, spd: 95,
            moves: [
                .special("Shadow Ball", .ghost, 80, 100, 15),
                .status("Hypnosis", .psychic, 60, 20, statusEffect: .sleep),
                .physical("Lick", .ghost, 30, 100, 30, statusEffect: .paralysis),
                .special("Dream Eater", .psychic, 100, 100, 15),
            ],
            level: 50, xp: 0, xpToNext: 100, ability: "Levitate",
            evolvesInto: 94, rarity: .uncommon
        ),
        Pokemon(
            id: 94, name: "Gengar", types: [.ghost, .poison], baseHP: 90,
            atk: 65, def: 60, spAtk: 130, spDef: 75, spd: 110,
            moves: [
                .special("Shadow Ball", .ghost, 80, 100, 15),
                .status("Hypnosis", .psychic, 60, 20, statusEffect: .sleep),
                .special("Dream Eater", .psychic, 100, 100, 15),
                .special("Sludge Bomb", .poison, 90, 100, 10),
            ],
            level: 50, xp: 0, xpToNext: 100, ability: "Levitate",
            evolutionOf: 93, rarity: .rare
        ),

        // MARK: Fighting/Steel line
        Pokemon(
            id: 447, name: "Riolu", types: [.fighting], baseHP: 80,
            atk: 70, def: 40, spAtk: 35, spDef: 40, spd: 60,
            moves: [
                .physical("Force Palm", .fighting, 60, 100, 10, statusEffect: .paralysis),
                .physical("Quick Attack", .normal, 40, 100, 30),
                .physical("Metal Claw", .steel, 50, 95, 35),
                .status("Calm Mind", .psychic, 100, 20),
            ],
            level: 50, xp: 0, xpToNext: 100, ability: "Inner Focus",
            evolvesInto: 448, rarity: .common
        ),
        Pokemon(
            id: 448, name: "Lucario", types: [.fighting, .steel], baseHP: 100,
            atk: 110, def: 70, spAtk: 115, spDef: 70, spd: 90,
            moves: [
                .physical("Close Combat", .fighting, 120, 100, 5),
                .special("Aura Sphere", .fighting, 80, 100, 20),
                .physical("Metal Claw", .steel, 50, 95, 35),
                .physical("Bone Rush", .ground, 25, 90, 10),
            ],
            level: 50, xp: 0, xpToNext: 100, ability: "Inner Focus",
            evolutionOf: 447, rarity: .rare
        ),

        // MARK: Dragon/Ground line
        Pokemon(
            id: 444, name: "Gabite", types: [.dragon, .ground], baseHP: 108,
            atk: 95, def: 75, spAtk: 60, spDef: 60, spd: 82,
            moves: [
                .physical("Dragon Claw", .dragon, 80, 100, 15),
                .physical("Dig", .ground, 80, 100, 10),
                .physical("Slash", .normal, 70, 100, 20),
                .physical("Sand Attack", .ground, 30, 100, 15),
            ],
            level: 50, xp: 0, xpToNext: 100, ability: "Sand Veil",
            evolvesInto: 445, rarity: .uncommon
        ),
        Pokemon(
            id: 445, name: "Garchomp", types: [.dragon, .ground], baseHP: 130,
            atk: 130, def: 95, spAtk: 80, spDef: 85, spd: 102,
            moves: [
                .physical("Dragon Rush", .dragon, 100, 75, 10),
                .physical("Earthquake", .ground, 100, 100, 10),
                .physical("Crunch", .dark, 80, 100, 15),
                .physical("Iron Head", .steel, 80, 100, 15),
            ],
            level: 50, xp: 0, xpToNext: 100, ability: "Sand Veil",
            evolutionOf: 444, rarity: .rare
        ),

        // MARK: Water/Dark
        Pokemon(
            id: 656, name: "Froakie", types: [.water], baseHP: 80,
            atk: 56, def: 40, spAtk: 62, spDef: 44, spd: 71,
            moves: [
                .special("Bubble", .water, 40, 100, 30),
                .physical("Quick Attack", .normal, 40, 100, 30),
                .physical("Pound", .normal, 40, 100, 35),
                .status("Smokescreen", .normal, 100, 20),
            ],
            level: 50, xp: 0, xpToNext: 100, ability: "Torrent",
            evolvesInto: 658, rarity: .common
        ),
        Pokemon(
            id: 658, name: "Greninja", types: [.water, .dark], baseHP: 95,
            atk: 95, def: 67, spAtk: 103, spDef: 71, spd: 122,
            moves: [
                .physical("Water Shuriken", .water, 15, 100, 20),
                .physical("Night Slash", .dark, 70, 100, 15),
                .special("Ice Beam", .ice, 90, 100, 10),
                .special("Extrasensory", .psychic, 80, 100, 20),
            ],
            level: 50, xp: 0, xpToNext: 100, ability: "Torrent",
            evolutionOf: 656, rarity: .rare
        ),

        // MARK: Misc
        Pokemon(
            id: 133, name: "Eevee", types: [.normal], baseHP: 95,
            atk: 55, def: 50, spAtk: 45, spDef: 65, spd: 55,
            moves: [
                .physical("Tackle", .normal, 40, 100, 35),
                .physical("Quick Attack", .normal, 40, 100, 30),
                .special("Swift", .normal, 60, 100, 20),
                .special("Shadow Ball", .ghost, 80, 100, 15),
            ],
            level: 50, xp: 0, xpToNext: 100, ability: "Run Away", rarity: .uncommon
        ),
        Pokemon(
            id: 143, name: "Snorlax", types: [.normal], baseHP: 160,
            atk: 110, def: 65, spAtk: 65, spDef: 110, spd: 30,
            moves: [
                .physical("Body Slam", .normal, 85, 100, 15, statusEffect: .paralysis),
                .special("Hyper Beam", .normal, 150, 90, 5),
                .status("Rest", .normal, 100, 10, statusEffect: .sleep, isSelfStatus: true, healPercent: 100),
                .physical("Heavy Slam", .steel, 100, 100, 10),
            ],
            level: 50, xp: 0, xpToNext: 100, ability: "Immunity", rarity: .rare
        ),
        Pokemon(
            id: 149, name: "Dragonite", types: [.dragon, .flying], baseHP: 130,
            atk: 134, def: 95, spAtk: 100, spDef: 100, spd: 80,
            moves: [
                .special("Dragon Breath", .dragon, 60, 100, 20),
                .special("Hurricane", .flying, 110, 70, 10),
                .special("Thunder", .electric, 110, 70, 10),
                .physical("Extreme Speed", .normal, 80, 100, 5),
            ],
            level: 50, xp: 0, xpToNext: 100, ability: "Inner Focus", rarity: .rare
        ),
        Pokemon(
            id: 150, name: "Mewtwo", types: [.psychic], baseHP: 130,
            atk: 110, def: 90, spAtk: 154, spDef: 90, spd: 130,
            moves: [
                .special("Psychic", .psychic, 90, 100, 10),
                .special("Shadow Ball", .ghost, 80, 100, 15),
                .special("Aura Sphere", .fighting, 80, 100, 20),
                .status("Recover", .psychic, 100, 10, isSelfStatus: true, healPercent: 50),
            ],
            level: 50, xp: 0, xpToNext: 100, ability: "Pressure", rarity: .legendary
        ),
    ]

    static let initialItems: [Item] = [
        Item(name: "Potion", description: "Restores 20 HP", count: 3, effect: .heal200, value: 20),
        Item(name: "Super Potion", description: "Restores 50 HP", count: 2, effect: .heal200, value: 50),
        Item(name: "X Attack", description: "Boosts ATK by 1.5x", count: 2, effect: .boostAtk, value: 1.5),
        Item(name: "X Defense", description: "Boosts DEF by 1.5x", count: 2, effect: .boostDef, value: 1.5),
    ]

    static let initialAchievements: [Achievement] = [
        Achievement(id: "first_battle", name: "First Steps", description: "Complete your first battle",
                    unlockCondition: "Win or lose your first battle", unlocked: false, progress: 0, target: 1),
        Achievement(id: "first_win", name: "Victorious!", description: "Win your first battle",
                    unlockCondition: "Win a battle", unlocked: false, progress: 0, target: 1),
        Achievement(id: "win_streak_3", name: "On Fire!", description: "Win 3 battles in a row",
                    unlockCondition: "Win 3 consecutive battles", unlocked: false, progress: 0, target: 3),
        Achievement(id: "win_10", name: "Champion", description: "Win 10 battles total",
                    unlockCondition: "Win 10 battles", unlocked: false, progress: 0, target: 10),
        Achievement(id: "crit_master", name: "Critical Hit!", description: "Land 20 critical hits",
                    unlockCondition: "Land 20 critical hits in total", unlocked: false, progress: 0, target: 20),
        Achievement(id: "type_master", name: "Type Master", description: "Deal super effective damage 10 times",
                    unlockCondition: "Hit super effective 10 times", unlocked: false, progress: 0, target: 10),
        Achievement(id: "all_pokemon", name: "Gotta Use Em All", description: "Use every pokemon at least once",
                    unlockCondition: "Use all 20 pokemon", unlocked: false, progress: 0, target: 20),
        Achievement(id: "quest_devotee", name: "Daily Devotee", description: "Complete a daily quest",
                    unlockCondition: "Finish any daily quest", unlocked: false, progress: 0, target: 1),
    ]

    private static let questPool: [DailyQuest] = [
        DailyQuest(id: "q_win", description: "Win a battle", type: .winBattle, target: 1, progress: 0, completed: false, rewardXP: 50),
        DailyQuest(id: "q_crits", description: "Land 3 critical hits in one battle", type: .landCrits, target: 3, progress: 0, completed: false, rewardXP: 60),
        DailyQuest(id: "q_item", description: "Use an item during battle", type: .useItem, target: 1, progress: 0, completed: false, rewardXP: 40),
        DailyQuest(id: "q_super", description: "Hit super effective 5 times total", type: .superEffective, target: 5, progress: 0, completed: false, rewardXP: 70),
        DailyQuest(id: "q_win2", description: "Win 2 battles today", type: .winBattle, target: 2, progress: 0, completed: false, rewardXP: 100),
    ]

    /// Deterministically picks 3 quests from the pool using the date string as a seed
    /// (same LCG as `generateDailyQuests` in gameData.ts) so a given calendar day always
    /// gets the same quest set.
    static func generateDailyQuests(dateString: String) -> [DailyQuest] {
        let seed = dateString.unicodeScalars.reduce(0) { $0 + Int($1.value) }
        var picks: [DailyQuest] = []
        var used = Set<Int>()
        var s = seed
        while picks.count < 3 && used.count < questPool.count {
            s = (s &* 1_664_525 &+ 1_013_904_223) & 0x7FFF_FFFF
            let idx = s % questPool.count
            if !used.contains(idx) {
                used.insert(idx)
                picks.append(questPool[idx])
            }
        }
        return picks
    }

    static let initialTrainer = TrainerData(
        name: "TRAINER",
        level: 1, xp: 0, xpToNext: 100,
        wins: 0, losses: 0, streak: 0, bestStreak: 0,
        totalBattles: 0, totalDamageDealt: 0, totalCritHits: 0, totalSuperEffective: 0,
        favoritePokemons: [:],
        battleHistory: [],
        achievements: initialAchievements,
        items: initialItems,
        settings: .initial,
        consecutiveDefeats: 0,
        dailyQuests: [],
        dailyQuestDate: "",
        lastTeamIDs: [],
        avatarKey: "default_trainer"
    )

    static func pokemon(id: Int) -> Pokemon? {
        allPokemon.first { $0.id == id }
    }

    static func pokemon(named name: String) -> Pokemon? {
        allPokemon.first { $0.name.caseInsensitiveCompare(name) == .orderedSame }
    }
}
