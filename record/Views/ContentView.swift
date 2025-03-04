//
//  ContentView.swift
//  record
//
//  Created by Nadav Avital on 2/14/25.
//

import SwiftUI

struct ContentView: View {
    @State private var selectedTab = 0
    @EnvironmentObject private var musicAPI: MusicAPIManager
    @EnvironmentObject private var rankingManager: MusicRankingManager
    @EnvironmentObject private var authManager: AuthManager  // Add this line
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
            
            // Ranking overlays
            if rankingManager.showSentimentPicker {
                Color(.systemBackground)
                    .opacity(0.95)
                    .ignoresSafeArea()
                    .zIndex(1)
                SentimentPickerView()
                    .transition(.opacity)
                    .zIndex(2)
            }
            if rankingManager.showComparison {
                Color(.systemBackground)
                    .opacity(0.95)
                    .ignoresSafeArea()
                    .zIndex(1)
                SongComparisonView()
                    .transition(.opacity)
                    .zIndex(3)
            }
        }
        .task {
            if !statsLoadedInitially {
                await musicAPI.checkMusicAuthorizationStatus()
                await musicAPI.fetchListeningHistory()
                statsLoadedInitially = true
            }
        }
        .onChange(of: rankingManager.isRanking) { isRanking in
            // If ranking ends while on Stats tab, switch back to Stats if needed
            if !isRanking && selectedTab == 1 {
                // No explicit dismissal needed here; rely on NavigationStack
            }
        }
    }
}

#Preview {
    ContentView()
        .environmentObject(UserProfileManager())
        .environmentObject(MusicRankingManager())
        .environmentObject(MusicAPIManager())
        .environmentObject(AuthManager.shared)  // Add this line
}
