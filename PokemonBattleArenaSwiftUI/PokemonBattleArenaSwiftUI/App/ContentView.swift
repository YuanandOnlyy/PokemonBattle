import SwiftUI

/// Mirrors `AppInner` in App.tsx: routes `currentScreen` to the matching screen view, wrapped
/// in the Game Boy device shell.
struct ContentView: View {
    @State private var viewModel = GameViewModel()
    // Set once when ContentView is first created (app launch) and never touched by navigation,
    // so the splash plays exactly once per cold launch and cannot loop back in on screen changes.
    @State private var showSplash = true

    var body: some View {
        DeviceShellView {
            ZStack {
                if showSplash {
                    SplashScreenView(skin: viewModel.trainerData.settings.consoleSkin.colors) {
                        withAnimation(.easeOut(duration: 0.25)) {
                            showSplash = false
                        }
                    }
                    .transition(.opacity)
                    .zIndex(1)
                } else {
                    Group {
                        switch viewModel.currentScreen {
                        case .title: TitleScreenView(viewModel: viewModel)
                        case .teamBuilder: TeamBuilderView(viewModel: viewModel)
                        case .battle: BattleScreenView(viewModel: viewModel)
                        case .victory: VictoryScreenView(viewModel: viewModel)
                        case .defeat: DefeatScreenView(viewModel: viewModel)
                        case .pokedex: PokedexView(viewModel: viewModel)
                        case .achievements: AchievementsView(viewModel: viewModel)
                        case .trainerProfile: TrainerProfileView(viewModel: viewModel)
                        case .battleHistory: BattleHistoryView(viewModel: viewModel)
                        case .settings: SettingsView(viewModel: viewModel)
                        }
                    }
                    .transition(.asymmetric(
                        insertion: .opacity.combined(with: .scale(scale: 0.97)),
                        removal: .opacity
                    ))
                }
            }
        }
    }
}

#Preview {
    ContentView()
}

