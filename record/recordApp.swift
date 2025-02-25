//
//  recordApp.swift
//  record
//
//  Created by Nadav Avital on 2/14/25.
//

import SwiftUI

@main
struct recordApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(UserProfileManager())
                .environmentObject(MusicRankingManager())
        }
    }
}
