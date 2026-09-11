import Foundation
import Supabase

/// Cloud sync for `TrainerData`, layered on top of the existing UserDefaults / Documents save in
/// `GameViewModel`. Local storage remains the source of truth for offline play; this mirrors saves
/// up to Supabase under the signed-in user's id so progress can be restored on a new device.
///
/// Requires: run `supabase/migrations/0001_trainers.sql` and sign in via `AuthService`
/// (email/password). Failures are non-fatal.
enum SupabaseService {
    private static var client: SupabaseClient { SupabaseClientProvider.shared }

    /// Human-readable last sync error (nil when the most recent operation succeeded).
    nonisolated(unsafe) static var lastError: String?
    /// When true, save/load short-circuit until the next successful probe.
    nonisolated(unsafe) private static var cloudUnavailable = false

    private struct TrainerCloudRow: Codable {
        let id: UUID
        let trainerName: String
        let avatarKey: String
        let level: Int
        let xp: Int
        let wins: Int
        let losses: Int
        let winStreak: Int
        let gameData: TrainerData

        enum CodingKeys: String, CodingKey {
            case id
            case trainerName = "trainer_name"
            case avatarKey = "avatar_key"
            case level, xp, wins, losses
            case winStreak = "win_streak"
            case gameData = "game_data"
        }
    }

    private static func currentUserId() async throws -> UUID {
        try await client.auth.session.user.id
    }

    private static func markUnavailable(_ message: String) {
        lastError = message
        cloudUnavailable = true
    }

    private static func classify(_ error: Error) -> String {
        let message = error.localizedDescription
        if message.localizedCaseInsensitiveContains("session") {
            return "Not signed in — open Trainer ID to log in"
        }
        if message.localizedCaseInsensitiveContains("trainers")
            || message.contains("PGRST205")
            || message.localizedCaseInsensitiveContains("schema cache") {
            return "Missing public.trainers table — run supabase/migrations/0001_trainers.sql"
        }
        return message
    }

    /// Fire-and-forget upload; failures never block play. No-ops when signed out.
    static func saveTrainer(_ trainer: TrainerData) async {
        guard !cloudUnavailable else { return }
        do {
            let uid = try await currentUserId()
            let row = TrainerCloudRow(
                id: uid,
                trainerName: String(trainer.name.prefix(12)),
                avatarKey: "default_trainer",
                level: trainer.level,
                xp: trainer.xp,
                wins: trainer.wins,
                losses: trainer.losses,
                winStreak: trainer.streak,
                gameData: trainer
            )
            try await client
                .from("trainers")
                .upsert(row)
                .execute()
            lastError = nil
        } catch {
            // Signed-out is normal before Trainer ID — don't latch unavailable.
            let classified = classify(error)
            if classified.localizedCaseInsensitiveContains("signed in")
                || classified.localizedCaseInsensitiveContains("session") {
                lastError = nil
                return
            }
            markUnavailable("Cloud save failed: \(classified)")
        }
    }

    /// Returns nil on any failure (offline, no cloud save yet, decode mismatch, signed out).
    static func loadTrainer() async -> TrainerData? {
        guard !cloudUnavailable else { return nil }
        do {
            let uid = try await currentUserId()
            let row: TrainerCloudRow = try await client
                .from("trainers")
                .select()
                .eq("id", value: uid)
                .single()
                .execute()
                .value
            lastError = nil
            var data = row.gameData
            if data.name.isEmpty { data.name = row.trainerName }
            return data
        } catch {
            let classified = classify(error)
            if classified.localizedCaseInsensitiveContains("trainers") {
                markUnavailable("Cloud load failed: \(classified)")
            } else {
                lastError = "Cloud load failed: \(classified)"
            }
            return nil
        }
    }

    /// Lightweight probe used by Settings. Clears the unavailable latch and re-tests.
    static func probeConnection() async -> String {
        cloudUnavailable = false
        do {
            _ = try await currentUserId()
            _ = try await client.from("trainers").select("id").limit(1).execute()
            lastError = nil
            cloudUnavailable = false
            return "Connected — trainers table reachable"
        } catch {
            let classified = classify(error)
            markUnavailable(classified)
            return classified
        }
    }

    static var isCloudUnavailable: Bool { cloudUnavailable }
}
