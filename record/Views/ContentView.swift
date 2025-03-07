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
    @State private var nowPlayingBarVisible = false
    @State private var isLoading = true
    
    var body: some View {
        ZStack(alignment: .bottom) {
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
            
            // Position the now playing bar above the tab bar with padding
            VStack {
                NowPlayingBar(isLoading: isLoading)
                    .opacity(nowPlayingBarVisible || isLoading ? 1 : 0)
                    .animation(.easeInOut(duration: 0.3), value: nowPlayingBarVisible)
                    .animation(.easeInOut(duration: 0.3), value: isLoading)
                
                // Add space for the tab bar
                Color.clear.frame(height: 49)
            }
            .background(Color.clear)
            .zIndex(1) // Lower zIndex so overlays appear above it
            
            // Ranking overlays (higher zIndex)
            if rankingManager.showSentimentPicker {
                Color(.systemBackground)
                    .opacity(0.95)
                    .ignoresSafeArea()
                    .zIndex(10)
                SentimentPickerView()
                    .transition(.opacity)
                    .zIndex(11)
            }
            if rankingManager.showComparison {
                Color(.systemBackground)
                    .opacity(0.95)
                    .ignoresSafeArea()
                    .zIndex(10)
                SongComparisonView()
                    .transition(.opacity)
                    .zIndex(11)
            }
        }
        .task {
            if !statsLoadedInitially {
                await musicAPI.checkMusicAuthorizationStatus()
                await musicAPI.fetchListeningHistory()
                
                // Set up now playing monitoring
                musicAPI.setupNowPlayingMonitoring()
                
                // For development: set a demo song if nothing is playing
                #if DEBUG
                musicAPI.setDemoCurrentSong()
                #endif
                
                // After a short delay, show the now playing bar and hide loading state
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                    withAnimation {
                        isLoading = false
                        nowPlayingBarVisible = musicAPI.currentPlayingSong != nil
                    }
                }
                
                statsLoadedInitially = true
            }
        }
        .onChange(of: rankingManager.isRanking) {
            // If ranking ends while on Stats tab, switch back to Stats if needed
            if !rankingManager.isRanking && selectedTab == 1 {
                // No explicit dismissal needed here; rely on NavigationStack
            }
        }
        .onChange(of: musicAPI.currentPlayingSong) { _ in
            // Only update visibility if we're not loading
            if !isLoading {
                withAnimation(.spring()) {
                    nowPlayingBarVisible = musicAPI.currentPlayingSong != nil
                }
            }
        }
    }
}

#Preview {
    ContentView()
        .environmentObject(UserProfileManager())
        .environmentObject(MusicRankingManager())
        .environmentObject(MusicAPIManager())
        .environmentObject(AuthManager.shared)
}
