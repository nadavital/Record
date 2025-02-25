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
    // Initialize shared managers
    @StateObject private var userProfileManager = UserProfileManager()
    @StateObject private var musicRankingManager = MusicRankingManager()
    @State private var musicAuthorizationStatus = MusicAuthorization.Status.notDetermined
    
    var body: some Scene {
        WindowGroup {
            ZStack {
                ContentView()
                    .environmentObject(userProfileManager)
                    .environmentObject(musicRankingManager)
                    .onAppear {
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
                            
                            // Configure MusicKit session after authorization
                            if musicAuthorizationStatus == .authorized {
                                do {
                                    // Test API access with a simple catalog query
                                    print("Testing MusicKit API connection...")
                                    var testRequest = MusicCatalogSearchRequest(term: "test", types: [MusicKit.Song.self])
                                    testRequest.limit = 1
                                    let testResponse = try await testRequest.response()
                                    print("MusicKit API connection successful - found \(testResponse.songs.count) songs")
                                } catch {
                                    print("MusicKit configuration error: \(error.localizedDescription)")
                                }
                            }
                        }
                    }
                
                // Show a modal if authorization is needed
                if musicAuthorizationStatus != .authorized {
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
            }
        }
    }
}
