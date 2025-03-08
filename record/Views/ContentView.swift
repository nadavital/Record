import SwiftUI

struct ContentView: View {
    @State private var selectedTab = 0
    @EnvironmentObject private var musicAPI: MusicAPIManager
    @EnvironmentObject private var rankingManager: MusicRankingManager
    @EnvironmentObject private var authManager: AuthManager
    @State private var statsLoadedInitially = false
    @State private var nowPlayingBarVisible = false
    @State private var isLoading = true
    @State private var showAlbumInfo = false
    
    var body: some View {
        ZStack(alignment: .bottom) {
            TabView(selection: $selectedTab) {
                // Keep the existing views with their own NavigationStacks
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
                NowPlayingBarContainer(isLoading: isLoading, showAlbumInfo: $showAlbumInfo)
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
        .onChange(of: musicAPI.currentPlayingSong) {
            // Only update visibility if we're not loading
            if !isLoading {
                withAnimation(.spring()) {
                    nowPlayingBarVisible = musicAPI.currentPlayingSong != nil
                }
            }
        }
        .sheet(isPresented: $showAlbumInfo) {
            if let song = musicAPI.currentPlayingSong {
                NavigationStack {
                    AlbumInfoView(
                        album: Album(
                            id: UUID(),
                            title: song.albumArt,
                            artist: song.artist,
                            albumArt: song.albumArt,
                            artworkURL: song.artworkURL
                        ),
                        musicAPI: musicAPI
                    )
                    .environmentObject(musicAPI)
                    .environmentObject(rankingManager)
                    .toolbar {
                        ToolbarItem(placement: .cancellationAction) {
                            Button("Done") {
                                showAlbumInfo = false
                            }
                        }
                    }
                }
                .presentationDetents([.large])
                .presentationDragIndicator(.visible)
            }
        }
    }
}

// A container for the NowPlayingBar that handles the album navigation
struct NowPlayingBarContainer: View {
    var isLoading: Bool
    @Binding var showAlbumInfo: Bool
    @State private var showSongInfo = false
    @State private var currentlyDisplayedSong: Song? = nil
    @EnvironmentObject private var musicAPI: MusicAPIManager
    @EnvironmentObject private var rankingManager: MusicRankingManager
    
    var body: some View {
        NowPlayingBar(isLoading: isLoading)
            .onTapGesture {
                if !isLoading && musicAPI.currentPlayingSong != nil {
                    showSongInfo = true
                }
            }
            .sheet(isPresented: $showSongInfo) {
                if let currentSong = musicAPI.currentPlayingSong {
                    NavigationStack {
                        SongInfoView(
                            rankedSong: currentSong,
                            musicAPI: musicAPI,
                            rankingManager: rankingManager,
                            presentationStyle: .sheetFromNowPlaying,
                            onReRankButtonTapped: {
                                showSongInfo = false
                                currentlyDisplayedSong = currentSong
                                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                                    rankingManager.addNewSong(song: currentSong)
                                }
                            },
                            onShowAlbum: {
                                // First dismiss the song info sheet
                                showSongInfo = false
                                // Then show the album with a slight delay
                                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                                    showAlbumInfo = true
                                }
                            }
                        )
                        .navigationBarTitleDisplayMode(.inline)
                        .toolbar {
                            ToolbarItem(placement: .cancellationAction) {
                                Button("Done") {
                                    showSongInfo = false
                                }
                            }
                        }
                    }
                    .presentationDetents([.large])
                    .presentationDragIndicator(.visible)
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
