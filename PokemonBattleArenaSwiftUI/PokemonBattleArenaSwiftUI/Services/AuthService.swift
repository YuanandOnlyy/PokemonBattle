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

    /// Production initializer — talks to the real Supabase project.
    convenience init() {
        let client = SupabaseClientProvider.shared
        self.init(authAPI: LiveAuthAPI(client: client), trainersAPI: LiveTrainersAPI(client: client))
    }

    /// Test / preview initializer with injectable collaborators.
    init(authAPI: AuthAPI, trainersAPI: TrainersAPI) {
        self.authAPI = authAPI
        self.trainersAPI = trainersAPI
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

    /// Map raw Supabase/network errors to the game's retro dialogue-box copy.
    private static func friendlyMessage(for error: Error, context: ErrorContext) -> String {
        let text = error.localizedDescription.lowercased()
        if text.contains("already") || text.contains("registered") || text.contains("exists") || text.contains("user_already") {
            return "THAT EMAIL IS ALREADY REGISTERED!"
        }
        if text.contains("invalid login") || text.contains("invalid credentials") || text.contains("wrong") || text.contains("not confirmed") {
            return "TRAINER ID NOT RECOGNIZED. TRY AGAIN!"
        }
        if text.contains("password") && (text.contains("weak") || text.contains("least") || text.contains("short")) {
            return "PASSWORD TOO WEAK. USE 8+ CHARACTERS!"
        }
        if text.contains("network") || text.contains("offline") || text.contains("internet") || text.contains("timed out") {
            return "NO SIGNAL. CHECK YOUR CONNECTION!"
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

    func insert(_ profile: TrainerProfile) async throws {
        try await client.from("trainers").insert(profile).execute()
    }

    func fetch(id: UUID) async throws -> TrainerProfile {
        try await client.from("trainers")
            .select()
            .eq("id", value: id)
            .single()
            .execute()
            .value
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
