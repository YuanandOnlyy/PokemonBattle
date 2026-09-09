import Foundation
import Supabase

/// Cloud sync for `TrainerData`, layered on top of the existing UserDefaults save in
/// `GameViewModel`. UserDefaults remains the source of truth for offline play; this mirrors saves
/// up to Supabase under the signed-in user's id so progress can be restored on a new device.
///
/// No login UI exists yet, so this uses Supabase's anonymous auth: each install gets a stable user
/// id on first launch that persists across app relaunches (but not across reinstalls/devices unless
/// a real sign-in method is added later).
enum SupabaseService {
    static let client = SupabaseClient(
        supabaseURL: URL(string: "https://tmlgvlstwsgmnkmwloty.supabase.co")!,
        supabaseKey: "sb_publishable_IeNJ_xqb0AtVHIbJP34JJg_48kEu3yU"
    )

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

    /// Fire-and-forget upload; failures (offline, etc.) are silently ignored since UserDefaults
    /// already holds the authoritative local copy.
    static func saveTrainer(_ trainer: TrainerData) async {
        guard let uid = try? await ensureSignedIn() else { return }
        try? await client
            .from("trainers")
            .upsert(TrainerRow(id: uid, data: trainer))
            .execute()
    }

    /// Returns nil on any failure (offline, no cloud save yet, decode mismatch).
    static func loadTrainer() async -> TrainerData? {
        guard let uid = try? await ensureSignedIn() else { return nil }
        let row: TrainerRow? = try? await client
            .from("trainers")
            .select()
            .eq("id", value: uid)
            .single()
            .execute()
            .value
        return row?.data
    }
}
