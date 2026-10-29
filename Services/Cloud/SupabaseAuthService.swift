import Foundation
import Supabase

public enum AuthError: LocalizedError, Sendable {
    case invalidCredentials
    case userAlreadyExists
    case unauthenticated
    case networkError(String)
    
    public var errorDescription: String? {
        switch self {
        case .invalidCredentials:
            return "Invalid email or password. Please try again."
        case .userAlreadyExists:
            return "An account with this email already exists."
        case .unauthenticated:
            return "No authenticated user session found."
        case .networkError(let message):
            return "Network error during authentication: \(message)"
        }
    }
}

public final class SupabaseAuthService: SupabaseAuthServiceProtocol, @unchecked Sendable {
    
    public static let shared = SupabaseAuthService()
    
    private let clientManager: SupabaseClientManager
    private let userDefaultsKey = "fittrack.auth.userId"
    private let userEmailKey = "fittrack.auth.userEmail"
    
    public init(clientManager: SupabaseClientManager = .shared) {
        self.clientManager = clientManager
    }
    
    public func signUp(email: String, password: String) async throws -> UUID {
        if !AppEnvironment.isConfigured {
            // Development fallback when credentials are not yet configured
            let mockId = UUID()
            saveSessionLocally(userId: mockId, email: email)
            return mockId
        }
        
        do {
            let response = try await clientManager.client.auth.signUp(
                email: email,
                password: password
            )
            let userId = response.user.id
            saveSessionLocally(userId: userId, email: email)
            return userId
        } catch {
            throw AuthError.networkError(error.localizedDescription)
        }
    }
    
    public func signIn(email: String, password: String) async throws -> UUID {
        if !AppEnvironment.isConfigured {
            let mockId = UUID(uuidString: UserDefaults.standard.string(forKey: userDefaultsKey) ?? "") ?? UUID()
            saveSessionLocally(userId: mockId, email: email)
            return mockId
        }
        
        do {
            let session = try await clientManager.client.auth.signIn(
                email: email,
                password: password
            )
            let userId = session.user.id
            saveSessionLocally(userId: userId, email: email)
            return userId
        } catch {
            throw AuthError.networkError(error.localizedDescription)
        }
    }
    
    public func signOut() async throws {
        if AppEnvironment.isConfigured {
            try? await clientManager.client.auth.signOut()
        }
        UserDefaults.standard.removeObject(forKey: userDefaultsKey)
        UserDefaults.standard.removeObject(forKey: userEmailKey)
    }
    
    public func currentUserId() -> UUID? {
        if let idString = UserDefaults.standard.string(forKey: userDefaultsKey) {
            return UUID(uuidString: idString)
        }
        return clientManager.client.auth.currentSession?.user.id
    }
    
    public func currentUserEmail() -> String? {
        return UserDefaults.standard.string(forKey: userEmailKey) ?? clientManager.client.auth.currentSession?.user.email
    }
    
    public func isAuthenticated() -> Bool {
        return currentUserId() != nil
    }
    
    private func saveSessionLocally(userId: UUID, email: String) {
        UserDefaults.standard.set(userId.uuidString, forKey: userDefaultsKey)
        UserDefaults.standard.set(email, forKey: userEmailKey)
    }
}
