//
//  recordApp.swift
//  record
//
//  Created by Nadav Avital on 2/14/25.
//

import SwiftUI
import MusicKit

@main
struct recordApp: App {
    @StateObject private var userProfileManager = UserProfileManager()
    @StateObject private var musicRankingManager = MusicRankingManager()
    @StateObject private var musicAPIManager = MusicAPIManager()
    @StateObject private var playerManager = MusicPlayerManager()
    @StateObject private var authManager = AuthManager.shared
    @State private var musicAuthorizationStatus = MusicAuthorization.Status.notDetermined
    @State private var showUsernamePrompt = false
    
    var body: some Scene {
        WindowGroup {
            ZStack {
                if authManager.isAuthenticated {
                    ContentView()
                        .environmentObject(userProfileManager)
                        .environmentObject(musicRankingManager)
                        .environmentObject(musicAPIManager)
                        .environmentObject(authManager)
                        .environmentObject(playerManager)
                        .onAppear {
                            checkMusicAuthorization()
                            checkIfUsernameNeeded()
                        }
                } else {
                    SignInView(authManager: authManager, profileManager: userProfileManager)
                        .environmentObject(userProfileManager)
                        .environmentObject(authManager)
                }
                
                if authManager.isAuthenticated && musicAuthorizationStatus != .authorized {
                    musicAuthorizationOverlay
                }
                
                if showUsernamePrompt {
                    UsernamePromptView(isPresented: $showUsernamePrompt)
                        .environmentObject(authManager)
                        .environmentObject(userProfileManager)
                        .transition(.opacity)
                        .zIndex(2)
                }
            }
            .onChange(of: authManager.isAuthenticated) {
                if authManager.isAuthenticated {
                    checkIfUsernameNeeded()
                }
            }
        }
    }
    
    // Check if we need to show username prompt
    private func checkIfUsernameNeeded() {
        if let userId = authManager.userId,
           let cachedUsername = UserDefaults.standard.string(forKey: "cachedUsername_\(userId)"),
           !cachedUsername.isEmpty {
            print("Found cached username '\(cachedUsername)' - no need to show prompt")
            if authManager.username == nil || authManager.username!.isEmpty {
                authManager.username = cachedUsername
            }
            userProfileManager.username = cachedUsername
            return
        }
        
        if authManager.isAuthenticated {
            if authManager.username == nil || authManager.username!.isEmpty {
                print("User needs to set a username - showing prompt")
                if let userId = authManager.userId {
                    authManager.fetchUserData(for: userId) {
                        DispatchQueue.main.async {
                            if self.authManager.username == nil || self.authManager.username!.isEmpty {
                                self.showUsernamePrompt = true
                            } else {
                                self.userProfileManager.username = self.authManager.username!
                            }
                        }
                    }
                } else {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                        self.showUsernamePrompt = true
                    }
                }
            } else {
                print("User already has username: \(authManager.username!)")
                userProfileManager.username = authManager.username!
            }
        }
    }
    
    private func checkMusicAuthorization() {
        Task {
            musicAuthorizationStatus = MusicAuthorization.currentStatus
            print("Initial Music Authorization Status: \(musicAuthorizationStatus)")
            if musicAuthorizationStatus != .authorized {
                print("Requesting MusicKit authorization...")
                musicAuthorizationStatus = await MusicAuthorization.request()
                print("Updated Music Authorization Status: \(musicAuthorizationStatus)")
            }
        }
    }
    
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
