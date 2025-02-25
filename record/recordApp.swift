//
//  recordApp.swift
//  record
//
//  Created by Nadav Avital on 2/14/25.
//

import SwiftUI
import MusicKit
import FirebaseCore
import FirebaseAuth
import FirebaseFirestore

@main
struct recordApp: App {
    // Initialize shared managers
    @StateObject private var userProfileManager = UserProfileManager()
    @StateObject private var musicRankingManager = MusicRankingManager()
    @StateObject private var authManager = AuthenticationManager()
    @State private var musicAuthorizationStatus = MusicAuthorization.Status.notDetermined
    
    init() {
        // Configure Firebase
        FirebaseApp.configure()
    }
    
    var body: some Scene {
        WindowGroup {
            ZStack {
                if authManager.isAuthenticated {
                    // Main app content when authenticated
                    ContentView()
                        .environmentObject(userProfileManager)
                        .environmentObject(musicRankingManager)
                        .environmentObject(authManager)
                        .onAppear {
                            // Sync Firebase user profile with app profile
                            syncUserProfile()
                            
                            // Request music authorization
                            requestMusicAuthorization()
                        }
                
                // Show Apple Music authorization modal if needed
                if authManager.isAuthenticated && musicAuthorizationStatus != .authorized {
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
                                Task {
                                    print("Requesting MusicKit authorization (manual)...")
                                    musicAuthorizationStatus = await MusicAuthorization.request()
                                    print("Manual Authorization Status: \(musicAuthorizationStatus)")
                                }
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
                } else {
                    // Authentication flow
                    SignInView()
                        .environmentObject(authManager)
                }
            }
        }
    }
    
    private func syncUserProfile() {
        guard let firebaseProfile = authManager.userProfile else { return }
        
        // Update local profile manager with Firebase data
        userProfileManager.username = firebaseProfile.username
        
        // In a real app, you'd sync more profile data here
    }
    
    private func requestMusicAuthorization() {
        Task {
            print("Requesting MusicKit authorization...")
            musicAuthorizationStatus = await MusicAuthorization.request()
            print("Authorization Status: \(musicAuthorizationStatus)")
        }
    }
