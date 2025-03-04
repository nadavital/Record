//
//  ContentView.swift
//  record
//
//  Created by Nadav Avital on 2/14/25.
//

import SwiftUI

struct ContentView: View {
    @State private var selectedTab = 0
    @StateObject private var statsLoader = MusicAPIManager()
    @State private var statsLoadedInitially = false
    
    var body: some View {
        ZStack {
            LinearGradient(
                gradient: Gradient(colors: [
                    Color.black.opacity(0.8),
                    Color(red: 0.1, green: 0.05, blue: 0.2)
                ]),
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()
            
            TabView(selection: $selectedTab) {
                RankingView()
                    .tabItem {
                        Image(systemName: "music.note.list")
                        Text("Rank")
                    }
                    .tag(0)
                
                StatisticsView()
                    .environmentObject(statsLoader)
                    .tabItem {
                        Image(systemName: "chart.bar")
                        Text("Stats")
                    }
                    .tag(1)
                
                ProfileView()
                    .tabItem {
                        Image(systemName: "person.fill")
                        Text("Profile")
                    }
                    .tag(2)
            }
            .accentColor(Color(red: 0.94, green: 0.3, blue: 0.9))
        }
        .task {
            if !statsLoadedInitially {
                // Check authorization and load statistics in background
                await statsLoader.checkMusicAuthorizationStatus()
                await statsLoader.fetchListeningHistory()
                statsLoadedInitially = true
            }
        }
    }
}

#Preview {
    ContentView()
        .environmentObject(UserProfileManager())
        .environmentObject(MusicRankingManager())
}
