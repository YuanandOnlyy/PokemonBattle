import Foundation
import Supabase

/// Single shared Supabase client. Credentials come from `Secrets.plist` (gitignored) or
/// Info.plist keys `SUPABASE_URL` / `SUPABASE_ANON_KEY` — never hardcode them in source.
enum SupabaseClientProvider {
    static let shared: SupabaseClient = {
        let config = loadConfig()
        guard let supabaseURL = URL(string: config.url), !config.key.isEmpty else {
            fatalError("Missing Supabase configuration. Copy Secrets.example.plist → Secrets.plist and fill in SUPABASE_URL / SUPABASE_ANON_KEY.")
        }
        return SupabaseClient(supabaseURL: supabaseURL, supabaseKey: config.key)
    }()

    private static func loadConfig() -> (url: String, key: String) {
        if let plistURL = Bundle.main.url(forResource: "Secrets", withExtension: "plist"),
           let dict = NSDictionary(contentsOf: plistURL) as? [String: Any],
           let url = dict["SUPABASE_URL"] as? String,
           let key = dict["SUPABASE_ANON_KEY"] as? String,
           !url.contains("YOUR_PROJECT"),
           !key.contains("YOUR_SUPABASE") {
            return (url, key)
        }

        let info = Bundle.main.infoDictionary
        if let url = info?["SUPABASE_URL"] as? String,
           let key = info?["SUPABASE_ANON_KEY"] as? String {
            return (url, key)
        }

        fatalError("Missing Supabase configuration in Secrets.plist / Info.plist")
    }
}
