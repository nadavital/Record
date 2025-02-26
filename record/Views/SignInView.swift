//
//  SignInView.swift
//  record
//
//  Created by Nadav Avital on 2/25/25.
//

import SwiftUI
import AuthenticationServices
import Firebase

struct SignInView: View {
    @EnvironmentObject var profileManager: UserProfileManager
    @EnvironmentObject var authManager: AuthManager
    @Environment(\.colorScheme) var colorScheme
    
    @State private var showUsernamePrompt = false
    @State private var username = ""
    
    var body: some View {
        ZStack {
            // Background
            LinearGradient(
                gradient: Gradient(colors: [
                    Color.black,
                    Color(red: 0.1, green: 0.05, blue: 0.2)
                ]),
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()
            
            VStack(spacing: 30) {
                // App logo
                ZStack {
                    Circle()
                        .fill(
                            LinearGradient(
                                gradient: Gradient(colors: [
                                    profileManager.accentColor.opacity(0.3),
                                    profileManager.accentColor.opacity(0.1)
                                ]),
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 150, height: 150)
                        .overlay(
                            Circle()
                                .stroke(
                                    LinearGradient(
                                        gradient: Gradient(colors: [
                                            profileManager.accentColor,
                                            profileManager.accentColor.opacity(0.5)
                                        ]),
                                        startPoint: .top,
                                        endPoint: .bottom
                                    ),
                                    lineWidth: 2
                                )
                        )
                        .shadow(color: profileManager.accentColor.opacity(0.5), radius: 10)
                    
                    Image(systemName: "music.note.list")
                        .font(.system(size: 60))
                        .foregroundColor(.white)
                }
                
                Text("Record")
                    .font(.system(size: 46, weight: .bold))
                    .foregroundColor(.white)
                
                Text("Rank, share, and explore your favorite music")
                    .font(.headline)
                    .foregroundColor(.white.opacity(0.8))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
                
                Spacer()
                
                // Sign in with Apple button
                SignInWithAppleButton(
                    onRequest: configureAppleSignInRequest,
                    onCompletion: handleAppleSignInCompletion
                )
                .signInWithAppleButtonStyle(colorScheme == .dark ? .white : .black)
                .frame(height: 50)
                .padding(.horizontal, 40)
                
                Text("By signing in, you agree to our Terms of Service and Privacy Policy")
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.6))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 20)
                    .padding(.top, 20)
                    .padding(.bottom, 40)
            }
            .padding()
            
            // Username prompt
            if showUsernamePrompt {
                usernamePromptView
                    .transition(.opacity)
                    .zIndex(1)
            }
        }
        .alert(isPresented: $authManager.showError) {
            Alert(
                title: Text("Error"),
                message: Text(authManager.errorMessage ?? "An unknown error occurred"),
                dismissButton: .default(Text("OK"))
            )
        }
        .onAppear {
            print("SignInView appeared - checking username status")
            // Force username prompt to show if authenticated but no username
            if authManager.isAuthenticated {
                if authManager.username == nil || authManager.username!.isEmpty {
                    print("User is authenticated but has no username - showing prompt")
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                        showUsernamePrompt = true
                    }
                } else {
                    print("User already has username: \(authManager.username!)")
                }
            } else {
                print("User is not authenticated")
            }
        }
    }
    
    // Configure the Sign in with Apple request
    private func configureAppleSignInRequest(_ request: ASAuthorizationAppleIDRequest) {
        print("Configuring Apple Sign In request")
        request.requestedScopes = [.fullName, .email]
        let nonce = authManager.prepareNonceForSignIn()
        request.nonce = nonce
    }
    
    // Handle Sign in with Apple completion
    private func handleAppleSignInCompletion(_ result: Result<ASAuthorization, Error>) {
        print("Apple Sign In completion received")
        switch result {
        case .success(let authorization):
            print("Sign in with Apple succeeded")
            if let appleIDCredential = authorization.credential as? ASAuthorizationAppleIDCredential {
                print("Processing Apple ID credential for user: \(appleIDCredential.user)")
                
                authManager.handleAppleSignIn(credential: appleIDCredential) { success in
                    if success {
                        print("Successfully authenticated with Apple ID")
                        
                        // Check if we need a username
                        if authManager.username == nil || authManager.username!.isEmpty {
                            print("No username found - showing username prompt")
                            DispatchQueue.main.async {
                                showUsernamePrompt = true
                            }
                        } else {
                            print("Username already exists: \(authManager.username!)")
                            // Already has username, update profile
                            updateProfileWithAuthData()
                        }
                    } else {
                        print("Authentication completion handler returned failure")
                    }
                }
            } else {
                print("Error: Received unexpected credential type")
            }
        case .failure(let error):
            // Check if this is a cancellation error
            if (error as NSError).code == ASAuthorizationError.canceled.rawValue {
                print("Sign in with Apple was cancelled by user")
                // Just ignore the cancellation - don't show an error
            } else {
                print("Sign in with Apple failed: \(error.localizedDescription)")
                authManager.errorMessage = error.localizedDescription
                authManager.showError = true
            }
        }
    }
    
    // Username prompt overlay
    private var usernamePromptView: some View {
        ZStack {
            // Dimmed background
            Color.black.opacity(0.6)
                .ignoresSafeArea()
            
            // Prompt card
            VStack(spacing: 20) {
                Text("Create Username")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                
                Text("Please create a unique username for your profile")
                    .font(.subheadline)
                    .foregroundColor(.white.opacity(0.8))
                    .multilineTextAlignment(.center)
                
                TextField("Username", text: $username)
                    .foregroundColor(.white)
                    .padding()
                    .background(
                        RoundedRectangle(cornerRadius: 10)
                            .fill(Color.white.opacity(0.1))
                            .overlay(
                                RoundedRectangle(cornerRadius: 10)
                                    .stroke(Color.white.opacity(0.3), lineWidth: 1)
                            )
                    )
                    .autocapitalization(.none)
                    .disableAutocorrection(true)
                
                Button(action: saveUsername) {
                    if authManager.isLoading {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                            .frame(maxWidth: .infinity)
                            .padding()
                    } else {
                        Text("Continue")
                            .fontWeight(.semibold)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding()
                    }
                }
                .background(
                    RoundedRectangle(cornerRadius: 10)
                        .fill(username.count >= 3 ? profileManager.accentColor : Color.gray)
                )
                .disabled(username.count < 3 || authManager.isLoading)
            }
            .padding(30)
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(Color.black.opacity(0.9))
                    .overlay(
                        RoundedRectangle(cornerRadius: 20)
                            .stroke(Color.white.opacity(0.1), lineWidth: 0.5)
                    )
            )
            .shadow(color: Color.black.opacity(0.5), radius: 20)
            .padding()
        }
    }
    
    private func saveUsername() {
        guard username.count >= 3 else { return }
        
        print("Attempting to save username: \(username)")
        authManager.updateUsername(username: username) { success, error in
            if success {
                print("Username saved successfully")
                showUsernamePrompt = false
                updateProfileWithAuthData()
            } else {
                print("Failed to save username: \(error?.localizedDescription ?? "Unknown error")")
            }
        }
    }
    
    private func updateProfileWithAuthData() {
        print("Updating profile with auth data")
        // Update the profile manager with the authenticated user's data
        if let username = authManager.username {
            print("Setting profile username to: \(username)")
            profileManager.username = username
        }
    }
}

