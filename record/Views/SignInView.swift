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
        NavigationView {
            ZStack {
                Color(.systemBackground)
                    .ignoresSafeArea()
                
                VStack(spacing: 32) {
                    Spacer()
                    
                    // App Icon
                    VStack(spacing: 16) {
                        ZStack {
                            Circle()
                                .fill(.ultraThinMaterial)
                                .frame(width: 120, height: 120)
                            
                            Image(systemName: "music.note.list")
                                .font(.system(size: 40, weight: .semibold))
                                .foregroundStyle(profileManager.accentColor)
                        }
                        
                        VStack(spacing: 8) {
                            Text("Record")
                                .font(.system(size: 34, weight: .bold))
                                .foregroundStyle(.primary)
                            
                            Text("Rank, share, and explore your favorite music")
                                .font(.body)
                                .foregroundStyle(.secondary)
                                .multilineTextAlignment(.center)
                                .padding(.horizontal)
                        }
                    }
                    
                    Spacer()
                    
                    // Sign in button
                    VStack(spacing: 16) {
                        SignInWithAppleButton(
                            onRequest: configureAppleSignInRequest,
                            onCompletion: handleAppleSignInCompletion
                        )
                        .signInWithAppleButtonStyle(colorScheme == .dark ? .white : .black)
                        .frame(height: 50)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                        
                        Text("By signing in, you agree to our Terms of Service and Privacy Policy")
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)
                    }
                    .padding(.bottom, 32)
                }
                .padding()
                
                // Username prompt overlay
                if showUsernamePrompt {
                    Color(.systemBackground)
                        .opacity(0.98)
                        .ignoresSafeArea()
                        .overlay(
                            VStack(spacing: 24) {
                                Text("Create Username")
                                    .font(.title2)
                                    .fontWeight(.bold)
                                
                                Text("Please create a unique username for your profile")
                                    .font(.body)
                                    .foregroundStyle(.secondary)
                                    .multilineTextAlignment(.center)
                                
                                TextField("Username", text: $username)
                                    .textFieldStyle(.roundedBorder)
                                    .textInputAutocapitalization(.never)
                                    .disableAutocorrection(true)
                                    .padding(.vertical)
                                
                                Button(action: saveUsername) {
                                    Group {
                                        if authManager.isLoading {
                                            ProgressView()
                                        } else {
                                            Text("Continue")
                                                .fontWeight(.semibold)
                                        }
                                    }
                                    .frame(maxWidth: .infinity)
                                    .padding()
                                    .background(username.count >= 3 ? profileManager.accentColor : Color.gray)
                                    .foregroundColor(.white)
                                    .clipShape(RoundedRectangle(cornerRadius: 12))
                                }
                                .disabled(username.count < 3 || authManager.isLoading)
                            }
                            .padding(24)
                            .transition(.opacity)
                        )
                        .zIndex(1)
                }
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

