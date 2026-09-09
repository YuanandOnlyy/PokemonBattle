import SwiftUI

/// Mirrors `DefeatScreen.tsx`.
struct DefeatScreenView: View {
    var viewModel: GameViewModel
    @State private var titleOffset: CGFloat = -16
    @State private var titleOpacity: Double = 0

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
            withAnimation(.easeOut(duration: 0.5)) {
                titleOffset = 0
                titleOpacity = 1
            }
        }
    }

    private func content(_ result: BattleResult) -> some View {
        let trainer = viewModel.trainerData
        let totalXP = result.xpGained.reduce(0) { $0 + $1.amount }
        let winRate = trainer.totalBattles > 0 ? Int((Double(trainer.wins) / Double(trainer.totalBattles) * 100).rounded()) : 0

        return ScrollView {
            VStack(spacing: 10) {
                VStack(spacing: 4) {
                    Text("\u{2717} \u{2717} \u{2717} \u{2717} \u{2717} \u{2717} \u{2717} \u{2717}")
                        .pixelText(7, Color(hex: "#c04000"))
                        .tracking(3)
                    Text("DEFEATED...")
                        .font(.pixel(26))
                        .foregroundStyle(Color(hex: "#8b2200"))
                        .multilineTextAlignment(.center)
                        .shadow(color: Color(hex: "#3a0f00"), radius: 0, x: 3, y: 3)
                    Text("ALL POKEMON FAINTED").pixelText(9, Color(hex: "#c04000")).tracking(1)
                }
                .padding(.top, 12)
                .offset(y: titleOffset)
                .opacity(titleOpacity)

                HStack(spacing: 10) {
                    ForEach(result.xpGained) { entry in
                        VStack(spacing: 2) {
                            OfficialSpriteView(id: PokemonNameLookup.id(for: entry.name), width: 56, height: 56)
                                .saturation(0)
                                .brightness(-0.4)
                                .opacity(0.6)
                            Text("FNT").pixelText(6, Color(hex: "#8b2200"))
                        }
                    }
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(Color(hex: "#1a0700"))
                .overlay(Rectangle().stroke(Color(hex: "#3a0f00"), lineWidth: 3))
                .staggerAppear(0)

                if let tip = result.tip {
                    VStack(alignment: .leading, spacing: 5) {
                        Text("\u{1F4A1} BATTLE TIP").pixelText(7, Color(hex: "#c0a000"))
                        Text(tip).font(.pixel(7)).foregroundStyle(Color(hex: "#a08040")).lineSpacing(6)
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .frame(maxWidth: 340, alignment: .leading)
                    .background(Color(hex: "#1a1a00"))
                    .overlay(Rectangle().stroke(Color(hex: "#8b6000"), lineWidth: 3))
                    .staggerAppear(1)
                }

                xpSection(result, totalXP: totalXP).staggerAppear(2)
                recordSection(trainer, winRate: winRate).staggerAppear(3)

                VStack(spacing: 8) {
                    Button("\u{2694} TRY AGAIN") {
                        viewModel.acknowledgeBattleEnd()
                        viewModel.navigate(.teamBuilder)
                    }
                    .buttonStyle(RetroButtonStyle(skin: skin, fontSize: 11))

                    Button("\u{1F3E0} MAIN MENU") {
                        viewModel.acknowledgeBattleEnd()
                        viewModel.navigate(.title)
                    }
                    .buttonStyle(RetroButtonStyle(skin: skin, dark: true, fontSize: 11))
                }
                .frame(maxWidth: 340)
                .padding(.bottom, 16)
                .staggerAppear(4)
            }
            .padding(.horizontal, 14)
            .frame(maxWidth: .infinity)
        }
        .background(Color(hex: "#071a07"))
    }

    private func xpSection(_ result: BattleResult, totalXP: Int) -> some View {
        VStack(spacing: 6) {
            Text("EXPERIENCE GAINED")
                .pixelText(9, skin.medium)
                .padding(.bottom, 6)
                .overlay(Rectangle().fill(Color(hex: "#3a1f00")).frame(height: 2), alignment: .bottom)

            ForEach(result.xpGained) { entry in
                HStack {
                    Text(entry.name.uppercased()).pixelText(8, Color(hex: "#8b7070"))
                    Spacer()
                    Text("+\(entry.amount) XP").pixelText(8, skin.medium)
                }
            }

            HStack {
                Text("TOTAL").pixelText(8, Color(hex: "#8b7070"))
                Spacer()
                Text("+\(totalXP)").pixelText(8, skin.medium)
            }
            .padding(.top, 6)
            .overlay(Rectangle().fill(Color(hex: "#3a1f00")).frame(height: 2), alignment: .top)
        }
        .padding(12)
        .frame(maxWidth: 340)
        .background(Color(hex: "#1a0f00"))
        .overlay(Rectangle().stroke(Color(hex: "#3a1f00"), lineWidth: 4))
    }

    private func recordSection(_ trainer: TrainerData, winRate: Int) -> some View {
        VStack(spacing: 6) {
            Text("BATTLE RECORD")
                .pixelText(9, skin.medium)
                .padding(.bottom, 6)
                .overlay(Rectangle().fill(Color(hex: "#3a1f00")).frame(height: 2), alignment: .bottom)

            statRow("LOSSES", "\(trainer.losses)", highlight: true)
            statRow("WINS", "\(trainer.wins)")
            statRow("WIN RATE", "\(winRate)%")
            statRow("TOTAL BATTLES", "\(trainer.totalBattles)")

            if trainer.consecutiveDefeats == 0 {
                Text("\u{1F381} BONUS POTION RECEIVED!")
                    .pixelText(8, skin.medium)
                    .padding(6)
                    .frame(maxWidth: .infinity)
                    .background(Color(hex: "#0f380f"))
                    .overlay(Rectangle().stroke(skin.dark, lineWidth: 2))
                    .padding(.top, 4)
            }
        }
        .padding(12)
        .frame(maxWidth: 340)
        .background(Color(hex: "#1a0f00"))
        .overlay(Rectangle().stroke(Color(hex: "#3a1f00"), lineWidth: 4))
    }

    private func statRow(_ label: String, _ value: String, highlight: Bool = false) -> some View {
        HStack {
            Text(label).pixelText(8, Color(hex: "#8bac0f"))
            Spacer()
            Text(value).pixelText(8, highlight ? Color(hex: "#c04000") : Color(hex: "#e0f8d0"))
        }
    }
}
