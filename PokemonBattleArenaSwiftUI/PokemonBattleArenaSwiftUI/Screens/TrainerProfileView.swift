import SwiftUI

/// Mirrors `TrainerProfile.tsx`: editable trainer name, level/rank, battle record, combat stats,
/// and an achievements mini-grid.
struct TrainerProfileView: View {
    var viewModel: GameViewModel

    @State private var editingName = false
    @State private var nameInput = ""

    private var skin: SkinColors { viewModel.trainerData.settings.consoleSkin.colors }
    private var trainer: TrainerData { viewModel.trainerData }

    private var winRate: Int {
        trainer.totalBattles > 0 ? Int((Double(trainer.wins) / Double(trainer.totalBattles) * 100).rounded()) : 0
    }

    private var favoriteEntry: (name: String, count: Int)? {
        trainer.favoritePokemons.max { $0.value < $1.value }.map { (name: $0.key, count: $0.value) }
    }

    private var favoriteID: Int? {
        favoriteEntry.map { PokemonNameLookup.id(for: $0.name) }
    }

    private var rank: String {
        switch trainer.level {
        case 50...: return "CHAMPION"
        case 30..<50: return "ELITE FOUR"
        case 20..<30: return "GYM LEADER"
        case 10..<20: return "ACE TRAINER"
        case 5..<10: return "POKEFAN"
        default: return "ROOKIE"
        }
    }

    private var unlockedAchievements: Int { trainer.achievements.filter(\.unlocked).count }

    var body: some View {
        VStack(spacing: 0) {
            header.staggerAppear(0)
            ScrollView {
                VStack(spacing: 10) {
                    heroCard.staggerAppear(1)
                    battleRecordCard.staggerAppear(2)
                    combatStatsCard.staggerAppear(3)
                    achievementsGridCard.staggerAppear(4)
                }
                .padding(10)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .background(skin.medium)
        .onAppear { nameInput = trainer.name }
    }

    private var header: some View {
        HStack(spacing: 8) {
            Button {
                viewModel.navigate(.title)
            } label: {
                Text("\u{25C0}").font(.pixel(12)).foregroundStyle(skin.lightest)
            }
            .buttonStyle(.plain)
            Text("TRAINER PROFILE").pixelText(10, skin.lightest)
            Spacer()
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .background(skin.darkest)
        .overlay(Rectangle().fill(skin.dark).frame(height: 4), alignment: .bottom)
    }

    private var heroCard: some View {
        HStack(spacing: 12) {
            ZStack(alignment: .bottom) {
                if let favoriteID {
                    OfficialSpriteView(id: favoriteID, width: 60, height: 60)
                        .brightness(-0.15)
                } else {
                    Text("\u{1F9E2}").font(.system(size: 28))
                }
                Text(rank)
                    .font(.pixel(5))
                    .foregroundStyle(skin.darkest)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 1)
                    .background(skin.medium)
            }
            .frame(width: 76, height: 76)
            .background(skin.dark)
            .overlay(Rectangle().stroke(skin.medium, lineWidth: 4))

            VStack(alignment: .leading, spacing: 4) {
                if editingName {
                    HStack(spacing: 4) {
                        TextField("", text: $nameInput)
                            .font(.pixel(10))
                            .foregroundStyle(skin.darkest)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 4)
                            .background(skin.light)
                            .overlay(Rectangle().stroke(skin.medium, lineWidth: 3))
                            .onChange(of: nameInput) { _, newValue in
                                let limited = String(newValue.prefix(10)).uppercased()
                                if limited != nameInput { nameInput = limited }
                            }
                            .onSubmit { saveName() }

                        Button("OK") { saveName() }
                            .font(.pixel(8))
                            .foregroundStyle(skin.darkest)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(skin.medium)
                            .overlay(Rectangle().stroke(skin.lightest, lineWidth: 3))
                            .buttonStyle(.plain)
                    }
                } else {
                    Button {
                        nameInput = trainer.name
                        editingName = true
                    } label: {
                        Text(trainer.name + " \u{270E}").font(.pixel(14)).foregroundStyle(skin.lightest)
                    }
                    .buttonStyle(.plain)
                }

                Text("LEVEL \(trainer.level) \(rank)").pixelText(8, skin.medium)
                Text("XP: \(trainer.xp)/\(trainer.xpToNext)").font(.pixel(6)).foregroundStyle(skin.dark)
                XPBarView(current: trainer.xp, max: trainer.xpToNext, skin: skin)
            }
        }
        .padding(12)
        .background(skin.darkest)
        .overlay(Rectangle().stroke(skin.dark, lineWidth: 4))
    }

    private var battleRecordCard: some View {
        VStack(spacing: 6) {
            Text("\u{2694} BATTLE RECORD")
                .pixelText(9, skin.darkest)
                .padding(.bottom, 6)
                .overlay(Rectangle().fill(skin.medium).frame(height: 2), alignment: .bottom)

            if trainer.totalBattles > 0 {
                VStack(spacing: 2) {
                    HStack {
                        Text("WIN RATE").pixelText(7, skin.dark)
                        Spacer()
                        Text("\(winRate)%").pixelText(7, skin.darkest)
                    }
                    GeometryReader { geo in
                        ZStack(alignment: .leading) {
                            Rectangle().fill(Color(hex: "#c04000"))
                            Rectangle().fill(skin.dark).frame(width: geo.size.width * Double(winRate) / 100)
                        }
                    }
                    .frame(height: 10)
                    .overlay(Rectangle().stroke(skin.darkest, lineWidth: 2))
                }
                .padding(.bottom, 6)
            }

            statRow("WINS", "\(trainer.wins)", accent: true)
            statRow("LOSSES", "\(trainer.losses)")
            statRow("STREAK", "\(trainer.streak)")
            statRow("BEST STREAK", "\(trainer.bestStreak)", accent: true)
            statRow("TOTAL BATTLES", "\(trainer.totalBattles)")
        }
        .padding(10)
        .background(skin.lightest)
        .overlay(Rectangle().stroke(skin.darkest, lineWidth: 4))
    }

    private var combatStatsCard: some View {
        VStack(spacing: 6) {
            Text("\u{1F4CA} COMBAT STATS")
                .pixelText(9, skin.darkest)
                .padding(.bottom, 6)
                .overlay(Rectangle().fill(skin.medium).frame(height: 2), alignment: .bottom)

            statRow("DAMAGE DEALT", "\(trainer.totalDamageDealt)")
            statRow("CRITICAL HITS", "\(trainer.totalCritHits)")
            statRow("ACHIEVEMENTS", "\(unlockedAchievements)/\(trainer.achievements.count)", accent: true)

            if let favoriteEntry, let favoriteID {
                HStack {
                    Text("FAVORITE").pixelText(8, skin.dark)
                    Spacer()
                    HStack(spacing: 6) {
                        OfficialSpriteView(id: favoriteID, width: 28, height: 28)
                        Text(favoriteEntry.name.uppercased()).pixelText(8, skin.darkest)
                    }
                }
            }
        }
        .padding(10)
        .background(skin.lightest)
        .overlay(Rectangle().stroke(skin.darkest, lineWidth: 4))
    }

    private var achievementsGridCard: some View {
        VStack(spacing: 8) {
            Text("\u{1F3C6} ACHIEVEMENTS")
                .pixelText(9, skin.darkest)
                .padding(.bottom, 6)
                .overlay(Rectangle().fill(skin.medium).frame(height: 2), alignment: .bottom)

            FlowLayout(spacing: 6, lineSpacing: 6) {
                ForEach(trainer.achievements) { achievement in
                    Text(achievement.unlocked ? "\u{2605}" : "\u{2606}")
                        .font(.system(size: 16))
                        .frame(width: 36, height: 36)
                        .background(achievement.unlocked ? Color(hex: "#c0a000") : skin.medium)
                        .overlay(Rectangle().stroke(achievement.unlocked ? skin.darkest : skin.dark, lineWidth: 3))
                        .opacity(achievement.unlocked ? 1 : 0.35)
                }
            }

            Text("\(unlockedAchievements) OF \(trainer.achievements.count) UNLOCKED")
                .pixelText(7, skin.dark)
        }
        .padding(10)
        .background(skin.lightest)
        .overlay(Rectangle().stroke(skin.darkest, lineWidth: 4))
    }

    private func statRow(_ label: String, _ value: String, accent: Bool = false) -> some View {
        HStack {
            Text(label).pixelText(8, skin.dark)
            Spacer()
            Text(value).pixelText(9, accent ? Color(hex: "#c0a000") : skin.darkest)
        }
    }

    private func saveName() {
        let trimmed = nameInput.trimmingCharacters(in: .whitespacesAndNewlines).uppercased()
        let final = trimmed.isEmpty ? "TRAINER" : String(trimmed.prefix(10))
        viewModel.updateTrainer { $0.name = final }
        editingName = false
    }
}
