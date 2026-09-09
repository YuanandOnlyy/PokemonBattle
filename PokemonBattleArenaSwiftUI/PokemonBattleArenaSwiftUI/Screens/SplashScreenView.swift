import SwiftUI

/// The app's launch splash: a Game Boy "power on" boot sequence rendered inside the device screen,
/// shown once by `ContentView` before the Title screen. Plays background fade-in -> logo spring-in
/// -> glow pulse -> supporting elements -> short hold -> fade/scale transition out, then calls
/// `onFinished` so the caller can swap to the normal screen stack. Purely presentational — it owns
/// no app state and never touches `GameViewModel.currentScreen`, so it cannot loop back in.
struct SplashScreenView: View {
    var skin: SkinColors
    var onFinished: () -> Void

    @State private var backgroundOpacity: Double = 0
    @State private var logoScale: CGFloat = 0.4
    @State private var logoOpacity: Double = 0
    @State private var glowPulse = false
    @State private var showTagline = false
    @State private var showSupporting = false
    @State private var loadProgress: CGFloat = 0
    @State private var isExiting = false

    private static let leftSpriteID = 6   // Charizard
    private static let rightSpriteID = 9  // Blastoise

    var body: some View {
        ZStack {
            background
            atmosphere
            vignette

            VStack(spacing: 0) {
                Spacer()
                logoBlock
                if showTagline {
                    tagline
                        .transition(.opacity.combined(with: .move(edge: .top)))
                }
                Spacer()
                if showSupporting {
                    loadingBlock
                        .transition(.opacity.combined(with: .move(edge: .bottom)))
                        .padding(.bottom, 22)
                }
            }
            .padding(.horizontal, 18)
        }
        .opacity(isExiting ? 0 : 1)
        .scaleEffect(isExiting ? 1.06 : 1)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .task { await runSequence() }
    }

    // MARK: - Layers

    private var background: some View {
        LinearGradient(
            colors: [skin.darkest, skin.dark, skin.medium],
            startPoint: .top, endPoint: .bottom
        )
        .opacity(backgroundOpacity)
        .ignoresSafeArea()
    }

    @ViewBuilder
    private var atmosphere: some View {
        // Faint battle silhouettes flanking the logo, echoing the Title screen's showcase.
        HStack {
            OfficialSpriteView(id: Self.leftSpriteID, width: 96, height: 96)
                .opacity(showSupporting ? 0.22 : 0)
                .offset(x: showSupporting ? 0 : -20, y: 10)
            Spacer()
            OfficialSpriteView(id: Self.rightSpriteID, width: 96, height: 96)
                .opacity(showSupporting ? 0.22 : 0)
                .offset(x: showSupporting ? 0 : 20, y: -6)
        }
        .padding(.horizontal, 4)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)

        // A soft radial glow behind the logo for depth.
        RadialGradient(colors: [skin.light.opacity(0.35), .clear], center: .center, startRadius: 4, endRadius: 150)
            .opacity(logoOpacity)
    }

    private var vignette: some View {
        RadialGradient(colors: [.clear, .black.opacity(0.45)], center: .center, startRadius: 110, endRadius: 240)
            .allowsHitTesting(false)
    }

    private var logoBlock: some View {
        VStack(spacing: 6) {
            Text("\u{2605} \u{2605} \u{2605} \u{2605} \u{2605} \u{2605}")
                .pixelText(6, skin.light)
                .tracking(4)
                .opacity(logoOpacity)

            Text("POKEMON")
                .font(.pixel(30))
                .foregroundStyle(skin.lightest)
                .tracking(2)
                .shadow(color: skin.darkest, radius: 0, x: 3, y: 3)
                .shadow(color: skin.accent.opacity(glowPulse ? 0.9 : 0.35), radius: glowPulse ? 14 : 4)

            Text("BATTLE ARENA")
                .font(.pixel(13))
                .foregroundStyle(skin.accent)
                .tracking(3)
                .shadow(color: skin.darkest, radius: 0, x: 2, y: 2)
        }
        .scaleEffect(logoScale)
        .opacity(logoOpacity)
        .onAppear {
            withAnimation(.easeInOut(duration: 0.9).repeatForever(autoreverses: true)) {
                glowPulse = true
            }
        }
    }

    private var tagline: some View {
        Text("\u{25B6} GAME BOY EDITION \u{25C0}")
            .pixelText(8, skin.lightest)
            .tracking(1)
            .padding(.top, 14)
    }

    private var loadingBlock: some View {
        VStack(spacing: 8) {
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Rectangle().fill(skin.darkest)
                    Rectangle()
                        .fill(skin.accent)
                        .frame(width: geo.size.width * loadProgress)
                }
            }
            .frame(width: 160, height: 8)
            .overlay(Rectangle().stroke(skin.darkest, lineWidth: 2))

            BlinkingText("LOADING...", size: 7, color: skin.darkest)
        }
    }

    // MARK: - Sequence

    /// Drives the full boot sequence end-to-end, then hands control back via `onFinished`.
    /// Structured as a single `.task`, so if this view is ever removed early SwiftUI cancels it
    /// automatically and `onFinished` simply never fires again for this instance.
    private func runSequence() async {
        withAnimation(.easeIn(duration: 0.3)) { backgroundOpacity = 1 }
        try? await Task.sleep(nanoseconds: 280_000_000)
        guard !Task.isCancelled else { return }

        withAnimation(.spring(response: 0.55, dampingFraction: 0.62)) {
            logoScale = 1
            logoOpacity = 1
        }
        try? await Task.sleep(nanoseconds: 420_000_000)
        guard !Task.isCancelled else { return }

        withAnimation(.easeOut(duration: 0.3)) { showTagline = true }
        try? await Task.sleep(nanoseconds: 260_000_000)
        guard !Task.isCancelled else { return }

        withAnimation(.easeOut(duration: 0.3)) { showSupporting = true }
        withAnimation(.easeInOut(duration: 0.7)) { loadProgress = 1 }
        try? await Task.sleep(nanoseconds: 750_000_000)
        guard !Task.isCancelled else { return }

        try? await Task.sleep(nanoseconds: 200_000_000)
        guard !Task.isCancelled else { return }

        withAnimation(.easeInOut(duration: 0.4)) { isExiting = true }
        try? await Task.sleep(nanoseconds: 400_000_000)
        guard !Task.isCancelled else { return }

        onFinished()
    }
}

#Preview {
    DeviceShellView {
        SplashScreenView(skin: SkinColors.dmg) {}
    }
}
