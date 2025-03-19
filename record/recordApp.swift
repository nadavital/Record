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
    @StateObject private var albumRatingManager = AlbumRatingManager()
    @StateObject private var authManager = AuthManager.shared
    @StateObject private var mediaPlayerManager = MediaPlayerManager()
    @State private var musicAuthorizationStatus = MusicAuthorization.Status.notDetermined
    @State private var showUsernamePrompt = false
    
    // Add persistence manager to access sync functionality
    @ObservedObject private var persistenceManager = PersistenceManager.shared
    
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
                        .environmentObject(albumRatingManager)
                        .environmentObject(mediaPlayerManager)
                        .onAppear {
                            checkMusicAuthorization()
                            checkIfUsernameNeeded()
                            // Trigger automatic sync when app launches
                            if let userId = authManager.userId {
                                persistenceManager.syncWithCloudKit()
                            }
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
           (authManager.username?.isEmpty ?? true) {
            showUsernamePrompt = true
        } else if let username = authManager.username, !username.isEmpty {
            print("User already has username: \(authManager.username!)")
            userProfileManager.username = authManager.username!
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
