//
//  recordApp.swift
//  record
//
//  Created by Nadav Avital on 2/14/25.
//

import SwiftUI
import MusicKit
import Firebase

@main
struct recordApp: App {
    // Initialize shared managers
    @StateObject private var userProfileManager = UserProfileManager()
    @StateObject private var musicRankingManager = MusicRankingManager()
    @StateObject private var authManager = AuthManager.shared
    @State private var musicAuthorizationStatus = MusicAuthorization.Status.notDetermined
    @State private var showUsernamePrompt = false
    
    init() {
        // Configure Firebase
        FirebaseApp.configure()
        
        // Set up Firebase debug logging for development
        #if DEBUG
        FirebaseConfiguration.shared.setLoggerLevel(.debug)
        #endif
    }
    
    var body: some Scene {
        WindowGroup {
            ZStack {
                // Main content
                if authManager.isAuthenticated {
                    // Main content when authenticated
                    ContentView()
                        .environmentObject(userProfileManager)
                        .environmentObject(musicRankingManager)
                        .environmentObject(authManager)
                        .onAppear {
                            checkMusicAuthorization()
                            checkIfUsernameNeeded()
                        }
                } else {
                    // Sign in view when not authenticated
                    SignInView()
                        .environmentObject(userProfileManager)
                        .environmentObject(authManager)
                }
                
                // Show a modal if Apple Music authorization is needed
                if authManager.isAuthenticated && musicAuthorizationStatus != .authorized {
                    musicAuthorizationOverlay
                }
                
                // Show username prompt if needed
                if showUsernamePrompt {
                    UsernamePromptView(isPresented: $showUsernamePrompt)
                        .environmentObject(authManager)
                        .environmentObject(userProfileManager)
                        .transition(.opacity)
                        .zIndex(2)
                }
            }
            .onChange(of: authManager.isAuthenticated) { isAuthenticated in
                if isAuthenticated {
                    checkIfUsernameNeeded()
                }
            }
        }
    }
    
    // Check if we need to show username prompt
    private func checkIfUsernameNeeded() {
        // First check if we have a cached username
        if let userId = authManager.userId,
           let cachedUsername = UserDefaults.standard.string(forKey: "cachedUsername_\(userId)"),
           !cachedUsername.isEmpty {
            print("Found cached username '\(cachedUsername)' - no need to show prompt")
            // Make sure the username is set in the auth manager
            if authManager.username == nil || authManager.username!.isEmpty {
                authManager.username = cachedUsername
            }
            // Update profile
            userProfileManager.username = cachedUsername
            return
        }
        
        // If no cached username, check auth manager
        if authManager.isAuthenticated {
            if authManager.username == nil || authManager.username!.isEmpty {
                print("User needs to set a username - showing prompt")
                // Double check with Firestore before showing prompt
                if let userId = authManager.userId {
                    authManager.fetchUserData(for: userId) {
                        DispatchQueue.main.async {
                            // Check again after fetch
                            if self.authManager.username == nil || self.authManager.username!.isEmpty {
                                self.showUsernamePrompt = true
                            } else {
                                // We have a username, update profile
                                self.userProfileManager.username = self.authManager.username!
                            }
                        }
                    }
                } else {
                    // If no userId, show prompt anyway
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                        self.showUsernamePrompt = true
                    }
                }
            } else {
                print("User already has username: \(authManager.username!)")
                // Update profile
                userProfileManager.username = authManager.username!
            }
        }
    }
    
    // Check Apple Music authorization status
    private func checkMusicAuthorization() {
        Task {
            // Check current authorization status
            musicAuthorizationStatus = await MusicAuthorization.currentStatus
            print("Initial Music Authorization Status: \(musicAuthorizationStatus)")
            
            if musicAuthorizationStatus != .authorized {
                // Request authorization if needed
                print("Requesting MusicKit authorization...")
                musicAuthorizationStatus = await MusicAuthorization.request()
                print("Updated Music Authorization Status: \(musicAuthorizationStatus)")
            }
        }
    }
    
    // Music authorization overlay
    private var musicAuthorizationOverlay: some View {
        ZStack {
            Color.black.opacity(0.6)
                .edgesIgnoringSafeArea(.all)
            
            VStack(spacing: 20) {
                Text("Apple Music Access Required")
                    .font(.title2)
                    .foregroundColor(.white)
                    .multilineTextAlignment(.center)
                
                Text("Record needs access to your Apple Music library to search for songs and display album artwork.")
                    .foregroundColor(.white.opacity(0.9))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
                
                Button {
                    checkMusicAuthorization()
                } label: {
                    Text("Grant Access")
                        .font(.headline)
                        .foregroundColor(.white)
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(
                            RoundedRectangle(cornerRadius: 15)
                                .fill(Color(red: 0.94, green: 0.3, blue: 0.9).opacity(0.8))
                        )
                        .padding(.horizontal)
                }
            }
            .padding(30)
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(Color.black.opacity(0.8))
            )
            .padding()
        }
    }
}
