import Foundation

public enum AppEnvironment {
    
    public static var supabaseURL: URL {
        if let urlString = Bundle.main.object(forInfoDictionaryKey: "SUPABASE_URL") as? String,
           let url = URL(string: urlString),
           !urlString.contains("your-project-id") {
            return url
        }
        // Fallback default for development / mock preview testing
        return URL(string: "https://your-project-id.supabase.co")!
    }
    
    public static var supabaseAnonKey: String {
        if let key = Bundle.main.object(forInfoDictionaryKey: "SUPABASE_ANON_KEY") as? String,
           !key.contains("your-public-anon-key-here") {
            return key
        }
        return "your-public-anon-key-here"
    }
    
    public static var isConfigured: Bool {
        let key = supabaseAnonKey
        let url = supabaseURL.absoluteString
        return !key.contains("your-public-anon-key-here") && !url.contains("your-project-id")
    }
}
