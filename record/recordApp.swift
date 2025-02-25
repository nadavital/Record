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
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(userProfileManager)
                .environmentObject(musicRankingManager)
        }
    }
}
