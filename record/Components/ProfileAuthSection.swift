//
//  ProfileAuthSection.swift
//  record
//
//  Created by Nadav Avital on 2/25/25.
//

import SwiftUI

struct ProfileAuthSection: View {
    @EnvironmentObject var authManager: AuthManager
    @State private var showSignOutConfirmation = false
    @State private var showUsernamePrompt = false
    @State private var newUsername = ""
    
    var body: some View {
        VStack(alignment: .leading, spacing: 15) {
            sectionHeader
            
            accountInfoView
            
            // Actions
            VStack(spacing: 12) {
                // Add username button if no username is set
                if authManager.username == nil || authManager.username!.isEmpty {
                    Button(action: {
                        showUsernamePrompt = true
                    }) {
                        HStack {
                            Image(systemName: "person.badge.plus")
                            Text("Set Username")
                        }
                        .font(.subheadline)
                        .foregroundColor(.blue)
                        .padding(.vertical, 10)
                    }
                }
                
                Button(action: {
                    showSignOutConfirmation = true
                }) {
                    HStack {
                        Image(systemName: "rectangle.portrait.and.arrow.right")
                        Text("Sign Out")
                    }
                    .font(.subheadline)
                    .foregroundColor(.white.opacity(0.7))
                    .padding(.vertical, 10)
                }
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color.white.opacity(0.03))
                .overlay(
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(Color.white.opacity(0.1), lineWidth: 0.5)
                )
        )
        .alert(isPresented: $showSignOutConfirmation) {
            Alert(
                title: Text("Sign Out"),
                message: Text("Are you sure you want to sign out?"),
                primaryButton: .destructive(Text("Sign Out")) {
                    authManager.signOut()
                },
                secondaryButton: .cancel()
            )
        }
        .sheet(isPresented: $showUsernamePrompt) {
            usernamePromptView
        }
    }
    
    private var sectionHeader: some View {
        HStack {
            Text("Account")
                .font(.headline)
                .foregroundColor(.white)
            
            Spacer()
            
            // Connected status
            HStack(spacing: 4) {
                Circle()
                    .fill(Color.green)
                    .frame(width: 8, height: 8)
                
                Text("Connected with Apple")
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.6))
            }
        }
    }
    
    private var accountInfoView: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Username
            HStack {
                Text("Username:")
                    .font(.subheadline)
                    .foregroundColor(.white.opacity(0.6))
                
                if let username = authManager.username, !username.isEmpty {
                    Text(username)
                        .font(.subheadline)
                        .foregroundColor(.white)
                } else {
                    Text("Not set")
                        .font(.subheadline)
                        .foregroundColor(.red.opacity(0.8))
                }
            }
            
            // User ID (masked)
            if let userId = authManager.userId {
                HStack {
                    Text("Apple ID:")
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.6))
                    
                    Text(maskIdentifier(userId))
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.7))
                }
            }
            
            // Email (if available)
            if let email = authManager.email {
                HStack {
                    Text("Email:")
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.6))
                    
                    Text(email)
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.7))
                }
            }
            
            Divider()
                .background(Color.white.opacity(0.2))
                .padding(.vertical, 5)
        }
    }
    
    // Helper to mask the user identifier for privacy
    private func maskIdentifier(_ identifier: String) -> String {
        if identifier.count > 8 {
            let prefix = String(identifier.prefix(4))
            let suffix = String(identifier.suffix(4))
            return "\(prefix)•••••\(suffix)"
        } else {
            return identifier
        }
    }
    
    // Username prompt view
    private var usernamePromptView: some View {
        ZStack {
            // Background
            Color.black.opacity(0.6).ignoresSafeArea()
            
            // Content
            VStack(spacing: 20) {
                Text("Create Username")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                
                Text("Please create a unique username for your profile")
                    .font(.subheadline)
                    .foregroundColor(.white.opacity(0.8))
                    .multilineTextAlignment(.center)
                
                TextField("Username", text: $newUsername)
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
                        Text("Save Username")
                            .fontWeight(.semibold)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding()
                    }
                }
                .background(
                    RoundedRectangle(cornerRadius: 10)
                        .fill(newUsername.count >= 3 ? Color.blue : Color.gray)
                )
                .disabled(newUsername.count < 3 || authManager.isLoading)
                
                Button("Cancel") {
                    showUsernamePrompt = false
                }
                .foregroundColor(.white.opacity(0.6))
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
        guard newUsername.count >= 3 else { return }
        
        print("Attempting to save username from profile: \(newUsername)")
        authManager.updateUsername(username: newUsername) { success, error in
            if success {
                print("Username saved successfully from profile")
                showUsernamePrompt = false
            } else {
                print("Failed to save username from profile: \(error?.localizedDescription ?? "Unknown error")")
            }
        }
    }
}
