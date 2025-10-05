//
//  LoginView.swift
//  Family Planning
//
//  Created by Marwan Hazman on 05/10/2025.
//


// Views/LoginView.swift
import SwiftUI

struct LoginView: View {
    @StateObject private var authManager = AuthManager.shared
    @State private var email = ""
    @State private var password = ""
    @State private var isShowingSignUp = false
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                // Header
                VStack(spacing: 10) {
                    Image(systemName: "calendar.circle.fill")
                        .font(.system(size: 80))
                        .foregroundColor(.blue)
                    
                    Text("Family Events")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                    
                    Text("Organize your family schedule")
                        .foregroundColor(.secondary)
                }
                .padding(.top, 50)
                
                // Form
                VStack(spacing: 16) {
                    TextField("Email", text: $email)
                        .textContentType(.emailAddress)
                        .keyboardType(.emailAddress)
                        .autocapitalization(.none)
                        .padding()
                        .background(Color(.systemGray6))
                        .cornerRadius(10)
                    
                    SecureField("Password", text: $password)
                        .textContentType(.password)
                        .padding()
                        .background(Color(.systemGray6))
                        .cornerRadius(10)
                    
                    if let errorMessage = authManager.errorMessage {
                        Text(errorMessage)
                            .foregroundColor(.red)
                            .font(.caption)
                    }
                    
                    Button(action: login) {
                        if authManager.isLoading {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        } else {
                            Text("Sign In")
                                .fontWeight(.semibold)
                        }
                    }
                    .disabled(email.isEmpty || password.isEmpty || authManager.isLoading)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(10)
                    
                    Button("Forgot Password?") {
                        resetPassword()
                    }
                    .foregroundColor(.blue)
                }
                .padding(.horizontal)
                
                Spacer()
                
                // Sign up link
                HStack {
                    Text("Don't have an account?")
                    Button("Sign Up") {
                        isShowingSignUp = true
                    }
                    .foregroundColor(.blue)
                }
                .padding(.bottom, 30)
            }
            .sheet(isPresented: $isShowingSignUp) {
                SignUpView()
            }
        }
    }
    
    private func login() {
        authManager.signIn(email: email, password: password) { success in
            if success {
                // Login successful, handled by auth state listener
            }
        }
    }
    
    private func resetPassword() {
        guard !email.isEmpty else { return }
        
        authManager.resetPassword(email: email) { success in
            if success {
                authManager.errorMessage = "Password reset email sent!"
            }
        }
    }
}