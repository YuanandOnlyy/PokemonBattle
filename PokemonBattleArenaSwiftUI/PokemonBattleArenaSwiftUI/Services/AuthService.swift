import Foundation
import Observation
import Supabase

/// Email/password auth + `public.trainers` profile row. Injected at the app root.
@MainActor
@Observable
final class AuthService {
    enum State: Equatable {
        case signedOut
        case loading
        case signedIn(TrainerProfile)
        case error(String)
    }

    var state: State = .signedOut
    /// Prefer LOG IN when the user previously had a session and signed out; else NEW TRAINER.
    var preferredAuthMode: AuthMode = .newTrainer
    /// True after the first `restoreSession()` completes (success or signed-out).
    var hasCheckedSession = false

    private let authAPI: AuthAPI
    private let trainersAPI: TrainersAPI

    /// Production initializer — talks to the real Supabase project when Secrets.plist is present.
    convenience init() {
        if SupabaseClientProvider.isConfigured {
            let client = SupabaseClientProvider.shared
            self.init(authAPI: LiveAuthAPI(client: client), trainersAPI: LiveTrainersAPI(client: client))
        } else {
            self.init(authAPI: UnconfiguredAuthAPI(), trainersAPI: UnconfiguredTrainersAPI())
        }
    }

    /// Test / preview initializer with injectable collaborators.
    init(authAPI: AuthAPI, trainersAPI: TrainersAPI) {
        self.authAPI = authAPI
        self.trainersAPI = trainersAPI
    }

    /// Clears a displayed auth error so mode switches / retries start clean.
    func clearError() {
        if case .error = state {
            state = .signedOut
        }
    }

    func signUp(email: String, password: String, trainerName: String, avatarKey: String) async {
        state = .loading
        do {
            let userId = try await authAPI.signUp(email: email, password: password)
            let profile = TrainerProfile.fresh(id: userId, trainerName: trainerName, avatarKey: avatarKey)
            try await trainersAPI.insert(profile)
            preferredAuthMode = .logIn
            state = .signedIn(profile)
        } catch {
            // Email confirmation pending is not a failure — switch to Log In so user can sign in after confirming.
            if Self.isEmailConfirmationError(error) {
                preferredAuthMode = .logIn
            }
            state = .error(Self.friendlyMessage(for: error, context: .signUp))
        }
    }

    func logIn(email: String, password: String) async {
        state = .loading
        do {
            let userId = try await authAPI.signIn(email: email, password: password)
            let profile = try await trainersAPI.fetch(id: userId)
            preferredAuthMode = .logIn
            state = .signedIn(profile)
        } catch {
            state = .error(Self.friendlyMessage(for: error, context: .logIn))
        }
    }

    func restoreSession() async {
        defer { hasCheckedSession = true }
        do {
            let userId = try await authAPI.currentUserId()
            let profile = try await trainersAPI.fetch(id: userId)
            preferredAuthMode = .logIn
            state = .signedIn(profile)
        } catch {
            state = .signedOut
        }
    }

    func logOut() async {
        try? await authAPI.signOut()
        preferredAuthMode = .logIn
        state = .signedOut
    }

    func resetPassword(email: String) async throws {
        try await authAPI.resetPassword(email: email)
    }

    private enum ErrorContext { case signUp, logIn }

    private static func isEmailConfirmationError(_ error: Error) -> Bool {
        let text = error.localizedDescription.lowercased()
        return text.contains("email confirmation") || text.contains("confirmation required") || text.contains("email_confirm")
    }

    /// Map raw Supabase/network errors to the game's retro dialogue-box copy.
    private static func friendlyMessage(for error: Error, context: ErrorContext) -> String {
        let text = error.localizedDescription.lowercased()
        if text.contains("already") || text.contains("registered") || text.contains("user_already") {
            return "THAT EMAIL IS ALREADY REGISTERED!"
        }
        if isEmailConfirmationError(error) {
            return "CHECK YOUR EMAIL! CONFIRM ACCOUNT THEN LOG IN."
        }
        if text.contains("invalid login") || text.contains("invalid credentials") || text.contains("wrong") || text.contains("not confirmed") {
            return "TRAINER ID NOT RECOGNIZED. TRY AGAIN!"
        }
        if text.contains("password") && (text.contains("weak") || text.contains("least") || text.contains("short")) {
            return "PASSWORD TOO WEAK. USE 8+ CHARACTERS!"
        }
        if text.contains("rate") && (text.contains("limit") || text.contains("exceeded")) {
            return "TOO MANY ATTEMPTS. WAIT A MINUTE AND TRY AGAIN!"
        }
        if text.contains("network") || text.contains("offline") || text.contains("internet") || text.contains("timed out") {
            return "NO SIGNAL. CHECK YOUR CONNECTION!"
        }
        if text.contains("secrets.plist") || text.contains("missing secrets") {
            return "SUPABASE NOT CONFIGURED. ADD SECRETS.PLIST!"
        }
        if text.contains("relation") || text.contains("does not exist") || text.contains("pgrst205") || text.contains("schema cache") {
            return "DATABASE NOT SET UP. RUN SQL MIGRATIONS IN SUPABASE!"
        }
        if text.contains("row level security") || text.contains("rls") || text.contains("policy") {
            return "DATABASE PERMISSION ERROR. CHECK SUPABASE POLICIES!"
        }
        switch context {
        case .signUp: return "SOMETHING WENT WRONG. TRY AGAIN!"
        case .logIn: return "TRAINER ID NOT RECOGNIZED. TRY AGAIN!"
        }
    }
}

// MARK: - Collaborator protocols (unit-test seams)

protocol AuthAPI {
    func signUp(email: String, password: String) async throws -> UUID
    func signIn(email: String, password: String) async throws -> UUID
    func currentUserId() async throws -> UUID
    func signOut() async throws
    func resetPassword(email: String) async throws
}

protocol TrainersAPI {
    func insert(_ profile: TrainerProfile) async throws
    func fetch(id: UUID) async throws -> TrainerProfile
}

struct LiveAuthAPI: AuthAPI {
    let client: SupabaseClient

    func signUp(email: String, password: String) async throws -> UUID {
        let response = try await client.auth.signUp(email: email, password: password)
        // Email-confirm projects return a user without a session; RLS insert would fail.
        if response.session == nil {
            throw AuthStubError.generic(
                "Email confirmation required — disable Confirm email in Supabase Auth settings for local play, or confirm the link then Log In."
            )
        }
        return response.user.id
    }

    func signIn(email: String, password: String) async throws -> UUID {
        let session = try await client.auth.signIn(email: email, password: password)
        return session.user.id
    }

    func currentUserId() async throws -> UUID {
        try await client.auth.session.user.id
    }

    func signOut() async throws {
        try await client.auth.signOut()
    }

    func resetPassword(email: String) async throws {
        try await client.auth.resetPasswordForEmail(email)
    }
}

struct LiveTrainersAPI: TrainersAPI {
    let client: SupabaseClient

    private struct LegacyTrainerRow: Codable {
        let id: UUID
        let data: LegacyTrainerBlob
    }

    private struct LegacyTrainerBlob: Codable {
        var name: String
        var level: Int
        var xp: Int
        var wins: Int
        var losses: Int
        var streak: Int
        var avatarKey: String

        init(name: String, level: Int, xp: Int, wins: Int, losses: Int, streak: Int, avatarKey: String) {
            self.name = name
            self.level = level
            self.xp = xp
            self.wins = wins
            self.losses = losses
            self.streak = streak
            self.avatarKey = avatarKey
        }

        init(from decoder: Decoder) throws {
            let c = try decoder.container(keyedBy: CodingKeys.self)
            name = try c.decodeIfPresent(String.self, forKey: .name) ?? "TRAINER"
            level = try c.decodeIfPresent(Int.self, forKey: .level) ?? 1
            xp = try c.decodeIfPresent(Int.self, forKey: .xp) ?? 0
            wins = try c.decodeIfPresent(Int.self, forKey: .wins) ?? 0
            losses = try c.decodeIfPresent(Int.self, forKey: .losses) ?? 0
            streak = try c.decodeIfPresent(Int.self, forKey: .streak) ?? 0
            avatarKey = try c.decodeIfPresent(String.self, forKey: .avatarKey) ?? "default_trainer"
        }

        enum CodingKeys: String, CodingKey {
            case name, level, xp, wins, losses, streak, avatarKey
        }
    }

    func insert(_ profile: TrainerProfile) async throws {
        do {
            try await client.from("trainers").insert(profile).execute()
        } catch {
            // Live DB may still be on the pre-migration `data jsonb` shape.
            if Self.isMissingColumnError(error) {
                let legacy = LegacyTrainerRow(
                    id: profile.id,
                    data: LegacyTrainerBlob(
                        name: profile.trainerName,
                        level: profile.level,
                        xp: profile.xp,
                        wins: profile.wins,
                        losses: profile.losses,
                        streak: profile.winStreak,
                        avatarKey: profile.avatarKey
                    )
                )
                try await client.from("trainers").insert(legacy).execute()
            } else {
                throw error
            }
        }
    }

    func fetch(id: UUID) async throws -> TrainerProfile {
        do {
            let profile: TrainerProfile = try await client.from("trainers")
                .select()
                .eq("id", value: id)
                .single()
                .execute()
                .value
            return profile
        } catch {
            if Self.isMissingColumnError(error) || Self.isDecodingError(error) {
                let legacy: LegacyTrainerRow = try await client.from("trainers")
                    .select()
                    .eq("id", value: id)
                    .single()
                    .execute()
                    .value
                return TrainerProfile(
                    id: legacy.id,
                    trainerName: legacy.data.name,
                    avatarKey: legacy.data.avatarKey.isEmpty ? "default_trainer" : legacy.data.avatarKey,
                    level: legacy.data.level,
                    xp: legacy.data.xp,
                    wins: legacy.data.wins,
                    losses: legacy.data.losses,
                    winStreak: legacy.data.streak
                )
            }
            throw error
        }
    }

    private static func isMissingColumnError(_ error: Error) -> Bool {
        let text = error.localizedDescription
        return text.contains("PGRST204")
            || text.localizedCaseInsensitiveContains("could not find")
            || text.localizedCaseInsensitiveContains("avatar_key")
            || text.localizedCaseInsensitiveContains("trainer_name")
            || text.localizedCaseInsensitiveContains("game_data")
    }

    static func isMissingTableError(_ error: Error) -> Bool {
        let text = error.localizedDescription
        return text.localizedCaseInsensitiveContains("relation")
            || text.localizedCaseInsensitiveContains("does not exist")
            || text.contains("PGRST205")
            || text.localizedCaseInsensitiveContains("schema cache")
    }

    private static func isDecodingError(_ error: Error) -> Bool {
        error is DecodingError || error.localizedDescription.localizedCaseInsensitiveContains("decoding")
    }
}

// MARK: - Test doubles

enum AuthStubError: LocalizedError {
    case duplicateEmail
    case wrongPassword
    case noSession
    case generic(String)

    var errorDescription: String? {
        switch self {
        case .duplicateEmail: return "User already registered"
        case .wrongPassword: return "Invalid login credentials"
        case .noSession: return "Auth session missing"
        case .generic(let message): return message
        }
    }
}

final class MockAuthAPI: AuthAPI {
    var signUpHandler: ((String, String) async throws -> UUID)?
    var signInHandler: ((String, String) async throws -> UUID)?
    var currentUserHandler: (() async throws -> UUID)?
    var signOutCalled = false
    var resetPasswordEmails: [String] = []

    func signUp(email: String, password: String) async throws -> UUID {
        if let signUpHandler { return try await signUpHandler(email, password) }
        throw AuthStubError.generic("signUp not stubbed")
    }

    func signIn(email: String, password: String) async throws -> UUID {
        if let signInHandler { return try await signInHandler(email, password) }
        throw AuthStubError.generic("signIn not stubbed")
    }

    func currentUserId() async throws -> UUID {
        if let currentUserHandler { return try await currentUserHandler() }
        throw AuthStubError.noSession
    }

    func signOut() async throws {
        signOutCalled = true
    }

    func resetPassword(email: String) async throws {
        resetPasswordEmails.append(email)
    }
}

final class MockTrainersAPI: TrainersAPI {
    var stored: [UUID: TrainerProfile] = [:]
    var inserted: [TrainerProfile] = []

    func insert(_ profile: TrainerProfile) async throws {
        stored[profile.id] = profile
        inserted.append(profile)
    }

    func fetch(id: UUID) async throws -> TrainerProfile {
        guard let profile = stored[id] else {
            throw AuthStubError.generic("Trainer profile not found")
        }
        return profile
    }
}

/// Used when Secrets.plist is missing so the app still boots (Trainer ID shows a clear error).
struct UnconfiguredAuthAPI: AuthAPI {
    private let message = "Missing Secrets.plist — copy Secrets.example.plist and add your Supabase URL/key."

    func signUp(email: String, password: String) async throws -> UUID { throw AuthStubError.generic(message) }
    func signIn(email: String, password: String) async throws -> UUID { throw AuthStubError.generic(message) }
    func currentUserId() async throws -> UUID { throw AuthStubError.noSession }
    func signOut() async throws {}
    func resetPassword(email: String) async throws { throw AuthStubError.generic(message) }
}

struct UnconfiguredTrainersAPI: TrainersAPI {
    private let message = "Missing Secrets.plist — copy Secrets.example.plist and add your Supabase URL/key."

    func insert(_ profile: TrainerProfile) async throws { throw AuthStubError.generic(message) }
    func fetch(id: UUID) async throws -> TrainerProfile { throw AuthStubError.generic(message) }
}
