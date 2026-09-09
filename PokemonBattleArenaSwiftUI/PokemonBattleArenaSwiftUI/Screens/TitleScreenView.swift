import SwiftUI

/// Mirrors `TitleScreen.tsx`: main menu, trainer HUD, rotating Pokemon showcase, and the
/// collapsible daily-quests banner.
struct TitleScreenView: View {
    var viewModel: GameViewModel

    private enum MenuAction: Hashable {
        case newBattle
        case continueLast
        case screen(Screen)
    }

    private static let menuItems: [(icon: String, label: String, action: MenuAction)] = [
        ("\u{2694}", "NEW BATTLE", .newBattle),
        ("\u{25B6}", "CONTINUE", .continueLast),
        ("\u{1F4D6}", "POKEDEX", .screen(.pokedex)),
        ("\u{1F3C6}", "ACHIEVEMENTS", .screen(.achievements)),
        ("\u{1F464}", "TRAINER", .screen(.trainerProfile)),
        ("\u{2699}", "SETTINGS", .screen(.settings)),
    ]

    private static let showcasePokemon = [25, 6, 150, 9, 149, 94]

    @State private var showcaseIndex = 0
    @State private var showQuests = false

    private var skin: SkinColors { viewModel.trainerData.settings.consoleSkin.colors }

    var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                hud.staggerAppear(0)
                titleBlock.staggerAppear(1)
                showcase.staggerAppear(2)
                showcaseDots.staggerAppear(2)
                pressStart.staggerAppear(3)
                menu.staggerAppear(4)
                questsBanner.staggerAppear(5)
                footer.staggerAppear(6)
            }
        }
        .background(skin.medium)
        .task {
            // Runs for as long as this view stays on screen; SwiftUI cancels it automatically
            // when the Title screen is navigated away from, so it doesn't restart on every
            // unrelated body re-evaluation the way a stored Combine Timer would.
            while !Task.isCancelled {
                try? await Task.sleep(nanoseconds: 2_400_000_000)
                guard !Task.isCancelled else { break }
                showcaseIndex = (showcaseIndex + 1) % Self.showcasePokemon.count
            }
        }
    }

    private var hud: some View {
        HStack {
            Text(viewModel.trainerData.name + (viewModel.trainerData.streak >= 3 ? " \u{1F525}" : ""))
                .pixelText(7, skin.medium)
            Spacer()
            HStack(spacing: 10) {
                let unlocked = viewModel.trainerData.achievements.filter(\.unlocked).count
                let total = viewModel.trainerData.achievements.count
                if unlocked < total {
                    Text("\u{1F3C6}\(unlocked)/\(total)").pixelText(6, skin.accent)
                }
                Text("LV.\(viewModel.trainerData.level)").pixelText(7, skin.medium)
            }
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(skin.darkest)
    }

    private var titleBlock: some View {
        VStack(spacing: 4) {
            Text("\u{2605} \u{2605} \u{2605} \u{2605} \u{2605} \u{2605} \u{2605} \u{2605}")
                .pixelText(7, skin.medium)
                .tracking(4)
            Text("POKEMON")
                .font(.pixel(26))
                .foregroundStyle(skin.lightest)
                .tracking(2)
                .shadow(color: skin.dark, radius: 0, x: 4, y: 4)
            Text("GAME BOY BATTLE ARENA")
                .pixelText(8, skin.light)
                .tracking(1)
        }
        .padding(.vertical, 10)
        .frame(maxWidth: .infinity)
        .background(skin.darkest)
        .overlay(Rectangle().fill(skin.dark).frame(height: 6), alignment: .bottom)
    }

    private var showcase: some View {
        ZStack {
            OfficialSpriteView(id: Self.showcasePokemon[(showcaseIndex + 2) % Self.showcasePokemon.count], width: 48, height: 48)
                .opacity(0.4)
                .frame(maxWidth: .infinity, alignment: .leading)
            OfficialSpriteView(id: Self.showcasePokemon[(showcaseIndex + 4) % Self.showcasePokemon.count], width: 48, height: 48)
                .opacity(0.4)
                .frame(maxWidth: .infinity, alignment: .trailing)
            OfficialSpriteView(id: Self.showcasePokemon[showcaseIndex], width: 110, height: 110)
                .id(showcaseIndex)
                .transition(.scale.combined(with: .opacity))
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 6)
        .frame(maxWidth: .infinity)
        .background(LinearGradient(colors: [skin.darkest, skin.dark], startPoint: .top, endPoint: .bottom))
        .animation(.easeOut(duration: 0.4), value: showcaseIndex)
    }

    private var showcaseDots: some View {
        HStack(spacing: 6) {
            ForEach(Self.showcasePokemon.indices, id: \.self) { i in
                Rectangle()
                    .fill(i == showcaseIndex ? skin.lightest : skin.medium)
                    .frame(width: i == showcaseIndex ? 10 : 6, height: 6)
                    .animation(.easeInOut(duration: 0.3), value: showcaseIndex)
            }
        }
        .padding(.vertical, 4)
        .frame(maxWidth: .infinity)
        .background(skin.dark)
        .overlay(Rectangle().fill(skin.darkest).frame(height: 3), alignment: .bottom)
    }

    private var pressStart: some View {
        BlinkingText("\u{25B6} PRESS START \u{25C0}", size: 9, color: skin.darkest)
            .padding(.vertical, 6)
            .frame(maxWidth: .infinity)
            .background(skin.light)
            .overlay(Rectangle().fill(skin.darkest).frame(height: 3), alignment: .bottom)
    }

    private var menu: some View {
        VStack(spacing: 0) {
            Text("MAIN MENU")
                .pixelText(8, skin.light)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 10)
                .padding(.vertical, 5)
                .background(skin.darkest)

            ForEach(Array(Self.menuItems.enumerated()), id: \.offset) { index, item in
                let continueDisabled = item.action == .continueLast && viewModel.trainerData.lastTeamIDs.count < 3
                Button {
                    guard !continueDisabled else { return }
                    switch item.action {
                    case .newBattle:
                        viewModel.openTeamBuilder(continueLast: false)
                    case .continueLast:
                        viewModel.openTeamBuilder(continueLast: true)
                    case .screen(let screen):
                        viewModel.navigate(screen)
                    }
                } label: {
                    HStack(spacing: 10) {
                        Text(item.icon).font(.system(size: 12)).frame(width: 20)
                        Text(item.label).font(.pixel(10))
                        if continueDisabled {
                            Spacer()
                            Text("NO SAVE").font(.pixel(7)).foregroundStyle(skin.dark)
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 9)
                    .foregroundStyle(continueDisabled ? skin.dark : skin.darkest)
                }
                .buttonStyle(.plain)
                .disabled(continueDisabled)
                .overlay(Rectangle().fill(skin.medium).frame(height: index < Self.menuItems.count - 1 ? 2 : 0), alignment: .bottom)
            }
        }
        .background(skin.lightest)
        .overlay(Rectangle().stroke(skin.darkest, lineWidth: 4))
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .frame(maxWidth: .infinity)
    }

    @ViewBuilder
    private var questsBanner: some View {
        let quests = viewModel.trainerData.dailyQuests
        if !quests.isEmpty {
            let completed = quests.filter(\.completed).count
            Button {
                showQuests.toggle()
            } label: {
                HStack {
                    Text("\u{1F4CB} DAILY QUESTS").pixelText(7, skin.lightest)
                    Spacer()
                    Text("\(completed)/\(quests.count) \u{25BC}")
                        .pixelText(7, completed == quests.count ? skin.accent : skin.medium)
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
            }
            .buttonStyle(.plain)
            .background(skin.dark)
            .overlay(Rectangle().fill(skin.darkest).frame(height: 3), alignment: .top)

            if showQuests {
                VStack(spacing: 0) {
                    ForEach(quests) { quest in
                        HStack {
                            Text((quest.completed ? "\u{2713} " : "\u{25CB} ") + quest.description.uppercased())
                                .pixelText(6, quest.completed ? skin.accent : skin.medium)
                                .strikethrough(quest.completed)
                            Spacer()
                            Text("+\(quest.rewardXP)XP").pixelText(6, skin.dark)
                        }
                        .padding(.vertical, 4)
                        .overlay(Rectangle().fill(skin.dark).frame(height: 1), alignment: .bottom)
                    }
                }
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
                .background(skin.darkest)
                .overlay(Rectangle().fill(skin.dark).frame(height: 2), alignment: .top)
            }
        }
    }

    private var footer: some View {
        HStack {
            Text("\u{00A9} FAN GAME").pixelText(6, skin.dark)
            Spacer()
            Button {
                viewModel.navigate(.battleHistory)
            } label: {
                Text("HISTORY").pixelText(6, skin.light)
            }
            .buttonStyle(.plain)
            Spacer()
            Text("W:\(viewModel.trainerData.wins) L:\(viewModel.trainerData.losses)").pixelText(6, skin.dark)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 4)
        .background(skin.darkest)
    }
}

/// A blinking pixel-text label. Mirrors the `.animate-blink` CSS keyframes used for "PRESS START"
/// and the battle screen's "waiting for input" arrow.
struct BlinkingText: View {
    var text: String
    var size: CGFloat
    var color: Color
    @State private var visible = true

    init(_ text: String, size: CGFloat, color: Color) {
        self.text = text
        self.size = size
        self.color = color
    }

    var body: some View {
        Text(text)
            .pixelText(size, color)
            .opacity(visible ? 1 : 0)
            .onAppear {
                withAnimation(.easeInOut(duration: 0.45).repeatForever(autoreverses: true)) {
                    visible = false
                }
            }
    }
}
