import Foundation
import Combine

@MainActor
public final class AuthViewModel: ObservableObject {
    
    @Published public var email: String = ""
    @Published public var password: String = ""
    @Published public var isSignUp: Bool = false
    @Published public var isLoading: Bool = false
    @Published public var errorMessage: String? = nil
    @Published public var isAuthenticated: Bool = false
    @Published public var currentUserEmail: String? = nil
    
    private let authService: SupabaseAuthServiceProtocol
    
    public init(authService: SupabaseAuthServiceProtocol = SupabaseAuthService.shared) {
        self.authService = authService
        self.isAuthenticated = authService.isAuthenticated()
        self.currentUserEmail = authService.currentUserEmail()
    }
    
    public var isValid: Bool {
        email.contains("@") && email.contains(".") && password.count >= 6
    }
    
    public func authenticate() async -> Bool {
        guard isValid else {
            errorMessage = "Please enter a valid email and a password of at least 6 characters."
            return false
        }
        
        isLoading = true
        errorMessage = nil
        
        do {
            if isSignUp {
                _ = try await authService.signUp(email: email, password: password)
            } else {
                _ = try await authService.signIn(email: email, password: password)
            }
            self.isAuthenticated = true
            self.currentUserEmail = authService.currentUserEmail()
            self.isLoading = false
            return true
        } catch {
            self.errorMessage = error.localizedDescription
            self.isLoading = false
            return false
        }
    }
    
    public func signOut() async {
        do {
            try await authService.signOut()
            self.isAuthenticated = false
            self.currentUserEmail = nil
        } catch {
            self.errorMessage = "Failed to sign out: \(error.localizedDescription)"
        }
    }
}
