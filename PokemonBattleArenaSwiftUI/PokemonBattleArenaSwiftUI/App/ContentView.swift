import SwiftUI

/// Mirrors `AppInner` in App.tsx: routes `currentScreen` to the matching screen view, wrapped
/// in the Game Boy device shell. Auth gate sits above the main menu until a session exists
/// *and* any sign-up/log-in success ceremony has finished.
struct ContentView: View {
    @State private var viewModel = GameViewModel()
    @State private var authService = AuthService()
    // Set once when ContentView is first created (app launch) and never touched by navigation,
    // so the splash plays exactly once per cold launch and cannot loop back in on screen changes.
    @State private var showSplash = true
    /// Becomes true after session restore or after TrainerIDView finishes its success beat.
    @State private var didPassAuthGate = false

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
                } else if !authService.hasCheckedSession {
                    Text("LOADING SAVE...")
                        .pixelText(10, viewModel.trainerData.settings.consoleSkin.colors.darkest)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .background(viewModel.trainerData.settings.consoleSkin.colors.medium)
                } else if didPassAuthGate {
                    mainStack
                        .transition(.asymmetric(
                            insertion: .opacity.combined(with: .scale(scale: 0.97)),
                            removal: .opacity
                        ))
                } else {
                    TrainerIDView(
                        viewModel: viewModel,
                        authService: authService,
                        initialMode: authService.preferredAuthMode,
                        onAuthenticated: { profile, isNew in
                            viewModel.applyAuthenticatedProfile(profile, isNewTrainer: isNew)
                            withAnimation(.easeInOut(duration: 0.28)) {
                                didPassAuthGate = true
                            }
                        }
                    )
                    .transition(.opacity)
                }
            }
        }
        .environment(authService)
        .task {
            await authService.restoreSession()
            if case .signedIn(let profile) = authService.state {
                viewModel.applyAuthenticatedProfile(profile, isNewTrainer: false)
                didPassAuthGate = true
            }
        }
        .onChange(of: authService.state) { _, newState in
            if case .signedOut = newState {
                didPassAuthGate = false
            }
        }
    }

    @ViewBuilder
    private var mainStack: some View {
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

#Preview {
    ContentView()
}
