import Foundation

public protocol SupabaseAuthServiceProtocol: Sendable {
    func signUp(email: String, password: String) async throws -> UUID
    func signIn(email: String, password: String) async throws -> UUID
    func signOut() async throws
    func currentUserId() -> UUID?
    func currentUserEmail() -> String?
    func isAuthenticated() -> Bool
}
