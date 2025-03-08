import SwiftUI
import MediaPlayer

struct NoFeedbackButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
    }
}

struct NowPlayingBar: View {
    @EnvironmentObject private var musicAPI: MusicAPIManager
    @EnvironmentObject private var rankingManager: MusicRankingManager
    @State private var isPlaying: Bool = false
    @State private var showSongInfo = false
    @State private var showAlbumInfo = false // State for album navigation
    @State private var currentlyDisplayedSong: Song? = nil
    @State private var albumToNavigateTo: Album? = nil // Store album for navigation
    
    var isLoading: Bool
    
    @Environment(\.colorScheme) var colorScheme
    
    private let musicPlayer = MPMusicPlayerController.systemMusicPlayer
    
    init(isLoading: Bool = false) {
        self.isLoading = isLoading
    }
    
    var body: some View {
        Button {
            if (!isLoading && musicAPI.currentPlayingSong != nil) {
                showSongInfo = true
            }
        } label: {
            HStack(spacing: 12) {
                if isLoading {
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color.gray.opacity(0.3))
                        .frame(width: 40, height: 40)
                } else if let currentSong = musicAPI.currentPlayingSong {
                    RemoteArtworkView(
                        artworkURL: currentSong.artworkURL,
                        placeholderText: currentSong.albumArt,
                        cornerRadius: 8,
                        size: CGSize(width: 40, height: 40)
                    )
                    .frame(width: 40, height: 40)
                } else {
                    Color.clear.frame(width: 0, height: 0)
                }
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(isLoading ? "Loading..." : (musicAPI.currentPlayingSong?.title ?? ""))
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .lineLimit(1)
                        .redacted(reason: isLoading ? .placeholder : [])
                    
                    Text(isLoading ? "Please wait" : (musicAPI.currentPlayingSong?.artist ?? ""))
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                        .redacted(reason: isLoading ? .placeholder : [])
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                
                HStack(spacing: 16) {
                    Button(action: previousTrack) {
                        Image(systemName: "backward.fill")
                            .font(.system(size: 20))
                            .opacity(isLoading ? 0.5 : 1)
                    }
                    .buttonStyle(BorderlessButtonStyle())
                    .disabled(isLoading)
                    
                    Button(action: togglePlayPause) {
                        Image(systemName: isPlaying ? "pause.fill" : "play.fill")
                            .font(.system(size: 22))
                            .opacity(isLoading ? 0.5 : 1)
                            .animation(nil, value: isPlaying)
                    }
                    .buttonStyle(BorderlessButtonStyle())
                    .disabled(isLoading)
                    
                    Button(action: nextTrack) {
                        Image(systemName: "forward.fill")
                            .font(.system(size: 20))
                            .opacity(isLoading ? 0.5 : 1)
                    }
                    .buttonStyle(BorderlessButtonStyle())
                    .disabled(isLoading)
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 10)
        }
        .buttonStyle(NoFeedbackButtonStyle())
        .background {
            RoundedRectangle(cornerRadius: 12)
                .fill(.ultraThinMaterial)
                .shadow(radius: 12, y: 4)
        }
        .padding(.horizontal)
        .padding(.bottom, 4)
        .sheet(isPresented: $showSongInfo) {
            if let currentSong = musicAPI.currentPlayingSong {
                NavigationStack {
                    SongInfoView(
                        rankedSong: currentSong,
                        musicAPI: musicAPI,
                        rankingManager: rankingManager,
                        presentationStyle: .sheetFromNowPlaying, // Specify it's from NowPlayingBar
                        onReRankButtonTapped: {
                            showSongInfo = false
                            currentlyDisplayedSong = currentSong
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                                rankingManager.addNewSong(song: currentSong)
                            }
                        },
                        onShowAlbum: {
                            // Create the album first before setting showAlbumInfo
                            // Delay navigation until sheet is fully dismissed
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
        .navigationDestination(isPresented: $showAlbumInfo) {
            if let song = musicAPI.currentPlayingSong {
                // Fetch MusicKit album based on current song
                AlbumInfoView(
                    album: Album(
                        id: UUID(), // Temporary ID; ideally fetch real ID
                        title: song.albumArt,
                        artist: song.artist,
                        albumArt: song.albumArt,
                        artworkURL: song.artworkURL
                    ),
                    musicAPI: musicAPI
                )
                .environmentObject(musicAPI)
                .environmentObject(rankingManager)
            }
        }
        .onChange(of: rankingManager.isRanking) {
            if !rankingManager.isRanking, currentlyDisplayedSong != nil {
                currentlyDisplayedSong = nil
            }
        }
        .onAppear {
            if !isLoading {
                updatePlaybackState()
                setupPlaybackObserver()
            }
        }
        .onChange(of: musicAPI.currentPlayingSong) {
            updatePlaybackState()
        }
        .onReceive(NotificationCenter.default.publisher(for: .MPMusicPlayerControllerPlaybackStateDidChange)) { _ in
            updatePlaybackState()
        }
        .opacity(musicAPI.currentPlayingSong != nil || isLoading ? 1 : 0)
    }
    
    private func togglePlayPause() {
        if musicPlayer.playbackState == .playing {
            musicPlayer.pause()
            isPlaying = false
        } else {
            musicPlayer.play()
            isPlaying = true
        }
    }
    
    private func nextTrack() {
        musicPlayer.skipToNextItem()
        updatePlaybackState()
    }
    
    private func previousTrack() {
        musicPlayer.skipToPreviousItem()
        updatePlaybackState()
    }
    
    private func updatePlaybackState() {
        isPlaying = musicPlayer.playbackState == .playing
    }
    
    private func setupPlaybackObserver() {
        NotificationCenter.default.addObserver(
            forName: .MPMusicPlayerControllerPlaybackStateDidChange,
            object: musicPlayer,
            queue: .main
        ) { _ in
            self.updatePlaybackState()
        }
        
        musicPlayer.beginGeneratingPlaybackNotifications()
    }
}
