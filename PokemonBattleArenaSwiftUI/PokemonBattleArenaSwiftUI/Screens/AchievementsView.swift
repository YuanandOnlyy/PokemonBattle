import SwiftUI

/// Mirrors `Achievements.tsx`.
struct AchievementsView: View {
    var viewModel: GameViewModel
    @State private var selectedID: String?

    private static let icons: [String: String] = [
        "first_battle": "\u{1F3AE}", "first_win": "\u{1F3C6}", "win_streak_3": "\u{1F525}",
        "win_10": "\u{2694}", "crit_master": "\u{1F4A5}", "all_pokemon": "\u{1F4D6}",
    ]
    private static let colors: [String: Color] = [
        "first_battle": Color(hex: "#306230"), "first_win": Color(hex: "#c0a000"),
        "win_streak_3": Color(hex: "#c04000"), "win_10": Color(hex: "#6040c0"),
        "crit_master": Color(hex: "#c06000"), "all_pokemon": Color(hex: "#0060c0"),
    ]

    private var skin: SkinColors { viewModel.trainerData.settings.consoleSkin.colors }
    private var achievements: [Achievement] { viewModel.trainerData.achievements }
    private var unlocked: Int { achievements.filter(\.unlocked).count }

    var body: some View {
        VStack(spacing: 0) {
            header.staggerAppear(0)
            progressSummary.staggerAppear(1)
            ScrollView {
                VStack(spacing: 8) {
                    ForEach(Array(achievements.enumerated()), id: \.element.id) { index, achievement in
                        achievementCard(achievement).staggerAppear(2 + index)
                    }
                    if unlocked == achievements.count {
                        allUnlockedBanner.staggerAppear(2 + achievements.count)
                    }
                }
                .padding(10)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .background(skin.medium)
    }

    private var header: some View {
        HStack(spacing: 8) {
            Button {
                viewModel.navigate(.title)
            } label: {
                Text("\u{25C0}").font(.pixel(12)).foregroundStyle(skin.lightest)
            }
            .buttonStyle(.plain)
            Text("ACHIEVEMENTS").pixelText(10, skin.lightest)
            Spacer()
            Text("\(unlocked)/\(achievements.count)").pixelText(8, Color(hex: "#c0a000"))
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .background(skin.darkest)
        .overlay(Rectangle().fill(skin.dark).frame(height: 4), alignment: .bottom)
    }

    private var progressSummary: some View {
        HStack {
            VStack(alignment: .leading, spacing: 3) {
                Text("COMPLETION").pixelText(7, skin.light)
                GeometryReader { geo in
                    let pct = achievements.isEmpty ? 0 : Double(unlocked) / Double(achievements.count)
                    ZStack(alignment: .leading) {
                        Rectangle().fill(skin.darkest)
                        Rectangle().fill(Color(hex: "#c0a000")).frame(width: geo.size.width * pct)
                    }
                }
                .frame(width: 200, height: 8)
                .overlay(Rectangle().stroke(skin.darkest, lineWidth: 2))
            }
            Spacer()
            VStack(alignment: .trailing, spacing: 2) {
                Text("BONUS XP").pixelText(7, skin.light)
                Text("+\(unlocked * 50)").pixelText(9, Color(hex: "#c0a000"))
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(skin.dark)
        .overlay(Rectangle().fill(skin.darkest).frame(height: 3), alignment: .bottom)
    }

    private func achievementCard(_ achievement: Achievement) -> some View {
        let icon = Self.icons[achievement.id] ?? "\u{1F3C5}"
        let accent = Self.colors[achievement.id] ?? skin.dark
        let progressPct = achievement.target > 0 ? min(1, Double(achievement.progress) / Double(achievement.target)) : 0
        let isSelected = selectedID == achievement.id

        return VStack(alignment: .leading, spacing: 4) {
            HStack(alignment: .top, spacing: 8) {
                Text(icon).font(.system(size: 20))
                VStack(alignment: .leading, spacing: 2) {
                    HStack {
                        Text(achievement.name.uppercased())
                            .pixelText(9, achievement.unlocked ? accent : skin.medium)
                        Spacer()
                        Text(achievement.unlocked ? "\u{2605}" : "\u{2606}")
                            .foregroundStyle(achievement.unlocked ? Color(hex: "#c0a000") : skin.dark)
                            .font(.system(size: 14))
                    }
                    Text(achievement.description)
                        .font(.pixel(7))
                        .foregroundStyle(achievement.unlocked ? skin.dark : Color(hex: "#6a8a6a"))
                }
            }

            if !achievement.unlocked {
                VStack(spacing: 2) {
                    HStack {
                        Text(achievement.unlockCondition).font(.pixel(6)).foregroundStyle(Color(hex: "#6a8a6a"))
                        Spacer()
                        Text("\(achievement.progress)/\(achievement.target)").font(.pixel(6)).foregroundStyle(skin.medium)
                    }
                    GeometryReader { geo in
                        ZStack(alignment: .leading) {
                            Rectangle().fill(skin.darkest)
                            Rectangle().fill(skin.medium).frame(width: geo.size.width * progressPct)
                        }
                    }
                    .frame(height: 8)
                    .overlay(Rectangle().stroke(skin.darkest, lineWidth: 2))
                }
                .padding(.top, 4)
            } else {
                HStack {
                    Text("\u{2713} UNLOCKED").pixelText(7, accent)
                    Spacer()
                    if let date = achievement.unlockedDate {
                        Text(date).pixelText(6, skin.dark)
                    }
                }
                .padding(.top, 4)
                .overlay(Rectangle().fill(accent).frame(height: 2), alignment: .top)

                if isSelected {
                    Text("\(achievement.unlockCondition) \u{2014} COMPLETED! +50 BONUS XP EARNED")
                        .font(.pixel(7))
                        .foregroundStyle(skin.dark)
                        .padding(6)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(Color(hex: "#d0ead0"))
                        .overlay(Rectangle().stroke(skin.medium, lineWidth: 2))
                        .padding(.top, 4)
                }
            }
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 8)
        .background(achievement.unlocked ? skin.lightest : Color(hex: "#1a2a1a"))
        .overlay(Rectangle().stroke(achievement.unlocked ? accent : skin.dark, lineWidth: 4))
        .opacity(achievement.unlocked ? 1 : 0.8)
        .onTapGesture {
            selectedID = isSelected ? nil : achievement.id
        }
    }

    private var allUnlockedBanner: some View {
        VStack(spacing: 4) {
            Text("\u{1F3C6} MASTER TRAINER! \u{1F3C6}").pixelText(10, skin.darkest)
            Text("ALL ACHIEVEMENTS UNLOCKED").pixelText(7, skin.dark)
        }
        .padding(.vertical, 12)
        .frame(maxWidth: .infinity)
        .background(Color(hex: "#c0a000"))
        .overlay(Rectangle().stroke(skin.darkest, lineWidth: 4))
    }
}
