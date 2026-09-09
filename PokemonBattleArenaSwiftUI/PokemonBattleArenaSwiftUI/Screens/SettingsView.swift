import SwiftUI

/// Mirrors `Settings.tsx`: console skin picker, audio/display toggles, animation speed, about, and
/// a confirm-gated full data reset.
struct SettingsView: View {
    var viewModel: GameViewModel
    @State private var confirmReset = false
    @State private var cloudStatus = "Checking cloud sync..."

    private static let skinPreviews: [ConsoleSkin: (emoji: String, desc: String)] = [
        .dmg: ("\u{1F7E2}", "Original 1989 green palette"),
        .pocket: ("\u{2B1C}", "Monochrome gray palette"),
        .crystal: ("\u{1F537}", "Deep navy with gold accents"),
        .advance: ("\u{1F7E3}", "Indigo with cyan highlights"),
    ]

    private var skin: SkinColors { viewModel.trainerData.settings.consoleSkin.colors }
    private var settings: GameSettings { viewModel.trainerData.settings }

    var body: some View {
        VStack(spacing: 0) {
            header.staggerAppear(0)
            ScrollView {
                VStack(spacing: 12) {
                    consoleSkinCard.staggerAppear(1)
                    audioDisplayCard.staggerAppear(2)
                    animSpeedCard.staggerAppear(3)
                    cloudSyncCard.staggerAppear(4)
                    aboutCard.staggerAppear(5)
                    dangerZoneCard.staggerAppear(6)
                }
                .padding(10)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .background(skin.medium)
        .task {
            cloudStatus = await SupabaseService.probeConnection()
        }
    }

    private var header: some View {
        HStack(spacing: 8) {
            Button {
                viewModel.navigate(.title)
            } label: {
                Text("\u{25C0}").font(.pixel(12)).foregroundStyle(skin.lightest)
            }
            .buttonStyle(.plain)
            Text("\u{2699} SETTINGS").pixelText(10, skin.lightest)
            Spacer()
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .background(skin.darkest)
        .overlay(Rectangle().fill(skin.dark).frame(height: 4), alignment: .bottom)
    }

    private func sectionCard(title: String, titleColor: Color? = nil, @ViewBuilder content: () -> some View) -> some View {
        VStack(spacing: 6) {
            Text(title)
                .pixelText(9, titleColor ?? skin.darkest)
                .padding(.bottom, 6)
                .overlay(Rectangle().fill(skin.medium).frame(height: 2), alignment: .bottom)
            content()
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(skin.lightest)
        .overlay(Rectangle().stroke(skin.darkest, lineWidth: 4))
    }

    private var consoleSkinCard: some View {
        sectionCard(title: "\u{1F3A8} CONSOLE SKIN") {
            VStack(spacing: 6) {
                ForEach(ConsoleSkin.allCases, id: \.self) { candidate in
                    let colors = candidate.colors
                    let preview = Self.skinPreviews[candidate]
                    let isSelected = settings.consoleSkin == candidate
                    Button {
                        viewModel.updateTrainer { $0.settings.consoleSkin = candidate }
                    } label: {
                        HStack(spacing: 8) {
                            HStack(spacing: 2) {
                                ForEach([colors.darkest, colors.dark, colors.medium, colors.lightest], id: \.self) { swatch in
                                    Rectangle().fill(swatch).frame(width: 10, height: 20)
                                        .overlay(Rectangle().stroke(.black, lineWidth: 1))
                                }
                            }
                            VStack(alignment: .leading, spacing: 2) {
                                Text((isSelected ? "\u{25B6} " : "") + colors.name.uppercased())
                                    .font(.pixel(8))
                                    .foregroundStyle(isSelected ? skin.lightest : skin.darkest)
                                if let preview {
                                    Text(preview.desc)
                                        .font(.pixel(6))
                                        .foregroundStyle(isSelected ? skin.medium : skin.dark)
                                }
                            }
                            Spacer()
                        }
                        .padding(.horizontal, 10)
                        .padding(.vertical, 8)
                        .background(isSelected ? skin.darkest : skin.medium)
                        .overlay(Rectangle().stroke(isSelected ? skin.accent : skin.darkest, lineWidth: 3))
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    private var audioDisplayCard: some View {
        sectionCard(title: "AUDIO & DISPLAY") {
            VStack(spacing: 0) {
                toggleRow(icon: "\u{1F50A}", label: "SOUND FX", value: settings.soundEffects) {
                    viewModel.updateTrainer { $0.settings.soundEffects.toggle() }
                }
                toggleRow(icon: "\u{1F3B5}", label: "MUSIC", value: settings.music) {
                    viewModel.updateTrainer { $0.settings.music.toggle() }
                }
                toggleRow(icon: "\u{1F4F3}", label: "VIBRATION", value: settings.vibration) {
                    viewModel.updateTrainer { $0.settings.vibration.toggle() }
                }
                toggleRow(icon: "\u{1F3AC}", label: "ANIMATIONS", value: settings.animations) {
                    viewModel.updateTrainer { $0.settings.animations.toggle() }
                }
                toggleRow(icon: "\u{1F3AF}", label: "REDUCED MOTION", value: settings.reducedMotion) {
                    viewModel.updateTrainer { $0.settings.reducedMotion.toggle() }
                }
                toggleRow(icon: "\u{1F4CA}", label: "BATTLE ASSIST", value: settings.battleAssist, showDivider: false) {
                    viewModel.updateTrainer { $0.settings.battleAssist.toggle() }
                }
            }
        }
    }

    private func toggleRow(icon: String, label: String, value: Bool, showDivider: Bool = true, action: @escaping () -> Void) -> some View {
        HStack {
            HStack(spacing: 8) {
                Text(icon).font(.system(size: 16))
                Text(label).pixelText(9, skin.darkest)
            }
            Spacer()
            Button(value ? "ON" : "OFF", action: action)
                .font(.pixel(9))
                .foregroundStyle(value ? skin.lightest : skin.dark)
                .padding(.horizontal, 12)
                .padding(.vertical, 5)
                .frame(minWidth: 56)
                .background(value ? skin.dark : skin.medium)
                .overlay(Rectangle().stroke(skin.darkest, lineWidth: 3))
                .buttonStyle(.plain)
        }
        .padding(.vertical, 8)
        .overlay(Rectangle().fill(skin.medium).frame(height: showDivider ? 2 : 0), alignment: .bottom)
    }

    private var animSpeedCard: some View {
        sectionCard(title: "\u{26A1} ANIM SPEED") {
            HStack(spacing: 8) {
                animSpeedButton(.normal, label: "\u{1F422} NORMAL")
                animSpeedButton(.fast, label: "\u{26A1} FAST")
            }
        }
    }

    private func animSpeedButton(_ speed: GameSettings.AnimationSpeed, label: String) -> some View {
        let isSelected = settings.animationSpeed == speed
        return Button(label) {
            viewModel.updateTrainer { $0.settings.animationSpeed = speed }
        }
        .font(.pixel(10))
        .foregroundStyle(isSelected ? skin.lightest : skin.darkest)
        .frame(maxWidth: .infinity)
        .padding(.vertical, 10)
        .background(isSelected ? skin.darkest : skin.medium)
        .overlay(Rectangle().stroke(skin.darkest, lineWidth: 3))
        .buttonStyle(.plain)
    }

    private var cloudSyncCard: some View {
        sectionCard(title: "\u{2601} CLOUD SYNC") {
            VStack(alignment: .leading, spacing: 8) {
                Text(cloudStatus.uppercased())
                    .font(.pixel(7))
                    .foregroundStyle(skin.darkest)
                    .fixedSize(horizontal: false, vertical: true)
                Text("LOCAL SAVE ALWAYS WORKS OFFLINE. CLOUD NEEDS ANON AUTH + TRAINERS TABLE.")
                    .pixelText(6, skin.dark)
                    .fixedSize(horizontal: false, vertical: true)
                Button("RECHECK") {
                    Task { cloudStatus = await SupabaseService.probeConnection() }
                }
                .buttonStyle(RetroButtonStyle(skin: skin, fontSize: 8))
            }
        }
    }

    private var aboutCard: some View {
        sectionCard(title: "ABOUT") {
            VStack(spacing: 5) {
                aboutRow("GAME", "BATTLE ARENA")
                aboutRow("VERSION", "v2.0.0")
                aboutRow("POKEMON", "\(GameData.allPokemon.count)")
                aboutRow("BATTLES", "\(viewModel.trainerData.totalBattles)")
            }
        }
    }

    private func aboutRow(_ label: String, _ value: String) -> some View {
        HStack {
            Text(label).pixelText(7, skin.dark)
            Spacer()
            Text(value).pixelText(7, skin.darkest)
        }
    }

    private var dangerZoneCard: some View {
        VStack(spacing: 6) {
            Text("\u{26A0} DANGER ZONE")
                .pixelText(9, Color(hex: "#c04000"))
                .padding(.bottom, 6)
                .overlay(Rectangle().fill(Color(hex: "#6a0000")).frame(height: 2), alignment: .bottom)

            if confirmReset {
                VStack(spacing: 4) {
                    Text("ARE YOU SURE?").pixelText(8, Color(hex: "#c04000")).multilineTextAlignment(.center)
                    Text("THIS WILL DELETE ALL PROGRESS.")
                        .font(.pixel(7))
                        .foregroundStyle(Color(hex: "#8b4040"))
                        .multilineTextAlignment(.center)
                        .padding(.bottom, 8)

                    HStack(spacing: 8) {
                        Button("RESET") {
                            viewModel.resetGame()
                            confirmReset = false
                        }
                        .font(.pixel(9))
                        .foregroundStyle(skin.lightest)
                        .frame(maxWidth: .infinity)
                        .padding(10)
                        .background(Color(hex: "#c04000"))
                        .overlay(Rectangle().stroke(skin.darkest, lineWidth: 3))
                        .buttonStyle(.plain)

                        Button("CANCEL") { confirmReset = false }
                            .font(.pixel(9))
                            .foregroundStyle(skin.darkest)
                            .frame(maxWidth: .infinity)
                            .padding(10)
                            .background(skin.medium)
                            .overlay(Rectangle().stroke(skin.darkest, lineWidth: 3))
                            .buttonStyle(.plain)
                    }
                }
            } else {
                Button("\u{1F5D1} RESET GAME DATA") { confirmReset = true }
                    .font(.pixel(9))
                    .foregroundStyle(Color(hex: "#e0a0a0"))
                    .frame(maxWidth: .infinity)
                    .padding(12)
                    .background(Color(hex: "#6a0000"))
                    .overlay(Rectangle().stroke(Color(hex: "#c04000"), lineWidth: 3))
                    .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(Color(hex: "#3a0a0a"))
        .overlay(Rectangle().stroke(Color(hex: "#c04000"), lineWidth: 4))
    }
}
