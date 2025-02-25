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
    
    init() {
        // Request minimal MusicKit authorization on app launch
        Task {
            // This will just check if we have permission without prompting if not granted
            let status = await MusicAuthorization.currentStatus
            print("Music Authorization Status: \(status)")
            
            // Only request authorization if needed
            if status == .notDetermined {
                // This will show a permission dialog, but it's the minimum required
                // to use even the basic catalog search functionality
                let newStatus = await MusicAuthorization.request()
                print("New Music Authorization Status: \(newStatus)")
            }
        }
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(userProfileManager)
                .environmentObject(musicRankingManager)
        }
    }
}
