import Foundation
import Observation

/// App-wide game state and orchestration. A port of `GameContext.tsx` / `GameProvider`.
///
/// The original used chained `setTimeout` callbacks to sequence battle messages (a typewriter
/// effect, then a fixed pause, then the next message) and to reset shake/flash animation flags
/// after a fixed delay. Swift's structured concurrency makes that sequencing an ordinary
/// `async`/`await` function instead of a callback pyramid — `showMessage`/`processMessages` below
/// are directly equivalent to their JS namesakes, just written top-to-bottom.
@MainActor
@Observable
final class GameViewModel {
    private static let storageKey = "pokemon-battle-arena-v1"

    var currentScreen: Screen = .title
    var trainerData: TrainerData
    var battleState: BattleState?
    var battleResult: BattleResult?
    var selectedPokedexPokemon: Pokemon?

    init() {
        trainerData = Self.loadTrainer()
        ensureDailyQuests()
    }

    // MARK: - Navigation & persistence

    func navigate(_ screen: Screen) {
        currentScreen = screen
    }

    /// Mirrors `updateTrainer(partial)` in GameContext.tsx: mutate the trainer save in place, then
    /// persist. Used by Settings/TrainerProfile for skin, toggles, name, and reset.
    func updateTrainer(_ mutate: (inout TrainerData) -> Void) {
        mutate(&trainerData)
        saveTrainer()
    }

    /// Mirrors `resetGame` in Settings.tsx: wipes all progress but keeps the trainer's chosen name.
    func resetGame() {
        let name = trainerData.name
        trainerData = GameData.initialTrainer
        trainerData.name = name
        saveTrainer()
        ensureDailyQuests()
    }

    func ensureDailyQuests() {
        let today = Self.todayString()
        if trainerData.dailyQuestDate == today && !trainerData.dailyQuests.isEmpty { return }
        trainerData.dailyQuests = GameData.generateDailyQuests(dateString: today)
        trainerData.dailyQuestDate = today
        saveTrainer()
    }

    private func saveTrainer() {
        guard let data = try? JSONEncoder().encode(trainerData) else { return }
        UserDefaults.standard.set(data, forKey: Self.storageKey)
    }

    private static func loadTrainer() -> TrainerData {
        guard let data = UserDefaults.standard.data(forKey: storageKey) else { return GameData.initialTrainer }
        return (try? JSONDecoder().decode(TrainerData.self, from: data)) ?? GameData.initialTrainer
    }

    private static func todayString() -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        formatter.timeStyle = .none
        return formatter.string(from: Date())
    }

    // MARK: - Battle message sequencing (typewriter)

    /// Types `message` into `battleState.displayedMessage` one character at a time, then holds
    /// briefly once fully shown. Mirrors `showMessage` in GameContext.tsx.
    private func showMessage(_ message: String) async {
        guard battleState != nil else { return }
        battleState?.displayedMessage = ""
        battleState?.currentMessage = message

        let speed: UInt64 = trainerData.settings.animationSpeed == .fast ? 20_000_000 : 50_000_000
        var shown = ""
        for character in message {
            try? await Task.sleep(nanoseconds: speed)
            guard battleState != nil else { return }
            shown.append(character)
            battleState?.displayedMessage = shown
        }
        try? await Task.sleep(nanoseconds: 600_000_000)
    }

    /// Mirrors `processMessages` in GameContext.tsx: shows each message in order, awaiting the
    /// full typewriter + pause for each before moving to the next.
    private func processMessages(_ messages: [String]) async {
        for message in messages {
            await showMessage(message)
        }
    }

    /// Sets a shake/flash/screen-shake flag, then clears it after `duration` without blocking the
    /// caller (fire-and-forget). Mirrors `triggerAnimation` in GameContext.tsx.
    private func triggerAnimation(_ keyPath: WritableKeyPath<BattleState, Bool>, duration: Double) {
        battleState?[keyPath: keyPath] = true
        Task { [weak self] in
            try? await Task.sleep(nanoseconds: UInt64(duration * 1_000_000_000))
            self?.battleState?[keyPath: keyPath] = false
        }
    }

    /// Mirrors `showFloatingDamage` in GameContext.tsx.
    private func showFloatingDamage(_ value: String) {
        let id = Int(Date().timeIntervalSince1970 * 1000)
        battleState?.floatingDamage = FloatingDamage(value: value, id: id)
        Task { [weak self] in
            try? await Task.sleep(nanoseconds: 1_100_000_000)
            if self?.battleState?.floatingDamage?.id == id {
                self?.battleState?.floatingDamage = nil
            }
        }
    }

    // MARK: - Starting & ending a battle

    /// Mirrors `startBattle` in GameContext.tsx.
    func startBattle(playerTeam: [Pokemon]) {
        let playerIDs = Set(playerTeam.map(\.id))
        let eligible = GameData.allPokemon.filter { !playerIDs.contains($0.id) }
        let enemyPicks = Array(eligible.shuffled().prefix(min(3, eligible.count)))
        guard let firstEnemy = enemyPicks.first else { return }

        let playerBattle = playerTeam.map(BattleEngine.createBattlePokemon)
        let enemyBattle = enemyPicks.map(BattleEngine.createBattlePokemon)

        var damageByPokemon: [String: Int] = [:]
        for p in playerTeam { damageByPokemon[p.name] = 0 }

        battleState = BattleState(
            playerTeam: playerBattle, enemyTeam: enemyBattle,
            activePlayerIndex: 0, activeEnemyIndex: 0, phase: .menu,
            currentMessage: "A wild \(firstEnemy.name) appeared!", displayedMessage: "",
            turn: 1, startTime: Date(),
            totalDamageDealt: 0, totalCritHits: 0, totalSuperEffective: 0, itemsUsed: 0,
            damageByPokemon: damageByPokemon,
            isPlayerShaking: false, isEnemyShaking: false,
            isPlayerFlashing: false, isEnemyFlashing: false, isScreenShaking: false,
            floatingDamage: nil, xpGained: [], levelUps: []
        )
        battleResult = nil
        navigate(.battle)

        var usageCounts = trainerData.favoritePokemons
        for p in playerTeam { usageCounts[p.name, default: 0] += 1 }
        trainerData.favoritePokemons = usageCounts
        saveTrainer()

        Task {
            try? await Task.sleep(nanoseconds: 300_000_000)
            await processMessages(["A wild \(firstEnemy.name) appeared!", "Go! \(playerTeam[0].name)!"])
            battleState?.phase = .menu
            battleState?.displayedMessage = "What will \(playerTeam[0].name) do?"
        }
    }

    /// Mirrors `endBattle` in GameContext.tsx: rolls XP, updates trainer stats/streak/items,
    /// advances daily quests and achievements, saves, then hands off to Victory/Defeat.
    private func endBattle(won: Bool) async {
        guard let state = battleState else { return }
        let duration = max(0, Int(Date().timeIntervalSince(state.startTime)))

        let levelUps: [String] = [] // The original app never populates level-ups; ported as-is.
        let baseXP = won ? 80 : 20
        let xpGained: [XPEntry] = state.playerTeam.map { p in
            XPEntry(name: p.name, amount: p.isFainted ? Int(Double(baseXP) * 0.3) : baseXP + Int.random(in: 0..<40))
        }

        let mvpEntry = state.damageByPokemon.max { $0.value < $1.value }
        let mvpPokemon = (mvpEntry?.value ?? 0) > 0 ? mvpEntry?.key : nil

        let enemy = state.enemyTeam.indices.contains(state.activeEnemyIndex)
            ? state.enemyTeam[state.activeEnemyIndex]
            : state.enemyTeam[0]
        let tip = won ? nil : BattleEngine.generateDefeatTip(enemyName: enemy.name, enemyTypes: enemy.types)

        let record = BattleRecord(
            id: UUID().uuidString, date: Self.todayString(), result: won ? .victory : .defeat,
            playerTeam: state.playerTeam.map(\.name), enemyPokemon: state.enemyTeam[0].name,
            xpGained: xpGained.reduce(0) { $0 + $1.amount }, duration: duration,
            damageDealt: state.totalDamageDealt, critHits: state.totalCritHits
        )

        let prevTotalSuperEffective = trainerData.totalSuperEffective

        trainerData.totalBattles += 1
        trainerData.totalDamageDealt += state.totalDamageDealt
        trainerData.totalCritHits += state.totalCritHits
        trainerData.totalSuperEffective += state.totalSuperEffective
        trainerData.battleHistory = Array(([record] + trainerData.battleHistory).prefix(50))

        if won {
            trainerData.wins += 1
            trainerData.streak += 1
            trainerData.consecutiveDefeats = 0
            trainerData.bestStreak = max(trainerData.bestStreak, trainerData.streak)
        } else {
            trainerData.losses += 1
            trainerData.streak = 0
            trainerData.consecutiveDefeats += 1
            if trainerData.consecutiveDefeats >= 3 {
                if let idx = trainerData.items.firstIndex(where: { $0.name == "Potion" }) {
                    trainerData.items[idx].count += 1
                }
                trainerData.consecutiveDefeats = 0
            }
        }

        let trainerXPGain = won ? 50 : 15
        trainerData.xp += trainerXPGain
        if trainerData.xp >= trainerData.xpToNext {
            trainerData.xp -= trainerData.xpToNext
            trainerData.level += 1
            trainerData.xpToNext = Int(Double(trainerData.xpToNext) * 1.5)
        }

        let today = Self.todayString()
        if trainerData.dailyQuestDate == today {
            var questsCompleted = 0
            trainerData.dailyQuests = trainerData.dailyQuests.map { quest in
                var q = quest
                if q.completed { return q }
                switch q.type {
                case .winBattle where won: q.progress += 1
                case .landCrits: q.progress = min(q.target, q.progress + state.totalCritHits)
                case .useItem: q.progress = min(q.target, q.progress + state.itemsUsed)
                case .superEffective: q.progress = min(q.target, prevTotalSuperEffective + state.totalSuperEffective)
                default: break
                }
                let completed = q.progress >= q.target
                if completed { questsCompleted += 1 }
                q.completed = completed
                return q
            }
            if questsCompleted > 0 {
                trainerData.xp += questsCompleted * 50
            }
        }

        let usedPokemonNames = Set(trainerData.favoritePokemons.keys)
        trainerData.achievements = trainerData.achievements.map { achievement in
            var a = achievement
            if a.unlocked { return a }
            switch a.id {
            case "first_battle": a.progress = trainerData.totalBattles
            case "first_win": a.progress = trainerData.wins
            case "win_streak_3": a.progress = trainerData.streak
            case "win_10": a.progress = trainerData.wins
            case "crit_master": a.progress = trainerData.totalCritHits
            case "type_master": a.progress = trainerData.totalSuperEffective
            case "all_pokemon": a.progress = usedPokemonNames.count
            case "quest_devotee": a.progress = trainerData.dailyQuests.contains { $0.completed } ? 1 : 0
            default: break
            }
            let unlocked = a.progress >= a.target
            if unlocked && !a.unlocked {
                a.unlockedDate = today
            }
            a.unlocked = unlocked
            return a
        }

        saveTrainer()

        let faintedNames = state.enemyTeam.filter(\.isFainted).map(\.name)
        let enemyDefeated = faintedNames.isEmpty ? state.enemyTeam.first?.name : faintedNames.joined(separator: ", ")

        battleResult = BattleResult(won: won, xpGained: xpGained, levelUps: levelUps,
                                     enemyDefeated: enemyDefeated, mvpPokemon: mvpPokemon, tip: tip)
        battleState?.phase = .battleEnd
        battleState?.xpGained = xpGained
        battleState?.levelUps = levelUps

        try? await Task.sleep(nanoseconds: 1_500_000_000)
        navigate(won ? .victory : .defeat)
    }

    // MARK: - Player actions

    /// Mirrors `playerAttack` in GameContext.tsx. The pre-check below intentionally discards its
    /// status roll (mirroring the original's `processStatusDamage({ ...player })` throwaway copy) —
    /// the persisted status tick happens later in `executePlayerStatusTurn`, once per round.
    func playerAttack(_ moveIndex: Int) {
        guard let state = battleState, state.phase == .menu || state.phase == .moveSelect else { return }
        var scratch = state.playerTeam[state.activePlayerIndex]
        let statusResult = BattleEngine.processStatusDamage(&scratch)

        if statusResult.shouldSkip {
            battleState?.phase = .animating
            Task {
                await processMessages([statusResult.message])
                await executeEnemyTurn()
            }
            return
        }

        Task { await executePlayerMove(moveIndex) }
    }

    private func executePlayerMove(_ moveIndex: Int) async {
        guard var state = battleState else { return }
        let playerIdx = state.activePlayerIndex
        var player = state.playerTeam[playerIdx]
        guard moveIndex < player.moves.count else { return }
        player.moves[moveIndex].currentPP = max(0, player.moves[moveIndex].currentPP - 1)
        state.playerTeam[playerIdx] = player
        state.phase = .animating
        battleState = state

        let enemyIdx = state.activeEnemyIndex
        var enemy = state.enemyTeam[enemyIdx]
        let move = player.moves[moveIndex]
        var messages = ["\(player.name) used \(move.name)!"]

        let hits = Double.random(in: 0..<100) < Double(move.accuracy)
        guard hits else {
            messages.append("\(player.name)'s attack missed!")
            battleState = state
            await processMessages(messages)
            await executeEnemyTurn()
            return
        }

        if move.power == 0 {
            if move.isSelfStatus {
                if let healPercent = move.healPercent {
                    let healAmt = player.maxHP * healPercent / 100
                    player.currentHP = min(player.maxHP, player.currentHP + healAmt)
                    messages.append("\(player.name) restored HP!")
                }
                if move.statusEffect == .sleep {
                    player.status = .sleep
                    player.sleepTurns = 2
                    player.statusTurnsLeft = 2
                    messages.append("\(player.name) went to sleep!")
                }
                state.playerTeam[playerIdx] = player
            } else if let statusEffect = move.statusEffect {
                let statusMsg = BattleEngine.applyStatusEffect(&enemy, statusEffect)
                if !statusMsg.isEmpty { messages.append(statusMsg) }
                state.enemyTeam[enemyIdx] = enemy
            }
        } else {
            let result = BattleEngine.calculateDamage(attacker: player, move: move, defender: enemy)
            if result.effectiveness == 0 {
                messages.append(result.message.isEmpty ? "It doesn't affect \(enemy.name)..." : result.message)
            } else {
                enemy.currentHP = max(0, enemy.currentHP - result.damage)
                if enemy.currentHP == 0 { enemy.isFainted = true }
                state.enemyTeam[enemyIdx] = enemy
                state.totalDamageDealt += result.damage
                if result.isCrit { state.totalCritHits += 1 }
                if result.effectiveness > 1 { state.totalSuperEffective += 1 }
                state.damageByPokemon[player.name, default: 0] += result.damage

                if let triggered = result.abilityTriggered { messages.append(triggered) }
                if !result.message.isEmpty { messages.append(result.message) }

                if BattleEngine.checkStaticTrigger(defender: enemy, move: move) && player.status == nil {
                    let statusMsg = BattleEngine.applyStatusEffect(&player, .paralysis)
                    if !statusMsg.isEmpty { messages.append(statusMsg) }
                    state.playerTeam[playerIdx] = player
                }

                battleState = state
                triggerAnimation(\.isEnemyShaking, duration: 0.4)
                triggerAnimation(\.isEnemyFlashing, duration: 0.6)
                if result.isCrit { triggerAnimation(\.isScreenShaking, duration: 0.5) }
                if result.effectiveness >= 2 { triggerAnimation(\.isScreenShaking, duration: 0.3) }
                showFloatingDamage("-\(result.damage)")
            }
        }

        battleState = state
        await processMessages(messages)

        guard let latest = battleState else { return }
        let currentEnemy = latest.enemyTeam[latest.activeEnemyIndex]
        if currentEnemy.isFainted {
            await processMessages(["\(currentEnemy.name) fainted!"])
            guard var s = battleState else { return }
            if let nextIdx = s.enemyTeam.indices.first(where: { $0 > s.activeEnemyIndex && !s.enemyTeam[$0].isFainted }) {
                let nextEnemy = s.enemyTeam[nextIdx]
                s.activeEnemyIndex = nextIdx
                s.phase = .animating
                battleState = s
                await processMessages(["Opponent sent out \(nextEnemy.name)!"])
                if var s2 = battleState {
                    s2.phase = .menu
                    s2.displayedMessage = "What will \(s2.playerTeam[s2.activePlayerIndex].name) do?"
                    battleState = s2
                }
            } else {
                await endBattle(won: true)
            }
        } else {
            await executeEnemyTurn()
        }
    }

    private func executeEnemyTurn() async {
        guard var state = battleState else { return }
        let enemyIdx = state.activeEnemyIndex
        let playerIdx = state.activePlayerIndex
        var enemy = state.enemyTeam[enemyIdx]
        let player = state.playerTeam[playerIdx]
        guard !enemy.isFainted, !player.isFainted else { return }

        var messages: [String] = []
        let statusResult = BattleEngine.processStatusDamage(&enemy)
        if !statusResult.message.isEmpty { messages.append(statusResult.message) }
        if statusResult.damage > 0 {
            enemy.currentHP = max(0, enemy.currentHP - statusResult.damage)
            if enemy.currentHP == 0 { enemy.isFainted = true }
        }
        if statusResult.cured { enemy.status = nil }
        state.enemyTeam[enemyIdx] = enemy
        state.phase = .enemyTurn
        battleState = state

        if statusResult.shouldSkip {
            await processMessages(messages)
            await executePlayerStatusTurn()
            return
        }

        let move = BattleEngine.chooseEnemyMove(enemy: enemy, player: player)
        messages.append("\(enemy.name) used \(move.name)!")

        let hits = Double.random(in: 0..<100) < Double(move.accuracy)
        var updatedPlayer = player
        if !hits {
            messages.append("\(enemy.name)'s attack missed!")
        } else if move.power > 0 {
            let result = BattleEngine.calculateDamage(attacker: enemy, move: move, defender: player)
            if result.effectiveness == 0 {
                messages.append(result.message.isEmpty ? "It doesn't affect \(player.name)..." : result.message)
            } else {
                updatedPlayer.currentHP = max(0, updatedPlayer.currentHP - result.damage)
                if updatedPlayer.currentHP == 0 { updatedPlayer.isFainted = true }
                state.playerTeam[playerIdx] = updatedPlayer

                if let triggered = result.abilityTriggered { messages.append(triggered) }
                if !result.message.isEmpty { messages.append(result.message) }

                if BattleEngine.checkStaticTrigger(defender: updatedPlayer, move: move) && enemy.status == nil {
                    let statusMsg = BattleEngine.applyStatusEffect(&enemy, .paralysis)
                    if !statusMsg.isEmpty { messages.append(statusMsg) }
                    state.enemyTeam[enemyIdx] = enemy
                }

                triggerAnimation(\.isPlayerShaking, duration: 0.4)
                triggerAnimation(\.isPlayerFlashing, duration: 0.6)
                if result.isCrit { triggerAnimation(\.isScreenShaking, duration: 0.5) }
            }
        } else if let statusEffect = move.statusEffect, !move.isSelfStatus {
            let statusMsg = BattleEngine.applyStatusEffect(&updatedPlayer, statusEffect)
            if !statusMsg.isEmpty { messages.append(statusMsg) }
            state.playerTeam[playerIdx] = updatedPlayer
        }

        if let mi = enemy.moves.firstIndex(where: { $0.name == move.name }) {
            enemy.moves[mi].currentPP = max(0, enemy.moves[mi].currentPP - 1)
        }
        state.enemyTeam[enemyIdx] = enemy
        battleState = state

        await processMessages(messages)

        guard let latest = battleState else { return }
        let latestPlayer = latest.playerTeam[latest.activePlayerIndex]
        if latestPlayer.isFainted {
            await processMessages(["\(latestPlayer.name) fainted!"])
            guard let s = battleState else { return }
            let anyAlive = s.playerTeam.contains { !$0.isFainted }
            if !anyAlive {
                await endBattle(won: false)
            } else {
                battleState?.phase = .switchPokemon
            }
        } else {
            await executePlayerStatusTurn()
        }
    }

    private func executePlayerStatusTurn() async {
        guard var state = battleState else { return }
        let playerIdx = state.activePlayerIndex
        var player = state.playerTeam[playerIdx]
        let statusResult = BattleEngine.processStatusDamage(&player)
        var messages: [String] = []
        if !statusResult.message.isEmpty { messages.append(statusResult.message) }
        if statusResult.damage > 0 {
            player.currentHP = max(0, player.currentHP - statusResult.damage)
            if player.currentHP == 0 { player.isFainted = true }
        }
        if statusResult.cured { player.status = nil }
        state.playerTeam[playerIdx] = player
        battleState = state

        guard !messages.isEmpty else {
            battleState?.phase = .menu
            battleState?.displayedMessage = "What will \(player.name) do?"
            return
        }

        await processMessages(messages)

        if player.isFainted {
            await processMessages(["\(player.name) fainted!"])
            guard let s = battleState else { return }
            let anyAlive = s.playerTeam.contains { !$0.isFainted }
            if !anyAlive {
                await endBattle(won: false)
            } else {
                battleState?.phase = .switchPokemon
            }
        } else {
            battleState?.phase = .menu
            battleState?.displayedMessage = "What will \(player.name) do?"
        }
    }

    /// Mirrors `playerSwitch` in GameContext.tsx. `wasForced` is captured from the state *before*
    /// the active index changes, matching the original's use of the stale outer-scope `battleState`.
    func playerSwitch(_ pokemonIndex: Int) {
        guard let state = battleState else { return }
        guard pokemonIndex < state.playerTeam.count else { return }
        let newPokemon = state.playerTeam[pokemonIndex]
        guard !newPokemon.isFainted, pokemonIndex != state.activePlayerIndex else { return }

        let wasForced = state.phase == .switchPokemon && state.playerTeam[state.activePlayerIndex].isFainted

        battleState?.activePlayerIndex = pokemonIndex
        battleState?.phase = .animating

        Task {
            await processMessages(["Go! \(newPokemon.name)!"])
            if wasForced {
                battleState?.phase = .menu
                battleState?.displayedMessage = "What will \(newPokemon.name) do?"
            } else {
                await executeEnemyTurn()
            }
        }
    }

    /// Mirrors `useItem` in GameContext.tsx.
    func useItem(_ item: Item, at itemIndex: Int) {
        guard var state = battleState else { return }
        let playerIdx = state.activePlayerIndex
        var player = state.playerTeam[playerIdx]
        var messages: [String] = []

        switch item.effect {
        case .heal200:
            let healed = min(player.maxHP - player.currentHP, Int(item.value))
            player.currentHP += healed
            messages.append("\(player.name) recovered \(healed) HP!")
        case .boostAtk:
            player.tempAtkBoost *= item.value
            messages.append("\(player.name)'s attack rose!")
        case .boostDef:
            player.tempDefBoost *= item.value
            messages.append("\(player.name)'s defense rose!")
        case .healHalf, .healFull:
            break // Unimplemented in the original app (no starting item uses these effects).
        }

        state.playerTeam[playerIdx] = player
        state.phase = .animating
        state.itemsUsed += 1
        battleState = state

        if itemIndex < trainerData.items.count {
            trainerData.items[itemIndex].count -= 1
            let name = trainerData.items[itemIndex].name
            if trainerData.items[itemIndex].count <= 0 && name != "Potion" && name != "Super Potion" {
                trainerData.items.remove(at: itemIndex)
            }
            saveTrainer()
        }

        Task {
            await processMessages(messages)
            await executeEnemyTurn()
        }
    }

    /// Mirrors `runFromBattle` in GameContext.tsx.
    func runFromBattle() {
        guard let state = battleState else { return }
        let escapeChance = 0.6 + Double.random(in: 0..<1) * 0.4
        let playerSpd = Double(state.playerTeam[state.activePlayerIndex].spd)
        let enemySpd = Double(state.enemyTeam[state.activeEnemyIndex].spd)
        let odds = min(0.95, (playerSpd / (enemySpd + 1)) * escapeChance)
        let escaped = Double.random(in: 0..<1) < odds
        let enemyName = state.enemyTeam[state.activeEnemyIndex].name

        Task {
            if escaped {
                await processMessages(["Got away safely!"])
                battleState = nil
                navigate(.title)
            } else {
                await processMessages(["Can't escape!", "\(enemyName) blocks the way!"])
                battleState?.phase = .menu
            }
        }
    }

    func acknowledgeBattleEnd() {
        battleState = nil
    }
}
