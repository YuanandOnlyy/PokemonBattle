import SwiftUI

/// Static Pokemon-name -> PokeAPI-id lookup for the MVP artwork. Mirrors the `POKEMON_IDS` map
/// duplicated in both VictoryScreen.tsx and DefeatScreen.tsx.
enum PokemonNameLookup {
    static let ids: [String: Int] = [
        "pikachu": 25, "raichu": 26, "charizard": 6, "charmander": 4, "blastoise": 9, "squirtle": 7,
        "venusaur": 3, "bulbasaur": 1, "gengar": 94, "haunter": 93, "lucario": 448, "riolu": 447,
        "garchomp": 445, "gabite": 444, "greninja": 658, "froakie": 656,
        "eevee": 133, "snorlax": 143, "dragonite": 149, "mewtwo": 150,
    ]

    static func id(for name: String) -> Int {
        ids[name.lowercased()] ?? 25
    }
}

/// Mirrors `VictoryScreen.tsx`.
struct VictoryScreenView: View {
    var viewModel: GameViewModel
    @State private var showLevelUp = false

    private var skin: SkinColors { viewModel.trainerData.settings.consoleSkin.colors }

    var body: some View {
        Group {
            if let result = viewModel.battleResult {
                content(result)
            } else {
                Color.clear.onAppear { viewModel.navigate(.title) }
            }
        }
        .task {
            try? await Task.sleep(nanoseconds: 800_000_000)
            showLevelUp = true
        }
    }

    private func content(_ result: BattleResult) -> some View {
        let totalXP = result.xpGained.reduce(0) { $0 + $1.amount }
        let mvpID = result.mvpPokemon.map(PokemonNameLookup.id(for:))

        return ScrollView {
            VStack(spacing: 10) {
                VStack(spacing: 4) {
                    Text("VICTORY!")
                        .font(.pixel(26))
                        .foregroundStyle(skin.lightest)
                        .shadow(color: skin.dark, radius: 0, x: 3, y: 3)
                    Text("\u{2605}\u{2605}\u{2605} \u{2605}\u{2605}\u{2605}").pixelText(11, skin.medium).tracking(3)
                }
                .padding(.top, 8)

                Text((result.enemyDefeated?.uppercased() ?? "ENEMY") + " DEFEATED!")
                    .pixelText(9, skin.lightest)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 6)
                    .background(skin.dark)
                    .overlay(Rectangle().stroke(skin.medium, lineWidth: 3))

                if let mvpName = result.mvpPokemon, let mvpID {
                    HStack(spacing: 8) {
                        OfficialSpriteView(id: mvpID, width: 40, height: 40)
                        VStack(alignment: .leading, spacing: 2) {
                            Text("\u{1F3C6} BATTLE MVP").pixelText(7, skin.accent)
                            Text(mvpName.uppercased()).pixelText(10, skin.lightest)
                        }
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .frame(maxWidth: 340, alignment: .leading)
                    .background(skin.darkest)
                    .overlay(Rectangle().stroke(skin.accent, lineWidth: 3))
                }

                xpSection(result, totalXP: totalXP)
                statsSection

                VStack(spacing: 8) {
                    Button("\u{2694} REMATCH") {
                        viewModel.acknowledgeBattleEnd()
                        viewModel.navigate(.teamBuilder)
                    }
                    .buttonStyle(RetroButtonStyle(skin: skin, fontSize: 11))

                    HStack(spacing: 8) {
                        Button("\u{1F4DC} HISTORY") {
                            viewModel.acknowledgeBattleEnd()
                            viewModel.navigate(.battleHistory)
                        }
                        .buttonStyle(RetroButtonStyle(skin: skin, fontSize: 9))

                        Button("\u{1F3E0} MENU") {
                            viewModel.acknowledgeBattleEnd()
                            viewModel.navigate(.title)
                        }
                        .buttonStyle(RetroButtonStyle(skin: skin, dark: true, fontSize: 9))
                    }
                }
                .frame(maxWidth: 340)
                .padding(.bottom, 12)
            }
            .padding(.horizontal, 14)
            .frame(maxWidth: .infinity)
        }
        .background(skin.darkest)
    }

    private func xpSection(_ result: BattleResult, totalXP: Int) -> some View {
        VStack(spacing: 10) {
            Text("\u{2B50} EXPERIENCE GAINED")
                .pixelText(9, skin.lightest)
                .padding(.bottom, 6)
                .overlay(Rectangle().fill(skin.medium).frame(height: 2), alignment: .bottom)

            ForEach(result.xpGained) { entry in
                let leveled = result.levelUps.contains(entry.name)
                VStack(spacing: 3) {
                    HStack {
                        Text(entry.name.uppercased() + (leveled ? " \u{25B2}" : ""))
                            .pixelText(9, leveled ? skin.accent : skin.lightest)
                        Spacer()
                        Text("+\(entry.amount) XP").pixelText(9, skin.light)
                    }
                    XPBarView(current: entry.amount, max: 200, skin: skin)
                    if leveled && showLevelUp {
                        Text("\u{2B06} LEVEL UP!")
                            .pixelText(9, skin.accent)
                            .padding(4)
                            .frame(maxWidth: .infinity)
                            .background(skin.darkest)
                            .overlay(Rectangle().stroke(skin.accent, lineWidth: 2))
                    }
                }
            }

            HStack {
                Text("TOTAL XP").pixelText(8, skin.medium)
                Spacer()
                Text("+\(totalXP)").pixelText(8, skin.accent)
            }
            .padding(.top, 8)
            .overlay(Rectangle().fill(skin.medium).frame(height: 2), alignment: .top)
        }
        .padding(12)
        .frame(maxWidth: 340)
        .background(skin.dark)
        .overlay(Rectangle().stroke(skin.medium, lineWidth: 4))
    }

    private var statsSection: some View {
        let trainer = viewModel.trainerData
        let winRate = trainer.totalBattles > 0 ? Int((Double(trainer.wins) / Double(trainer.totalBattles) * 100).rounded()) : 0
        return VStack(spacing: 5) {
            Text("\u{1F4CA} BATTLE RECORD")
                .pixelText(9, skin.lightest)
                .padding(.bottom, 6)
                .overlay(Rectangle().fill(skin.medium).frame(height: 2), alignment: .bottom)
            statRow("WINS", "\(trainer.wins)")
            statRow("WIN STREAK", "\(trainer.streak)")
            statRow("BEST STREAK", "\(trainer.bestStreak)")
            statRow("WIN RATE", "\(winRate)%")
        }
        .padding(12)
        .frame(maxWidth: 340)
        .background(skin.dark)
        .overlay(Rectangle().stroke(skin.medium, lineWidth: 4))
    }

    private func statRow(_ label: String, _ value: String) -> some View {
        HStack {
            Text(label).pixelText(8, skin.medium)
            Spacer()
            Text(value).pixelText(8, skin.lightest)
        }
    }
}
