//
//  UsernameSetupView.swift
//  record
//
//  Created by Nadav Avital on 2/25/25.
//

import SwiftUI
import Firebase
import FirebaseFirestore

struct UsernameSetupView: View {
    @EnvironmentObject var authManager: AuthenticationManager
    
    @State private var username: String = ""
    @State private var isCheckingUsername = false
    @State private var usernameError: String? = nil
    @State private var isSubmitting = false
    @State private var showAlert = false
    @State private var alertTitle = ""
    @State private var alertMessage = ""
    
    private let minUsernameLength = 3
    private let maxUsernameLength = 20
    
    var body: some View {
        NavigationView {
            ZStack {
                // Background gradient
                LinearGradient(
                    gradient: Gradient(colors: [
                        Color.black.opacity(0.9),
                        Color(red: 0.1, green: 0.05, blue: 0.2)
                    ]),
                    startPoint: .top,
                    endPoint: .bottom
                )
                .ignoresSafeArea()
                
                VStack(spacing: 30) {
                    // Header information
                    VStack(spacing: 15) {
                        Text("Create Your Username")
                            .font(.system(size: 26, weight: .bold, design: .rounded))
                            .foregroundColor(.white)
                            .multilineTextAlignment(.center)
                        
                        Text("This is how others will find and recognize you")
                            .font(.subheadline)
                            .foregroundColor(.white.opacity(0.8))
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)
                    }
                    .padding(.top, 30)
                    
                    // Suggested username
                    if let suggestedUsername = authManager.userProfile?.username {
                        Button {
                            username = suggestedUsername
                            validateUsername()
                        } label: {
                            VStack(alignment: .leading, spacing: 8) {
                                Text("We suggest")
                                    .font(.caption)
                                    .foregroundColor(.white.opacity(0.6))
                                
                                Text(suggestedUsername)
                                    .font(.headline)
                                    .foregroundColor(Color(red: 0.94, green: 0.3, blue: 0.9))
                                    .padding(.horizontal, 15)
                                    .padding(.vertical, 8)
                                    .background(
                                        RoundedRectangle(cornerRadius: 10)
                                            .fill(Color.white.opacity(0.1))
                                    )
                            }
                            .padding(.horizontal)
                        }
                        .padding(.bottom, 10)
                    }
                    
                    // Username input
                    VStack(alignment: .leading, spacing: 10) {
                        Text("Username")
                            .font(.headline)
                            .foregroundColor(.white)
                            .padding(.horizontal)
                        
                        ZStack {
                            RoundedRectangle(cornerRadius: 15)
                                .fill(Color.white.opacity(0.1))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 15)
                                        .stroke(
                                            usernameError == nil ? Color.white.opacity(0.3) : Color.red.opacity(0.7),
                                            lineWidth: 1
                                        )
                                )
                            
                            TextField("Enter username", text: $username)
                                .font(.system(size: 17, weight: .medium))
                                .foregroundColor(.white)
                                .padding(.horizontal, 15)
                                .autocapitalization(.none)
                                .disableAutocorrection(true)
                                .onChange(of: username) { _ in
                                    validateUsername()
                                }
                            
                            if isCheckingUsername {
                                HStack {
                                    Spacer()
                                    ProgressView()
                                        .progressViewStyle(CircularProgressViewStyle(tint: .white.opacity(0.8)))
                                        .padding(.trailing, 15)
                                }
                            } else if usernameError == nil && !username.isEmpty {
                                HStack {
                                    Spacer()
                                    Image(systemName: "checkmark.circle.fill")
                                        .foregroundColor(.green)
                                        .padding(.trailing, 15)
                                }
                            }
                        }
                        .frame(height: 50)
                        .padding(.horizontal)
                        
                        if let error = usernameError {
                            Text(error)
                                .font(.caption)
                                .foregroundColor(.red.opacity(0.8))
                                .padding(.horizontal, 20)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                        
                        Text("Username must be \(minUsernameLength)-\(maxUsernameLength) characters and can only contain letters, numbers, periods, and underscores.")
                            .font(.caption)
                            .foregroundColor(.white.opacity(0.6))
                            .padding(.horizontal, 20)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    
                    Spacer()
                    
                    // Create button
                    Button {
                        isSubmitting = true
                        saveUsername()
                    } label: {
                        HStack {
                            Text("Continue")
                                .font(.headline)
                            
                            if isSubmitting {
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                    .padding(.leading, 5)
                            }
                        }
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(
                            isUsernameValid()
                                ? Color(red: 0.94, green: 0.3, blue: 0.9).opacity(0.8)
                                : Color.gray.opacity(0.5)
                        )
                        .cornerRadius(15)
                        .padding(.bottom, 10)
                    }
                    .disabled(!isUsernameValid() || isSubmitting)
                    .padding(.horizontal)
                    .padding(.bottom, 30)
                }
                .alert(isPresented: $showAlert) {
                    Alert(
                        title: Text(alertTitle),
                        message: Text(alertMessage),
                        dismissButton: .default(Text("OK"))
                    )
                }
            }
            .navigationBarBackButtonHidden(true)
        }
        .onAppear {
            // Set initial username from Firebase if available
            if let suggestedUsername = authManager.userProfile?.username {
                username = suggestedUsername
                validateUsername()
            }
        }
    }
    
    private func isUsernameValid() -> Bool {
        return usernameError == nil && !username.isEmpty
    }
    
    private func validateUsername() {
        usernameError = nil
        
        // Check for empty username
        if username.isEmpty {
            usernameError = "Username cannot be empty"
            return
        }
        
        // Check username length
        if username.count < minUsernameLength {
            usernameError = "Username must be at least \(minUsernameLength) characters"
            return
        }
        
        if username.count > maxUsernameLength {
            usernameError = "Username must be no more than \(maxUsernameLength) characters"
            return
        }
        
        // Check for invalid characters
        let usernameRegex = "^[a-zA-Z0-9._]+$"
        if !NSPredicate(format: "SELF MATCHES %@", usernameRegex).evaluate(with: username) {
            usernameError = "Username can only contain letters, numbers, periods, and underscores"
            return
        }
        
        // Debounce availability check
        isCheckingUsername = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            self.checkAvailability()
        }
    }
    
    private func checkAvailability() {
        // If username hasn't changed in the last 0.5 seconds
        authManager.checkUsernameAvailability(username: username) { isAvailable, error in
            DispatchQueue.main.async {
                self.isCheckingUsername = false
                
                if let error = error {
                    self.usernameError = "Error checking username: \(error.localizedDescription)"
                    return
                }
                
                if !isAvailable {
                    self.usernameError = "Username is already taken"
                }
            }
        }
    }
    
    private func saveUsername() {
        guard let uid = authManager.currentUser?.uid else {
            showAlert(title: "Error", message: "User is not logged in")
            isSubmitting = false
            return
        }
        
        authManager.reserveUsername(username: username, for: uid) { success, error in
            DispatchQueue.main.async {
                self.isSubmitting = false
                
                if let error = error {
                    self.showAlert(title: "Error", message: "Failed to reserve username: \(error.localizedDescription)")
                    return
                }
                
                if success {
                    // Update the needsUsernameSetup flag in Firestore
                    let db = Firestore.firestore()
                    db.collection("users").document(uid).updateData([
                        "username": self.username,
                        "needsUsernameSetup": false
                    ]) { error in
                        if let error = error {
                            print("Error updating user profile: \(error)")
                            return
                        }
                        
                        // Update local user profile
                        if var profile = self.authManager.userProfile {
                            // Create a new profile with the updated username
                            let updatedProfile = AuthenticationManager.UserProfile(
                                uid: profile.uid,
                                email: profile.email,
                                displayName: profile.displayName,
                                username: self.username
                            )
                            self.authManager.userProfile = updatedProfile
                        }
                        
                        // Dismiss this view
                        DispatchQueue.main.async {
                            // The parent view is listening for changes to isAuthenticated
                            self.authManager.fetchUserProfile()
                        }
                    }
                } else {
                    self.showAlert(title: "Error", message: "Failed to reserve username")
                }
            }
        }
    }
    
    private func showAlert(title: String, message: String) {
        alertTitle = title
        alertMessage = message
        showAlert = true
    }
}

#Preview {
    UsernameSetupView()
        .environmentObject(AuthenticationManager())
}