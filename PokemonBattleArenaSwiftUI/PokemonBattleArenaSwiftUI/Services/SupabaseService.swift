import Foundation
import Supabase

/// Cloud sync for `TrainerData`, layered on top of the existing UserDefaults / Documents save in
/// `GameViewModel`. Local storage remains the source of truth for offline play; this mirrors saves
/// up to Supabase under the signed-in user's id so progress can be restored on a new device.
///
/// Requires (Supabase dashboard):
/// 1. Authentication → Providers → Anonymous → Enable
/// 2. SQL editor → run `supabase/schema.sql` (creates `public.trainers`)
///
/// Failures are non-fatal. After a hard configuration failure (anon disabled / missing table),
/// further network attempts are skipped until `probeConnection()` is called again.
enum SupabaseService {
    static let client = SupabaseClient(
        supabaseURL: URL(string: "https://tmlgvlstwsgmnkmwloty.supabase.co")!,
        supabaseKey: "sb_publishable_IeNJ_xqb0AtVHIbJP34JJg_48kEu3yU"
    )

    /// Human-readable last sync error (nil when the most recent operation succeeded).
    nonisolated(unsafe) static var lastError: String?
    /// When true, save/load short-circuit until the next successful probe.
    nonisolated(unsafe) private static var cloudUnavailable = false

    private static func ensureSignedIn() async throws -> UUID {
        if let session = try? await client.auth.session {
            return session.user.id
        }
        let session = try await client.auth.signInAnonymously()
        return session.user.id
    }

    private struct TrainerRow: Codable {
        let id: UUID
        let data: TrainerData
    }

    private static func markUnavailable(_ message: String) {
        lastError = message
        cloudUnavailable = true
    }

    private static func classify(_ error: Error) -> String {
        let message = error.localizedDescription
        if message.localizedCaseInsensitiveContains("anonymous") {
            return "Anonymous sign-ins disabled — enable in Supabase Auth settings"
        }
        if message.localizedCaseInsensitiveContains("trainers")
            || message.contains("PGRST205")
            || message.localizedCaseInsensitiveContains("schema cache") {
            return "Missing public.trainers table — run supabase/schema.sql"
        }
        return message
    }

    /// Fire-and-forget upload; failures never block play.
    static func saveTrainer(_ trainer: TrainerData) async {
        guard !cloudUnavailable else { return }
        do {
            let uid = try await ensureSignedIn()
            try await client
                .from("trainers")
                .upsert(TrainerRow(id: uid, data: trainer))
                .execute()
            lastError = nil
        } catch {
            markUnavailable("Cloud save failed: \(classify(error))")
        }
    }

    /// Returns nil on any failure (offline, no cloud save yet, decode mismatch, auth disabled).
    static func loadTrainer() async -> TrainerData? {
        guard !cloudUnavailable else { return nil }
        do {
            let uid = try await ensureSignedIn()
            let row: TrainerRow = try await client
                .from("trainers")
                .select()
                .eq("id", value: uid)
                .single()
                .execute()
                .value
            lastError = nil
            return row.data
        } catch {
            let classified = classify(error)
            // "no rows" is normal for a new account — don't latch unavailable.
            if classified.localizedCaseInsensitiveContains("trainers")
                || classified.localizedCaseInsensitiveContains("anonymous") {
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
            _ = try await ensureSignedIn()
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
