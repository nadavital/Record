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
            Color.black.opacity(0.2)
                .ignoresSafeArea()
            
            // Prompt card
            VStack(spacing: 20) {
                Text("Create Username")
                    .font(.title2)
                    .fontWeight(.bold)
                
                Text("Please choose a unique username")
                    .font(.subheadline)
                    .foregroundColor(Color(.secondaryLabel))
                    .multilineTextAlignment(.center)
                    .padding(.bottom, 10)
                
                TextField("Username", text: $username)
                    .padding()
                    .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 10))
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
                            .progressViewStyle(CircularProgressViewStyle(tint: .accent))
                            .frame(maxWidth: .infinity)
                            .padding()
                    } else {
                        Text("Save")
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
            }
            .padding(30)
            .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 20))
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

#Preview {
    @Previewable @State var isPresented = true
    UsernamePromptView(isPresented: $isPresented)
        .environmentObject(AuthManager.shared)
        .environmentObject(UserProfileManager())
}
