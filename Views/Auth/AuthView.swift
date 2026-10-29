import SwiftUI

@MainActor
public struct AuthView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var viewModel: AuthViewModel
    public let onAuthenticated: () -> Void
    
    public init(
        viewModel: AuthViewModel,
        onAuthenticated: @escaping () -> Void = {}
    ) {
        _viewModel = StateObject(wrappedValue: viewModel)
        self.onAuthenticated = onAuthenticated
    }
    
    public init(onAuthenticated: @escaping () -> Void = {}) {
        _viewModel = StateObject(wrappedValue: AuthViewModel())
        self.onAuthenticated = onAuthenticated
    }
    
    public var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                // Header
                VStack(spacing: 8) {
                    Image(systemName: "cloud.fill")
                        .font(.system(size: 50))
                        .foregroundColor(.blue)
                    
                    Text(viewModel.isSignUp ? "Create FitTrack Account" : "Welcome Back")
                        .font(.title2)
                        .fontWeight(.bold)
                    
                    Text("Enable seamless multi-device cloud backup with Supabase PostgreSQL.")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                }
                .padding(.top, 20)
                
                // Form Card
                VStack(spacing: 16) {
                    TextField("Email", text: $viewModel.email)
                        .keyboardType(.emailAddress)
                        .autocapitalization(.none)
                        .padding()
                        .background(Color.fitSecondaryBackground)
                        .cornerRadius(12)
                    
                    SecureField("Password (min 6 characters)", text: $viewModel.password)
                        .padding()
                        .background(Color.fitSecondaryBackground)
                        .cornerRadius(12)
                    
                    if let error = viewModel.errorMessage {
                        Text(error)
                            .font(.caption)
                            .foregroundColor(.red)
                            .multilineTextAlignment(.center)
                    }
                    
                    Button {
                        Task {
                            let success = await viewModel.authenticate()
                            if success {
                                onAuthenticated()
                                dismiss()
                            }
                        }
                    } label: {
                        if viewModel.isLoading {
                            ProgressView()
                                .tint(.white)
                        } else {
                            Text(viewModel.isSignUp ? "Sign Up" : "Sign In")
                                .font(.headline)
                                .foregroundColor(.white)
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(viewModel.isValid ? Color.blue : Color.gray.opacity(0.4))
                    .cornerRadius(12)
                    .disabled(!viewModel.isValid || viewModel.isLoading)
                }
                .padding()
                .background(Color.fitCardBackground)
                .cornerRadius(16)
                .padding(.horizontal)
                
                // Toggle Mode Button
                Button {
                    withAnimation {
                        viewModel.isSignUp.toggle()
                        viewModel.errorMessage = nil
                    }
                } label: {
                    Text(viewModel.isSignUp ? "Already have an account? Sign In" : "Don't have an account? Create One")
                        .font(.subheadline)
                        .foregroundColor(.blue)
                }
                
                Spacer()
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") { dismiss() }
                }
            }
        }
    }
}
