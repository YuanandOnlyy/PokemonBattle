import SwiftUI

/// Mirrors `BattleScreen.tsx`: the arena (enemy/player panels + sprites), the typewriter dialog
/// box, and the bottom action panel (FIGHT/BAG/POKEMON/RUN and their sub-menus).
struct BattleScreenView: View {
    var viewModel: GameViewModel

    @State private var uiPhase: BattlePhase = .menu
    @State private var confirmRun = false

    private var skin: SkinColors { viewModel.trainerData.settings.consoleSkin.colors }

    var body: some View {
        Group {
            if let state = viewModel.battleState {
                content(state)
            } else {
                Text("LOADING...")
                    .pixelText(10, skin.darkest)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(skin.medium)
            }
        }
        .onChange(of: viewModel.battleState?.phase) { _, newPhase in
            if newPhase == .menu { uiPhase = .menu }
            if newPhase == .switchPokemon { uiPhase = .switchPokemon }
        }
    }

    private func content(_ state: BattleState) -> some View {
        let activePlayer = state.playerTeam[state.activePlayerIndex]
        let activeEnemy = state.enemyTeam[state.activeEnemyIndex]
        let isBusy = state.phase == .animating || state.phase == .enemyTurn || state.phase == .battleEnd

        return VStack(spacing: 0) {
            arena(state, activePlayer: activePlayer, activeEnemy: activeEnemy)
            dialog(state)
            actionPanel(state, activePlayer: activePlayer, isBusy: isBusy)
        }
        .background(skin.medium)
        .modifier(ScreenShakeEffect(active: state.isScreenShaking))
    }

    // MARK: - Arena

    private func arena(_ state: BattleState, activePlayer: BattlePokemon, activeEnemy: BattlePokemon) -> some View {
        VStack(spacing: 2) {
            teamTracker(state)

            HStack(alignment: .top) {
                EnemyPanelView(pokemon: activeEnemy, skin: skin)
                Spacer()
                ZStack(alignment: .top) {
                    PokemonSpriteView(id: activeEnemy.id, back: false, width: 104, height: 104)
                        .scaleEffect(x: -1, y: 1)
                        .opacity(activeEnemy.isFainted ? 0.15 : 1)
                        .saturation(activeEnemy.isFainted ? 0 : 1)
                        .modifier(ShakeEffect(active: state.isEnemyShaking))
                        .opacity(state.isEnemyFlashing ? 0.3 : 1)

                    if let floating = state.floatingDamage {
                        Text(floating.value)
                            .font(.pixel(14))
                            .foregroundStyle(skin.lightest)
                            .offset(y: -14)
                            .transition(.opacity)
                            .id(floating.id)
                    }
                }
            }
            .padding(.horizontal, 6)

            Rectangle().fill(skin.darkest).frame(height: 3)

            HStack(alignment: .bottom) {
                PokemonSpriteView(id: activePlayer.id, back: true, width: 116, height: 116)
                    .opacity(activePlayer.isFainted ? 0.15 : 1)
                    .saturation(activePlayer.isFainted ? 0 : 1)
                    .modifier(ShakeEffect(active: state.isPlayerShaking))
                    .opacity(state.isPlayerFlashing ? 0.3 : 1)
                Spacer()
                PlayerPanelView(pokemon: activePlayer, skin: skin)
            }
            .padding(.horizontal, 6)
            .padding(.bottom, 6)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(skin.medium)
        .overlay(Rectangle().fill(skin.darkest).frame(height: 4), alignment: .bottom)
    }

    private func teamTracker(_ state: BattleState) -> some View {
        HStack {
            HStack(spacing: 4) {
                Text("FOE").pixelText(6, skin.medium)
                ForEach(state.enemyTeam.indices, id: \.self) { i in
                    PokeballDotView(fainted: state.enemyTeam[i].isFainted, active: i == state.activeEnemyIndex, skin: skin)
                }
            }
            Spacer()
            Text("TURN \(state.turn)").pixelText(6, skin.medium)
            Spacer()
            HStack(spacing: 4) {
                ForEach(state.playerTeam.indices, id: \.self) { i in
                    PokeballDotView(fainted: state.playerTeam[i].isFainted, active: i == state.activePlayerIndex, skin: skin)
                }
                Text("YOU").pixelText(6, skin.medium)
            }
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 4)
        .background(skin.darkest)
    }

    // MARK: - Dialog

    private func dialog(_ state: BattleState) -> some View {
        let isBusy = state.phase == .animating || state.phase == .enemyTurn || state.phase == .battleEnd
        let msg = state.displayedMessage
        let color: Color = msg.contains("SUPER EFFECTIVE") ? Color(hex: "#c04000")
            : msg.contains("critical hit") ? Color(hex: "#c0a000")
            : msg.contains("fainted") ? Color(hex: "#c04000")
            : msg.contains("not very effective") ? skin.dark
            : skin.darkest

        return ZStack(alignment: .bottomTrailing) {
            DialogBoxView(text: msg, textColor: color, skin: skin)
            if isBusy {
                BlinkingText("\u{25BC}", size: 10, color: skin.darkest)
                    .padding(.trailing, 8)
                    .padding(.bottom, 5)
            }
        }
        .padding(.horizontal, 8)
        .padding(.top, 5)
        .padding(.bottom, 3)
        .background(skin.medium)
    }

    // MARK: - Action panel

    private func actionPanel(_ state: BattleState, activePlayer: BattlePokemon, isBusy: Bool) -> some View {
        Group {
            if confirmRun {
                confirmRunView
            } else if uiPhase == .menu || isBusy {
                mainActions(isBusy: isBusy)
            } else if uiPhase == .moveSelect {
                moveSelect(activePlayer)
            } else if uiPhase == .switchPokemon {
                switchPokemon(state)
            } else if uiPhase == .bagOpen {
                bagOpen()
            }
        }
        .padding(8)
        .frame(maxWidth: .infinity)
        .background(skin.lightest)
        .overlay(Rectangle().stroke(skin.darkest, lineWidth: 4))
        .padding(.horizontal, 8)
        .padding(.bottom, 8)
        .padding(.top, 3)
    }

    private var confirmRunView: some View {
        VStack(spacing: 8) {
            Text("REALLY RUN AWAY?").pixelText(9, Color(hex: "#c04000"))
            HStack(spacing: 8) {
                Button("YES, RUN!") {
                    confirmRun = false
                    viewModel.runFromBattle()
                }
                .buttonStyle(RetroButtonStyle(skin: skin, fontSize: 9))

                Button("STAY") { confirmRun = false }
                    .buttonStyle(RetroButtonStyle(skin: skin, fontSize: 9))
            }
        }
        .padding(.vertical, 4)
    }

    private func mainActions(isBusy: Bool) -> some View {
        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 6) {
            actionButton("\u{2694} FIGHT", disabled: isBusy) { uiPhase = .moveSelect }
            actionButton("\u{1F392} BAG", disabled: isBusy) { uiPhase = .bagOpen }
            actionButton("\u{1F504} POKEMON", disabled: isBusy) { uiPhase = .switchPokemon }
            actionButton("\u{1F3C3} RUN", disabled: isBusy) { confirmRun = true }
        }
    }

    private func actionButton(_ label: String, disabled: Bool, action: @escaping () -> Void) -> some View {
        Button(label, action: action)
            .buttonStyle(RetroButtonStyle(skin: skin, fontSize: 9, isDisabled: disabled))
            .disabled(disabled)
    }

    private func moveSelect(_ activePlayer: BattlePokemon) -> some View {
        VStack(spacing: 6) {
            HStack {
                Text("\u{2694} CHOOSE MOVE").pixelText(8, skin.darkest)
                Spacer()
                backButton { uiPhase = .menu }
            }
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 5) {
                ForEach(Array(activePlayer.moves.enumerated()), id: \.offset) { index, move in
                    MoveButtonView(move: move, skin: skin) {
                        guard move.currentPP > 0 else { return }
                        viewModel.playerAttack(index)
                        uiPhase = .menu
                    }
                }
            }
        }
    }

    private func switchPokemon(_ state: BattleState) -> some View {
        let forcedSwitch = state.playerTeam[state.activePlayerIndex].isFainted
        return VStack(spacing: 6) {
            HStack {
                Text("\u{1F504} YOUR TEAM").pixelText(8, skin.darkest)
                Spacer()
                if !forcedSwitch { backButton { uiPhase = .menu } }
            }
            VStack(spacing: 4) {
                ForEach(state.playerTeam.indices, id: \.self) { index in
                    let p = state.playerTeam[index]
                    let isCurrent = index == state.activePlayerIndex
                    let disabled = p.isFainted || isCurrent
                    Button {
                        guard !disabled else { return }
                        viewModel.playerSwitch(index)
                        uiPhase = .menu
                    } label: {
                        HStack {
                            Text((isCurrent ? "\u{25B6} " : "") + p.name.uppercased() + (p.isFainted ? " [FNT]" : ""))
                                .strikethrough(p.isFainted)
                            Spacer()
                            Text("\(p.currentHP)/\(p.maxHP)").font(.pixel(7))
                        }
                        .font(.pixel(8))
                        .foregroundStyle(isCurrent ? skin.lightest : (p.isFainted ? skin.dark : skin.darkest))
                        .padding(.horizontal, 8)
                        .padding(.vertical, 6)
                        .background(isCurrent ? skin.dark : (p.isFainted ? skin.medium : skin.lightest))
                        .overlay(Rectangle().stroke(skin.darkest, lineWidth: 3))
                        .opacity(p.isFainted ? 0.45 : 1)
                    }
                    .buttonStyle(.plain)
                    .disabled(disabled)
                }
            }
            if forcedSwitch {
                Text("CHOOSE NEXT POKEMON!").pixelText(8, Color(hex: "#c04000"))
            }
        }
    }

    private func bagOpen() -> some View {
        let items = viewModel.trainerData.items
        let available = items.filter { $0.count > 0 }
        return VStack(spacing: 6) {
            HStack {
                Text("\u{1F392} BAG").pixelText(8, skin.darkest)
                Spacer()
                backButton { uiPhase = .menu }
            }
            if available.isEmpty {
                Text("BAG IS EMPTY").pixelText(9, skin.dark).padding(10)
            } else {
                VStack(spacing: 4) {
                    ForEach(Array(items.enumerated()), id: \.offset) { index, item in
                        if item.count > 0 {
                            Button {
                                viewModel.useItem(item, at: index)
                                uiPhase = .menu
                            } label: {
                                VStack(alignment: .leading, spacing: 2) {
                                    Text("\(item.name.uppercased()) \u{00D7}\(item.count)").font(.pixel(8))
                                    Text(item.description).font(.pixel(6)).foregroundStyle(skin.dark)
                                }
                                .foregroundStyle(skin.darkest)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 7)
                                .background(skin.lightest)
                                .overlay(Rectangle().stroke(skin.darkest, lineWidth: 3))
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
            }
        }
    }

    private func backButton(action: @escaping () -> Void) -> some View {
        Button("\u{25C0} BACK", action: action)
            .font(.pixel(8))
            .foregroundStyle(skin.darkest)
            .padding(.horizontal, 10)
            .padding(.vertical, 4)
            .background(skin.medium)
            .overlay(Rectangle().stroke(skin.darkest, lineWidth: 2))
            .buttonStyle(.plain)
    }
}

// MARK: - Subviews

private struct EnemyPanelView: View {
    var pokemon: BattlePokemon
    var skin: SkinColors

    var body: some View {
        let hpPercent = pokemon.maxHP > 0 ? max(0, Double(pokemon.currentHP) / Double(pokemon.maxHP)) : 0
        VStack(alignment: .leading, spacing: 2) {
            HStack {
                Text(pokemon.name.uppercased()).pixelText(9, skin.darkest)
                Spacer()
                Text("Lv\(pokemon.level)").pixelText(7, skin.dark)
            }
            HStack(spacing: 3) {
                ForEach(pokemon.types, id: \.self) { TypeBadgeView(type: $0) }
                if let status = pokemon.status { StatusBadgeView(status: status) }
            }
            HStack(spacing: 4) {
                Text("HP").font(.pixel(6)).foregroundStyle(skin.dark)
                HPBarView(current: pokemon.currentHP, max: pokemon.maxHP, compact: true, skin: skin)
            }
            Text(pokemon.isFainted ? "FAINTED" : "\(Int((hpPercent * 100).rounded()))%")
                .pixelText(7, skin.dark)
                .frame(maxWidth: .infinity, alignment: .trailing)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 5)
        .frame(minWidth: 160)
        .background(skin.lightest)
        .overlay(Rectangle().stroke(skin.darkest, lineWidth: 4))
    }
}

private struct PlayerPanelView: View {
    var pokemon: BattlePokemon
    var skin: SkinColors

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            HStack {
                Text(pokemon.name.uppercased()).pixelText(9, skin.darkest)
                Spacer()
                Text("Lv\(pokemon.level)").pixelText(7, skin.dark)
            }
            HStack(spacing: 3) {
                ForEach(pokemon.types, id: \.self) { TypeBadgeView(type: $0) }
                if let status = pokemon.status { StatusBadgeView(status: status) }
            }
            HStack(spacing: 4) {
                Text("HP").font(.pixel(6)).foregroundStyle(skin.dark)
                HPBarView(current: pokemon.currentHP, max: pokemon.maxHP, skin: skin)
            }
            Text("\(pokemon.currentHP) / \(pokemon.maxHP)").pixelText(8, skin.darkest)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 5)
        .frame(minWidth: 180)
        .background(skin.lightest)
        .overlay(Rectangle().stroke(skin.darkest, lineWidth: 4))
    }
}

private struct MoveButtonView: View {
    var move: Move
    var skin: SkinColors
    var action: () -> Void

    var body: some View {
        let outOfPP = move.currentPP == 0
        Button(action: action) {
            VStack(alignment: .leading, spacing: 3) {
                Text(move.name.uppercased()).font(.pixel(7))
                HStack {
                    TypeBadgeView(type: move.type)
                    Spacer()
                    Text(move.power > 0 ? "PWR:\(move.power)" : "STATUS").font(.pixel(6))
                }
                Text("PP: \(move.currentPP)/\(move.maxPP) | \(move.accuracy)%").font(.pixel(6))
            }
            .foregroundStyle(outOfPP ? skin.dark : skin.darkest)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 5)
            .padding(.vertical, 7)
            .background(outOfPP ? skin.medium : skin.lightest)
            .overlay(Rectangle().stroke(skin.darkest, lineWidth: 3))
            .opacity(outOfPP ? 0.55 : 1)
        }
        .buttonStyle(.plain)
        .disabled(outOfPP)
    }
}

private struct PokeballDotView: View {
    var fainted: Bool
    var active: Bool
    var skin: SkinColors

    var body: some View {
        Circle()
            .fill(fainted ? skin.dark.opacity(0.5) : (active ? skin.accent : skin.darkest))
            .frame(width: 10, height: 10)
            .overlay(Circle().stroke(skin.darkest, lineWidth: 1))
    }
}

/// Mirrors `.animate-shake` in index.css: a short horizontal shudder, played once whenever
/// `active` flips to `true` (the view model pulses it true then false via `triggerAnimation`).
private struct ShakeEffect: ViewModifier {
    var active: Bool
    @State private var offsetX: CGFloat = 0

    private static let steps: [CGFloat] = [-10, 10, -8, 8, -4, 4, 0]

    func body(content: Content) -> some View {
        content
            .offset(x: offsetX)
            .onChange(of: active) { _, newValue in
                guard newValue else { return }
                Task { await runShake() }
            }
    }

    @MainActor
    private func runShake() async {
        for step in Self.steps {
            withAnimation(.easeInOut(duration: 0.06)) { offsetX = step }
            try? await Task.sleep(nanoseconds: 60_000_000)
        }
    }
}

/// Mirrors `.animate-screen-shake` in index.css: a brief 2D jolt of the whole battle screen.
private struct ScreenShakeEffect: ViewModifier {
    var active: Bool
    @State private var offset: CGSize = .zero

    private static let steps: [CGSize] = [
        CGSize(width: -5, height: -3), CGSize(width: 5, height: 3), CGSize(width: -5, height: 3),
        CGSize(width: 5, height: -3), CGSize(width: -3, height: -3), CGSize(width: 3, height: 3),
        CGSize(width: -2, height: -2), CGSize(width: 2, height: 2), .zero,
    ]

    func body(content: Content) -> some View {
        content
            .offset(offset)
            .onChange(of: active) { _, newValue in
                guard newValue else { return }
                Task { await runShake() }
            }
    }

    @MainActor
    private func runShake() async {
        for step in Self.steps {
            withAnimation(.easeInOut(duration: 0.05)) { offset = step }
            try? await Task.sleep(nanoseconds: 50_000_000)
        }
    }
}
