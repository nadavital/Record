//
//  SignInViewModel.swift
//  record
//
//  Created by Nadav Avital on 3/4/25.
//

import SwiftUI
import AuthenticationServices
import CryptoKit

class SignInViewModel: ObservableObject {
    @Published var username = ""
    @Published var showUsernamePrompt = false
    
    private let authManager: AuthManager
    private let profileManager: UserProfileManager
    
    init(authManager: AuthManager, profileManager: UserProfileManager) {
        self.authManager = authManager
        self.profileManager = profileManager
    }

    // Configure the Sign in with Apple request
    func configureAppleSignInRequest(_ request: ASAuthorizationAppleIDRequest) {
        print("Configuring Apple Sign In request")
        request.requestedScopes = [.fullName, .email]
        let nonce = authManager.prepareNonceForSignIn()
        request.nonce = nonce
    }
    
    // Handle Sign in with Apple completion
    func handleAppleSignInCompletion(_ result: Result<ASAuthorization, Error>) {
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
                        if self.authManager.username == nil || self.authManager.username!.isEmpty {
                            print("No username found - showing username prompt")
                            DispatchQueue.main.async {
                                self.showUsernamePrompt = true
                            }
                        } else {
                            print("Username already exists: \(self.authManager.username!)")
                            // Already has username, update profile
                            self.updateProfileWithAuthData()
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
    
    func saveUsername() {
        guard username.count >= 3 else { return }
        
        print("Attempting to save username: \(username)")
        authManager.updateUsername(username: username) { success, error in
            if success {
                print("Username saved successfully")
                self.showUsernamePrompt = false
                self.updateProfileWithAuthData()
            } else {
                print("Failed to save username: \(error?.localizedDescription ?? "Unknown error")")
            }
        }
    }
    
    func updateProfileWithAuthData() {
        print("Updating profile with auth data")
        // Update the profile manager with the authenticated user's data
        if let username = authManager.username {
            print("Setting profile username to: \(username)")
            self.profileManager.username = username
        }
    }
}
