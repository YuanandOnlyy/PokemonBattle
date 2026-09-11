import Foundation

/// Cloud trainer profile row — 1:1 with `auth.users.id`. Credentials never live here.
struct TrainerProfile: Codable, Identifiable, Equatable, Hashable {
    let id: UUID
    var trainerName: String
    var avatarKey: String
    var level: Int
    var xp: Int
    var wins: Int
    var losses: Int
    var winStreak: Int

    enum CodingKeys: String, CodingKey {
        case id
        case trainerName = "trainer_name"
        case avatarKey = "avatar_key"
        case level, xp, wins, losses
        case winStreak = "win_streak"
    }

    static func fresh(id: UUID, trainerName: String, avatarKey: String) -> TrainerProfile {
        TrainerProfile(
            id: id,
            trainerName: trainerName,
            avatarKey: avatarKey,
            level: 1,
            xp: 0,
            wins: 0,
            losses: 0,
            winStreak: 0
        )
    }
}

enum AuthMode: String, Equatable, CaseIterable {
    case newTrainer
    case logIn
}

/// Client-side validators for Trainer ID (shared by UI + unit tests).
enum AuthValidators {
    static let maxTrainerNameLength = 12
    static let minPasswordLength = 8

    private static let emailRegex = /^[A-Z0-9._%+-]+@[A-Z0-9.-]+\.[A-Z]{2,}$/.ignoresCase()

    static func isValidTrainerName(_ name: String) -> Bool {
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        return (1...maxTrainerNameLength).contains(trimmed.count)
    }

    static func isValidEmail(_ email: String) -> Bool {
        let trimmed = email.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return false }
        return trimmed.wholeMatch(of: emailRegex) != nil
    }

    static func isValidPassword(_ password: String) -> Bool {
        password.count >= minPasswordLength
    }

    static func passwordsMatch(_ password: String, _ confirm: String) -> Bool {
        !password.isEmpty && password == confirm
    }

    /// 0 = empty/too short, 1 = Weak, 2 = Good, 3 = Strong (3-pip meter).
    static func passwordStrength(_ password: String) -> Int {
        guard password.count >= minPasswordLength else { return password.isEmpty ? 0 : 1 }
        var score = 1
        if password.count >= 10 { score += 1 }
        let hasLetter = password.rangeOfCharacter(from: .letters) != nil
        let hasDigit = password.rangeOfCharacter(from: .decimalDigits) != nil
        let hasSymbol = password.unicodeScalars.contains { !CharacterSet.alphanumerics.contains($0) }
        if hasLetter && hasDigit && (hasSymbol || password.count >= 12) { score = min(3, score + 1) }
        return min(3, score)
    }

    static func canSubmitNewTrainer(
        name: String,
        email: String,
        password: String,
        confirm: String
    ) -> Bool {
        isValidTrainerName(name)
            && isValidEmail(email)
            && isValidPassword(password)
            && passwordsMatch(password, confirm)
    }

    static func canSubmitLogIn(email: String, password: String) -> Bool {
        isValidEmail(email) && isValidPassword(password)
    }
}

/// Pure form-field helpers for TrainerID mode toggle tests (no SwiftUI dependency).
enum AuthFormLogic {
    /// Field keys visible in each auth mode.
    static func visibleFields(for mode: AuthMode) -> [String] {
        switch mode {
        case .newTrainer:
            return ["trainerName", "email", "password", "confirmPassword", "avatar"]
        case .logIn:
            return ["email", "password", "rememberMe"]
        }
    }

    /// Switching modes clears validation errors but keeps the shared email value.
    static func switchMode(
        from: AuthMode,
        to: AuthMode,
        email: String,
        clearError: inout String?
    ) -> (mode: AuthMode, email: String) {
        clearError = nil
        return (to, email)
    }

    static func primaryButtonEnabled(mode: AuthMode, name: String, email: String, password: String, confirm: String) -> Bool {
        switch mode {
        case .newTrainer:
            return AuthValidators.canSubmitNewTrainer(name: name, email: email, password: password, confirm: confirm)
        case .logIn:
            return AuthValidators.canSubmitLogIn(email: email, password: password)
        }
    }
}
