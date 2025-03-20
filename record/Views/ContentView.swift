import SwiftUI

struct ContentView: View {
    @State private var selectedTab = 0
    @EnvironmentObject private var musicAPI: MusicAPIManager
    @EnvironmentObject private var rankingManager: MusicRankingManager
    @EnvironmentObject private var authManager: AuthManager
    @EnvironmentObject private var playerManager: MusicPlayerManager
    @EnvironmentObject private var albumRatingManager: AlbumRatingManager // Add this
    @State private var statsLoadedInitially = false
    @State private var nowPlayingBarVisible = false
    @State private var isLoading = true
    @State private var showAlbumInfo = false
    
    var body: some View {
        ZStack(alignment: .bottom) {
            TabView(selection: $selectedTab) {
                RankingView()
                    .tabItem {
                        Image(systemName: "music.note.list")
                        Text("Rank")
                    }
                    .tag(0)
                
                ReviewView()
                    .tabItem {
                        Image(systemName: "square.stack")
                        Text("Review")
                    }
                    .tag(1)
                
                ProfileView()
                    .tabItem {
                        Image(systemName: "person.fill")
                        Text("Profile")
                    }
                    .tag(2)
            }
            
            VStack {
                NowPlayingBarContainer(isLoading: isLoading, showAlbumInfo: $showAlbumInfo)
                    .opacity(nowPlayingBarVisible || isLoading ? 1 : 0)
                    .animation(.easeInOut(duration: 0.3), value: nowPlayingBarVisible)
                    .animation(.easeInOut(duration: 0.3), value: isLoading)
                
                Color.clear.frame(height: 49)
            }
            .background(Color.clear)
            .zIndex(1)
            
            // Song Rating Process Overlays
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
            
            // Album Rating Overlay
            if albumRatingManager.showRatingView {
                RateAlbumOverlayView()
                    .transition(.opacity)
                    .zIndex(12)
            }
        }
        .onChange(of: rankingManager.isRanking) {
            if !rankingManager.isRanking && selectedTab == 1 {
                // No action needed
            }
        }
        .onChange(of: playerManager.currentSong) { // Changed to playerManager
            if !isLoading {
                withAnimation(.spring()) {
                    nowPlayingBarVisible = playerManager.currentSong != nil
                }
            }
        }
        .sheet(isPresented: $showAlbumInfo) {
            if let song = playerManager.currentSong { // Changed to playerManager
                NavigationStack {
                    AlbumInfoView(
                        album: Album(
                            id: UUID(),
                            title: song.albumArt,
                            artist: song.artist,
                            albumArt: song.albumArt,
                            artworkURL: song.artworkURL
                        ),
                        musicAPI: musicAPI,
                        isPresentedAsSheet: true
                    )
                    .environmentObject(musicAPI)
                    .environmentObject(rankingManager)
                    .environmentObject(playerManager) // Add playerManager
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
        .onAppear {
            // Set isLoading to false after a brief delay to allow data to load
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                isLoading = false
                
                // Check for currently playing songs
                if playerManager.currentSong != nil {
                    nowPlayingBarVisible = true
                }
            }
        }
    }
}

struct NowPlayingBarContainer: View {
    var isLoading: Bool
    @Binding var showAlbumInfo: Bool
    @State private var showSongInfo = false
    @State private var currentlyDisplayedSong: Song? = nil
    @EnvironmentObject private var musicAPI: MusicAPIManager
    @EnvironmentObject private var rankingManager: MusicRankingManager
    @EnvironmentObject private var playerManager: MusicPlayerManager
    
    var body: some View {
        NowPlayingBar(isLoading: isLoading)
            .onTapGesture {
                if !isLoading && playerManager.currentSong != nil {
                    showSongInfo = true
                }
            }
            .sheet(isPresented: $showSongInfo) {
                if let currentSong = playerManager.currentSong {
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
                                showSongInfo = false
                                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                                    showAlbumInfo = true
                                }
                            }
                        )
                        .environmentObject(playerManager)
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
        .environmentObject(MusicPlayerManager())
}
