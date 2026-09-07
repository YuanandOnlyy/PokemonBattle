import SwiftUI

/// Mirrors `AppInner` in App.tsx: routes `currentScreen` to the matching screen view, wrapped
/// in the Game Boy device shell.
struct ContentView: View {
    @State private var viewModel = GameViewModel()

    var body: some View {
        DeviceShellView {
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
        }
    }
}

#Preview {
    ContentView()
}

