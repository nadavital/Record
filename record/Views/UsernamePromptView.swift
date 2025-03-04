//
//  UsernamePromptView.swift
//  record
//
//  Created by Nadav Avital on 2/25/25.
//


//
//  UsernamePromptView.swift
//  record
//
//  Created by Nadav Avital on 2/25/25.
//

import SwiftUI

struct UsernamePromptView: View {
    @EnvironmentObject var authManager: AuthManager
    @EnvironmentObject var profileManager: UserProfileManager
    @Binding var isPresented: Bool
    
    @State private var username = ""
    @State private var errorMessage: String?
    @State private var showError = false
    
    var body: some View {
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
                    .padding(.bottom, 10)
                
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
                
                if let errorMessage = errorMessage {
                    Text(errorMessage)
                        .font(.caption)
                        .foregroundColor(.red)
                        .padding(.top, -10)
                }
                
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
                        .fill(username.count >= 3 ? Color.accentColor : Color.gray)
                )
                .disabled(username.count < 3 || authManager.isLoading)
                
                Button("Maybe Later") {
                    isPresented = false
                }
                .foregroundColor(.white.opacity(0.6))
                .padding(.top, 10)
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
        
        print("UsernamePromptView - Saving username: \(username)")
        errorMessage = nil
        
        authManager.updateUsername(username: username) { success, error in
            if success {
                print("UsernamePromptView - Username saved successfully")
                
                // Update profile manager with the username
                DispatchQueue.main.async {
                    profileManager.username = username
                    isPresented = false
                }
            } else {
                print("UsernamePromptView - Failed to save username: \(error?.localizedDescription ?? "Unknown error")")
                DispatchQueue.main.async {
                    errorMessage = error?.localizedDescription ?? "Failed to save username"
                }
            }
        }
    }
}
