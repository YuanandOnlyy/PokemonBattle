import SwiftUI

/// Combined NEW TRAINER / LOG IN dialog — Game Boy styled Trainer ID gate.
struct TrainerIDView: View {
    var viewModel: GameViewModel
    var authService: AuthService
    var initialMode: AuthMode = .newTrainer
    var onAuthenticated: (TrainerProfile, Bool) -> Void

    @State private var authMode: AuthMode = .newTrainer
    @State private var trainerName = ""
    @State private var email = ""
    @State private var password = ""
    @State private var confirmPassword = ""
    @State private var showPassword = false
    @State private var rememberMe = true
    @State private var selectedAvatar = "default_trainer"
    @State private var fieldsOpacity: Double = 1
    @State private var showingForgotPassword = false
    @State private var forgotSent = false
    @State private var localError: String?
    @State private var shakeToken = 0
    @State private var successPhase: SuccessPhase = .none
    @Environment(\.accessibilityReduceMotion) private var systemReduceMotion

    private enum SuccessPhase: Equatable {
        case none
        case welcome
        case burst
        case tagline
    }

    private static let avatarKeys = [
        "default_trainer", "ash_cap", "misty_band", "brock_gear", "rocket_shade", "oak_lab"
    ]

    private var skin: SkinColors { viewModel.trainerData.settings.consoleSkin.colors }
    private var reduceMotion: Bool {
        systemReduceMotion || viewModel.trainerData.settings.reducedMotion
    }

    private var isLoading: Bool {
        if case .loading = authService.state { return true }
        return false
    }

    private var canSubmit: Bool {
        switch authMode {
        case .newTrainer:
            AuthValidators.canSubmitNewTrainer(
                name: trainerName, email: email, password: password, confirm: confirmPassword
            )
        case .logIn:
            AuthValidators.canSubmitLogIn(email: email, password: password)
        }
    }

    var body: some View {
        GeometryReader { geo in
            ScrollView {
                VStack(spacing: 14) {
                    logo
                    modeToggle
                    if showingForgotPassword {
                        forgotPasswordPanel
                    } else {
                        fieldsStack
                            .opacity(fieldsOpacity)
                        primaryButton
                        if authMode == .logIn {
                            Button("forgot password?") {
                                localError = nil
                                forgotSent = false
                                showingForgotPassword = true
                            }
                            .font(.pixel(8))
                            .foregroundStyle(skin.dark)
                            .frame(minHeight: 44)
                            .buttonStyle(.plain)
                            .accessibilityLabel("Forgot password")
                        }
                    }
                    errorBox
                    if successPhase != .none {
                        successOverlay
                    }
                    Text("▼ continue")
                        .pixelText(8, skin.dark.opacity(0.7))
                        .padding(.top, 4)
                }
                .padding(16)
                .frame(minHeight: geo.size.height)
            }
        }
        .background(skin.medium)
        .onAppear {
            authMode = initialMode
        }
        .onChange(of: authService.state) { _, newState in
            handleAuthState(newState)
        }
    }

    // MARK: - Chrome

    private var logo: some View {
        VStack(spacing: 6) {
            Text("POKEMON")
                .font(.pixel(22))
                .foregroundStyle(skin.darkest)
                .shadow(color: skin.dark, radius: 0, x: 2, y: 2)
            Text("TRAINER ID")
                .pixelText(10, skin.dark)
            Text("GAME BOY BATTLE ARENA")
                .pixelText(7, skin.dark.opacity(0.85))
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 8)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Pokemon Game Boy Battle Arena Trainer ID")
    }

    private var modeToggle: some View {
        HStack(spacing: 0) {
            modeTab(.newTrainer, title: "NEW TRAINER")
            modeTab(.logIn, title: "LOG IN")
        }
        .overlay(Rectangle().stroke(skin.darkest, lineWidth: 3))
        .accessibilityElement(children: .contain)
    }

    private func modeTab(_ mode: AuthMode, title: String) -> some View {
        let selected = authMode == mode && !showingForgotPassword
        return Button {
            guard authMode != mode || showingForgotPassword else { return }
            switchToMode(mode)
        } label: {
            Text(title)
                .font(.pixel(8))
                .foregroundStyle(selected ? skin.lightest : skin.darkest)
                .frame(maxWidth: .infinity)
                .frame(minHeight: 44)
                .background(selected ? skin.darkest : skin.lightest)
        }
        .buttonStyle(.plain)
        .accessibilityLabel(title)
        .accessibilityAddTraits(selected ? .isSelected : [])
    }

    private func switchToMode(_ mode: AuthMode) {
        localError = nil
        showingForgotPassword = false
        forgotSent = false
        let apply = {
            authMode = mode
            fieldsOpacity = 1
        }
        if reduceMotion {
            apply()
            return
        }
        withAnimation(.easeOut(duration: 0.15)) { fieldsOpacity = 0 }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
            apply()
            withAnimation(.easeIn(duration: 0.15)) { fieldsOpacity = 1 }
        }
    }

    // MARK: - Fields

    @ViewBuilder
    private var fieldsStack: some View {
        VStack(spacing: 10) {
            if authMode == .newTrainer {
                namedField(
                    title: "TRAINER NAME",
                    text: $trainerName,
                    limit: AuthValidators.maxTrainerNameLength,
                    secure: false,
                    accessibility: "Trainer name, \(trainerName.count) of \(AuthValidators.maxTrainerNameLength) characters used"
                )
                Text("\(trainerName.count)/\(AuthValidators.maxTrainerNameLength)")
                    .pixelText(7, skin.dark)
                    .frame(maxWidth: .infinity, alignment: .trailing)
            }

            namedField(
                title: "EMAIL",
                text: $email,
                limit: nil,
                secure: false,
                accessibility: "Email"
            )

            passwordField(title: "PASSWORD", text: $password, accessibility: "Password, secure text field")

            if authMode == .newTrainer {
                passwordField(title: "CONFIRM PASSWORD", text: $confirmPassword, accessibility: "Confirm password, secure text field")
                confirmMatchIndicator
                passwordStrengthMeter
                avatarPicker
            } else {
                rememberMeRow
            }
        }
        .dynamicTypeSize(...DynamicTypeSize.accessibility3)
    }

    private func namedField(
        title: String,
        text: Binding<String>,
        limit: Int?,
        secure: Bool,
        accessibility: String
    ) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title).pixelText(8, skin.darkest)
            Group {
                if secure && !showPassword {
                    SecureField("", text: text)
                } else {
                    TextField("", text: text)
                }
            }
            .font(.pixel(10))
            .foregroundStyle(skin.darkest)
            .padding(10)
            .frame(minHeight: 44)
            .background(skin.lightest)
            .overlay(Rectangle().stroke(skin.darkest, lineWidth: 3))
            .onChange(of: text.wrappedValue) { _, newValue in
                if let limit, newValue.count > limit {
                    text.wrappedValue = String(newValue.prefix(limit))
                }
            }
            .accessibilityLabel(accessibility)
        }
    }

    private func passwordField(title: String, text: Binding<String>, accessibility: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(title).pixelText(8, skin.darkest)
                Spacer()
                Button(showPassword ? "HIDE" : "SHOW") { showPassword.toggle() }
                    .font(.pixel(7))
                    .foregroundStyle(skin.dark)
                    .frame(minHeight: 44)
                    .buttonStyle(.plain)
                    .accessibilityLabel(showPassword ? "Hide password" : "Show password")
            }
            Group {
                if showPassword {
                    TextField("", text: text)
                } else {
                    SecureField("", text: text)
                }
            }
            .font(.pixel(10))
            .foregroundStyle(skin.darkest)
            .padding(10)
            .frame(minHeight: 44)
            .background(skin.lightest)
            .overlay(Rectangle().stroke(skin.darkest, lineWidth: 3))
            .accessibilityLabel(accessibility)
        }
    }

    private var confirmMatchIndicator: some View {
        let match = AuthValidators.passwordsMatch(password, confirmPassword)
        let message = confirmPassword.isEmpty ? "ENTER CONFIRMATION" : (match ? "PASSWORDS MATCH" : "DOESN'T MATCH")
        return Text(message)
            .pixelText(7, match && !confirmPassword.isEmpty ? skin.darkest : Color(hex: "#c04000"))
            .frame(maxWidth: .infinity, alignment: .leading)
            .accessibilityLabel(message)
    }

    private var passwordStrengthMeter: some View {
        let strength = AuthValidators.passwordStrength(password)
        let label = ["", "WEAK", "GOOD", "STRONG"][strength]
        return VStack(alignment: .leading, spacing: 4) {
            Text("PASSWORD STRENGTH: \(label)").pixelText(7, skin.dark)
            HStack(spacing: 4) {
                ForEach(1...3, id: \.self) { pip in
                    Rectangle()
                        .fill(pip <= strength ? strengthColor(strength) : skin.darkest.opacity(0.25))
                        .frame(height: 10)
                }
            }
            .overlay(Rectangle().stroke(skin.darkest, lineWidth: 2))
            // TODO: restyle with design system — mini HP-bar meter already reuses track/fill language
        }
        .accessibilityLabel("Password strength \(label.isEmpty ? "none" : label)")
    }

    private func strengthColor(_ strength: Int) -> Color {
        switch strength {
        case 1: return Color(hex: "#c04000")
        case 2: return Color(hex: "#c0a000")
        default: return skin.dark
        }
    }

    private var avatarPicker: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("TRAINER SPRITE").pixelText(8, skin.darkest)
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(Self.avatarKeys, id: \.self) { key in
                        let selected = selectedAvatar == key
                        Button {
                            selectedAvatar = key
                        } label: {
                            Text(avatarGlyph(key))
                                .font(.system(size: 22))
                                .frame(width: 52, height: 52)
                                .background(selected ? skin.darkest : skin.lightest)
                                .foregroundStyle(selected ? skin.lightest : skin.darkest)
                                .overlay(Rectangle().stroke(skin.darkest, lineWidth: selected ? 4 : 2))
                        }
                        .buttonStyle(.plain)
                        .accessibilityLabel("Avatar \(key)\(selected ? ", selected" : "")")
                    }
                }
            }
            // TODO: restyle with design system — swap glyphs for Trainer Profile sprite tiles when assets land
        }
    }

    private func avatarGlyph(_ key: String) -> String {
        switch key {
        case "ash_cap": return "🧢"
        case "misty_band": return "🌊"
        case "brock_gear": return "🪨"
        case "rocket_shade": return "🕶️"
        case "oak_lab": return "🔬"
        default: return "🧑‍🎤"
        }
    }

    private var rememberMeRow: some View {
        HStack {
            Text("REMEMBER ME").pixelText(9, skin.darkest)
            Spacer()
            Button(rememberMe ? "ON" : "OFF") { rememberMe.toggle() }
                .font(.pixel(9))
                .foregroundStyle(rememberMe ? skin.lightest : skin.dark)
                .padding(.horizontal, 12)
                .padding(.vertical, 5)
                .frame(minWidth: 56, minHeight: 44)
                .background(rememberMe ? skin.dark : skin.medium)
                .overlay(Rectangle().stroke(skin.darkest, lineWidth: 3))
                .buttonStyle(.plain)
                .accessibilityLabel("Remember me, \(rememberMe ? "on" : "off")")
        }
    }

    private var primaryButton: some View {
        Button {
            Task { await submit() }
        } label: {
            HStack(spacing: 8) {
                if isLoading {
                    BlinkingText("...", size: 12, color: skin.lightest)
                }
                Text(authMode == .newTrainer ? "▶ CREATE TRAINER" : "▶ LOG IN")
                    .font(.pixel(11))
            }
            .frame(maxWidth: .infinity)
            .frame(minHeight: 48)
        }
        .buttonStyle(RetroButtonStyle(
            skin: skin,
            dark: true,
            fontSize: 11,
            isDisabled: !canSubmit || isLoading || successPhase != .none
        ))
        .disabled(!canSubmit || isLoading || successPhase != .none)
        .accessibilityLabel(authMode == .newTrainer ? "Create trainer" : "Log in")
    }

    private var forgotPasswordPanel: some View {
        VStack(spacing: 12) {
            Text("RESET PASSWORD").pixelText(10, skin.darkest)
            namedField(title: "EMAIL", text: $email, limit: nil, secure: false, accessibility: "Email for password reset")
            if forgotSent {
                DialogBoxView(
                    text: "CHECK YOUR POKÉGEAR FOR RESET INSTRUCTIONS",
                    textColor: skin.darkest,
                    skin: skin
                )
            } else {
                Button("SEND RESET LINK") {
                    Task {
                        do {
                            try await authService.resetPassword(email: email.trimmingCharacters(in: .whitespacesAndNewlines))
                            forgotSent = true
                            localError = nil
                        } catch {
                            localError = "COULDN'T SEND RESET. TRY AGAIN!"
                            shakeToken += 1
                        }
                    }
                }
                .buttonStyle(RetroButtonStyle(skin: skin, dark: true, fontSize: 10, isDisabled: !AuthValidators.isValidEmail(email)))
                .disabled(!AuthValidators.isValidEmail(email))
            }
            Button("◀ BACK TO LOG IN") {
                showingForgotPassword = false
                forgotSent = false
                authMode = .logIn
            }
            .font(.pixel(8))
            .foregroundStyle(skin.darkest)
            .frame(minHeight: 44)
            .buttonStyle(.plain)
        }
    }

    @ViewBuilder
    private var errorBox: some View {
        if let message = displayedError {
            DialogBoxView(text: message, textColor: Color(hex: "#c04000"), skin: skin)
                .modifier(AuthShakeEffect(token: shakeToken, reduceMotion: reduceMotion))
                .accessibilityLabel("Error: \(message)")
        }
    }

    private var displayedError: String? {
        if let localError { return localError }
        if case .error(let message) = authService.state { return message }
        return nil
    }

    private var successOverlay: some View {
        VStack(spacing: 10) {
            switch successPhase {
            case .welcome:
                DialogBoxView(text: welcomeText, textColor: skin.darkest, skin: skin)
            case .burst:
                Text(reduceMotion ? "★" : "✦ ✧ ★ ✧ ✦")
                    .font(.pixel(14))
                    .foregroundStyle(skin.darkest)
                    .transition(.opacity)
            case .tagline:
                DialogBoxView(text: "YOUR ADVENTURE BEGINS!", textColor: skin.darkest, skin: skin)
            case .none:
                EmptyView()
            }
        }
    }

    private var welcomeText: String {
        if authMode == .newTrainer {
            return "WELCOME, \(trainerName.uppercased())!"
        }
        if case .signedIn(let profile) = authService.state {
            return "WELCOME BACK, \(profile.trainerName.uppercased())!"
        }
        return "WELCOME BACK!"
    }

    // MARK: - Actions

    private func submit() async {
        localError = nil
        let trimmedEmail = email.trimmingCharacters(in: .whitespacesAndNewlines)
        switch authMode {
        case .newTrainer:
            guard AuthValidators.canSubmitNewTrainer(
                name: trainerName, email: trimmedEmail, password: password, confirm: confirmPassword
            ) else { return }
            await authService.signUp(
                email: trimmedEmail,
                password: password,
                trainerName: trainerName.trimmingCharacters(in: .whitespacesAndNewlines),
                avatarKey: selectedAvatar
            )
        case .logIn:
            guard AuthValidators.canSubmitLogIn(email: trimmedEmail, password: password) else { return }
            await authService.logIn(email: trimmedEmail, password: password)
        }
    }

    private func handleAuthState(_ newState: AuthService.State) {
        switch newState {
        case .error:
            shakeToken += 1
        case .signedIn(let profile):
            Task { await playSuccess(profile: profile) }
        default:
            break
        }
    }

    private func playSuccess(profile: TrainerProfile) async {
        let isNew = authMode == .newTrainer
        successPhase = .welcome
        try? await Task.sleep(nanoseconds: reduceMotion ? 400_000_000 : 900_000_000)
        if isNew {
            successPhase = .burst
            try? await Task.sleep(nanoseconds: reduceMotion ? 250_000_000 : 700_000_000)
            successPhase = .tagline
            try? await Task.sleep(nanoseconds: reduceMotion ? 350_000_000 : 800_000_000)
        } else {
            try? await Task.sleep(nanoseconds: reduceMotion ? 250_000_000 : 600_000_000)
        }
        onAuthenticated(profile, isNew)
    }
}

/// Short horizontal shudder when `token` increments — disabled under Reduced Motion.
private struct AuthShakeEffect: ViewModifier {
    var token: Int
    var reduceMotion: Bool
    @State private var offsetX: CGFloat = 0

    func body(content: Content) -> some View {
        content
            .offset(x: offsetX)
            .onChange(of: token) { _, _ in
                guard !reduceMotion else {
                    withAnimation(.easeInOut(duration: 0.12)) { offsetX = 0 }
                    return
                }
                Task { @MainActor in
                    for step: CGFloat in [-8, 8, -6, 6, -3, 3, 0] {
                        withAnimation(.easeInOut(duration: 0.05)) { offsetX = step }
                        try? await Task.sleep(nanoseconds: 50_000_000)
                    }
                }
            }
    }
}

#Preview {
    TrainerIDView(
        viewModel: GameViewModel(),
        authService: AuthService(),
        initialMode: .newTrainer,
        onAuthenticated: { _, _ in }
    )
}
