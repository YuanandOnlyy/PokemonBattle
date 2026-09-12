import Foundation
import Supabase

/// Single shared Supabase client. Credentials come from `Secrets.plist` (gitignored) or
/// Info.plist keys `SUPABASE_URL` / `SUPABASE_ANON_KEY` — never hardcode them in source.
enum SupabaseClientProvider {
    /// False when Secrets.plist / Info.plist keys are missing or still placeholders.
    static let isConfigured: Bool = {
        loadConfig() != nil
    }()

    /// Shared client. Only access when `isConfigured` is true (or after AuthService wired live APIs).
    static let shared: SupabaseClient = {
        guard let config = loadConfig(),
              let supabaseURL = URL(string: config.url),
              !config.key.isEmpty else {
            // Placeholder so `shared` can exist for type-checking; live calls will fail until configured.
            // AuthService convenience init uses Unconfigured* APIs when `isConfigured` is false.
            return SupabaseClient(
                supabaseURL: URL(string: "https://example.supabase.co")!,
                supabaseKey: "missing-secrets-plist"
            )
        }
        return SupabaseClient(supabaseURL: supabaseURL, supabaseKey: config.key)
    }()

    private static func loadConfig() -> (url: String, key: String)? {
        if let plistURL = Bundle.main.url(forResource: "Secrets", withExtension: "plist"),
           let dict = NSDictionary(contentsOf: plistURL) as? [String: Any],
           let url = dict["SUPABASE_URL"] as? String,
           let key = dict["SUPABASE_ANON_KEY"] as? String,
           !url.isEmpty, !key.isEmpty,
           !url.contains("YOUR_PROJECT"),
           !key.contains("YOUR_SUPABASE"),
           !key.contains("missing-secrets") {
            return (url, key)
        }

        let info = Bundle.main.infoDictionary
        if let url = info?["SUPABASE_URL"] as? String,
           let key = info?["SUPABASE_ANON_KEY"] as? String,
           !url.isEmpty, !key.isEmpty,
           !url.hasPrefix("$("),
           !url.contains("YOUR_PROJECT") {
            return (url, key)
        }

        return nil
    }
}
