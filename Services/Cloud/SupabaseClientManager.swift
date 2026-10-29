import Foundation
import Supabase

public final class SupabaseClientManager: @unchecked Sendable {
    
    public static let shared = SupabaseClientManager()
    
    public let client: SupabaseClient
    
    public init(
        supabaseURL: URL = AppEnvironment.supabaseURL,
        supabaseAnonKey: String = AppEnvironment.supabaseAnonKey
    ) {
        self.client = SupabaseClient(
            supabaseURL: supabaseURL,
            supabaseKey: supabaseAnonKey
        )
    }
}
