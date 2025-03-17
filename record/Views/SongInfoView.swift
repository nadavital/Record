import SwiftUI
import MusicKit

struct SongInfoView: View {
    @StateObject private var viewModel: SongInfoViewModel
    @EnvironmentObject private var musicAPI: MusicAPIManager
    @EnvironmentObject private var rankingManager: MusicRankingManager
    @EnvironmentObject private var playerManager: MusicPlayerManager
    @Environment(\.dismiss) var dismiss
    
    private let presentationStyle: PresentationStyle
    enum PresentationStyle {
        case fullscreen
        case sheetFromAlbum
        case sheetFromNowPlaying
    }
    
    private let musicKitSong: MusicKit.Song?
    private let rankedSong: Song?
    @State private var reRankedSong: Song?
    private let onReRankButtonTapped: (() -> Void)?
    private let onShowAlbum: (() -> Void)?
    
    @State private var navigateToAlbum = false
    @State private var albumToShow: Album? = nil
    
    init(
        musicKitSong: MusicKit.Song? = nil,
        rankedSong: Song? = nil,
        musicAPI: MusicAPIManager,
        rankingManager: MusicRankingManager,
        presentationStyle: PresentationStyle = .fullscreen,
        onReRankButtonTapped: (() -> Void)? = nil,
        onShowAlbum: (() -> Void)? = nil
    ) {
        self.musicKitSong = musicKitSong
        self.rankedSong = rankedSong
        self.presentationStyle = presentationStyle
        self.onReRankButtonTapped = onReRankButtonTapped
        self.onShowAlbum = onShowAlbum
        
        _viewModel = StateObject(wrappedValue: SongInfoViewModel(
            musicAPI: musicAPI,
            rankingManager: rankingManager
        ))
    }
    
    var body: some View {
        NavigationStack {
            Group {
                if viewModel.isLoading {
                    ProgressView()
                } else if let song = viewModel.unifiedSong {
                    SongInfoContentView(
                        song: song,
                        onReRank: {
                            if let onReRankButtonTapped = onReRankButtonTapped {
                                onReRankButtonTapped()
                            } else {
                                reRankSong(currentSong: song)
                            }
                        },
                        onPlayPause: togglePlayPause,
                        onShowAlbum: presentationStyle == .sheetFromAlbum ? nil : handleShowAlbum
                    )
                } else if let error = viewModel.errorMessage {
                    Text(error).foregroundColor(.red)
                } else {
                    Text("No song data available").foregroundColor(.gray)
                }
            }
            .navigationTitle("Song Info")
            .navigationBarTitleDisplayMode(.inline)
            .navigationDestination(isPresented: $navigateToAlbum) {
                if let album = albumToShow {
                    AlbumInfoView(album: album, musicAPI: musicAPI)
                        .environmentObject(musicAPI)
                        .environmentObject(rankingManager)
                        .environmentObject(playerManager)
                }
            }
            .task {
                if let song = musicKitSong {
                    await viewModel.loadSongInfo(from: song)
                } else if let song = rankedSong {
                    await viewModel.loadSongInfo(from: song)
                }
            }
            .onChange(of: rankingManager.isRanking) {
                if !rankingManager.isRanking, let reRankedSong = reRankedSong {
                    Task {
                        await viewModel.refreshSongInfo(from: reRankedSong)
                    }
                }
            }
        }
    }
    
    private func reRankSong(currentSong: UnifiedSong) {
        let rankedSong: Song
        if let existingSong = rankingManager.rankedSongs.first(where: {
            $0.title.lowercased() == currentSong.title.lowercased() &&
            $0.artist.lowercased() == currentSong.artist.lowercased()
        }) {
            rankedSong = Song(
                id: existingSong.id,
                title: currentSong.title,
                artist: currentSong.artist,
                albumArt: currentSong.album,
                sentiment: currentSong.sentiment ?? .fine,
                artworkURL: currentSong.artworkURL ?? existingSong.artworkURL,
                score: currentSong.score ?? 0.0
            )
        } else {
            rankedSong = Song(
                title: currentSong.title,
                artist: currentSong.artist,
                albumArt: currentSong.album,
                sentiment: currentSong.sentiment ?? .fine,
                artworkURL: currentSong.artworkURL
            )
        }
        reRankedSong = rankedSong
        rankingManager.addNewSong(song: rankedSong)
    }
    
    private func togglePlayPause() {
        // Check if this song is already the current playing song
        if isCurrentSong() {
            // If it's the same song, just toggle play/pause using the manager
            // This will resume from the current position rather than starting over
            playerManager.togglePlayPause()
            return
        }
        
        // For a different song, stop any current playback first
        if playerManager.isPlaying {
            playerManager.togglePlayPause() // Pause the current song
        }
        
        // Small delay to ensure the previous song is properly paused
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            // Start the new song
            if let musicKitSong = self.musicKitSong {
                self.playerManager.playSong(mediaItem: musicKitSong)
            } else if let rankedSong = self.rankedSong {
                self.playerManager.playSong(title: rankedSong.title, artist: rankedSong.artist) { success in
                    if !success {
                        print("Failed to play \(rankedSong.title) by \(rankedSong.artist)")
                    }
                }
            }
        }
    }
    
    private func isCurrentSong() -> Bool {
        guard let currentSong = playerManager.currentSong,
              let unifiedSong = viewModel.unifiedSong else { return false }
        
        // Use normalized comparing to handle case differences and spacing
        let currentTitle = currentSong.title.lowercased().trimmingCharacters(in: .whitespacesAndNewlines)
        let currentArtist = currentSong.artist.lowercased().trimmingCharacters(in: .whitespacesAndNewlines)
        let songTitle = unifiedSong.title.lowercased().trimmingCharacters(in: .whitespacesAndNewlines)
        let songArtist = unifiedSong.artist.lowercased().trimmingCharacters(in: .whitespacesAndNewlines)
        
        // Check if titles and artists match
        return currentTitle == songTitle && currentArtist == songArtist
    }
    
    private func handleShowAlbum() {
        if let onShowAlbum = onShowAlbum {
            // If provided with an external handler, use it (like from NowPlayingBar)
            onShowAlbum()
        } else if let song = viewModel.unifiedSong {
            // Otherwise, create an Album object and navigate to it
            albumToShow = Album(
                id: UUID(),
                title: song.album,
                artist: song.artist,
                albumArt: song.album,
                artworkURL: song.artworkURL
            )
            navigateToAlbum = true
        }
    }
}

struct SongInfoContentView: View {
    let song: UnifiedSong
    let onReRank: () -> Void
    let onPlayPause: () -> Void
    let onShowAlbum: (() -> Void)? // Add this parameter
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                ArtworkCard(
                    song: song,
                    onReRank: onReRank,
                    onPlayPause: onPlayPause,
                    onShowAlbum: onShowAlbum // Pass it down
                )
                StatsCard(song: song)
                
                // Only show MetadataCard if there's at least one metadata item
                if hasMetadata(song) {
                    MetadataCard(song: song)
                }
                
                Color.clear
                    .frame(height: 80)
                    .listRowInsets(EdgeInsets())
            }
            .padding(.horizontal)
            .padding(.bottom)
            .scrollIndicators(.hidden)
        }
        .background(Color(uiColor: .systemBackground)
            .opacity(0.8)
            .ignoresSafeArea())
    }
    
    private func hasMetadata(_ song: UnifiedSong) -> Bool {
        return song.releaseDate != nil || song.genre != nil || song.lastPlayedDate != nil
    }
}

struct ArtworkCard: View {
    let song: UnifiedSong
    let onReRank: () -> Void
    let onPlayPause: () -> Void
    let onShowAlbum: (() -> Void)? // Add this parameter
    
    @EnvironmentObject private var playerManager: MusicPlayerManager
    
    var body: some View {
        VStack(spacing: 16) {
            if let url = song.artworkURL {
                AsyncImage(url: url) { image in
                    image
                        .resizable()
                        .scaledToFit()
                } placeholder: {
                    Color.gray
                }
                .frame(width: 250, height: 250)
                .cornerRadius(12)
                .shadow(radius: 5)
                // Add tap gesture for showing album if onShowAlbum exists
                .onTapGesture {
                    if let onShowAlbum = onShowAlbum {
                        onShowAlbum()
                    }
                }
            } else {
                Color.gray
                    .frame(width: 250, height: 250)
                    .cornerRadius(12)
                    .shadow(radius: 5)
            }
            
            VStack(spacing: 8) {
                Text(song.title)
                    .font(.title2)
                    .bold()
                Text(song.artist)
                    .font(.title3)
                    .foregroundColor(.secondary)
                
                // Make album text tappable if onShowAlbum exists
                Button(action: {
                    if let onShowAlbum = onShowAlbum {
                        onShowAlbum()
                    }
                }) {
                    Text(song.album)
                        .font(.subheadline)
                        .foregroundColor(onShowAlbum != nil ? .accentColor : .secondary)
                }
                .buttonStyle(PlainButtonStyle())
                .disabled(onShowAlbum == nil)
            }
            
            HStack(spacing: 20) {
                Button(action: onPlayPause) {
                    Image(systemName: playerManager.isPlaying && isCurrentSong() ? "pause.circle.fill" : "play.circle.fill")
                        .font(.system(size: 40))
                        .foregroundColor(.accentColor)
                }
                .buttonStyle(PlainButtonStyle())
                
                Button(action: onReRank) {
                    Text(song.isRanked ? "Re-rank" : "Rank")
                        .fontWeight(.semibold)
                        .padding(.horizontal, 20)
                        .padding(.vertical, 10)
                        .background(Color.accentColor)
                        .foregroundColor(.white)
                        .cornerRadius(8)
                }
            }
            .padding(.top, 4)
            .padding(.bottom, 8)
        }
        .padding(20)
        .frame(maxWidth: .infinity)
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }
    
    private func isCurrentSong() -> Bool {
        guard let currentSong = playerManager.currentSong else { return false }
        return currentSong.title.lowercased() == song.title.lowercased() &&
               currentSong.artist.lowercased() == song.artist.lowercased()
    }
}


struct StatsCard: View {
    let song: UnifiedSong
    
    var body: some View {
        VStack(spacing: 16) {
            HStack(spacing: 30) {
                if song.isRanked {
                    StatItem(label: "Rank", value: "#\(song.rank ?? 0)")
                    StatItem(label: "Score", value: String(format: "%.1f", song.score ?? 0))
                    if let sentiment = song.sentiment {
                        StatItem(label: "Sentiment") {
                            Image(systemName: sentiment.icon)
                                .font(.title3)
                                .foregroundColor(sentiment.color)
                        }
                    }
                } else {
                    StatItem(label: "Rank", value: "--")
                    StatItem(label: "Score", value: "--")
                    StatItem(label: "Sentiment") {
                        Image(systemName: "questionmark.circle")
                            .font(.title3)
                            .foregroundColor(.secondary)
                    }
                }
            }
            .padding(.horizontal)
            
            Divider().padding(.horizontal)
            
            StatItem(label: "Plays", value: "\(song.playCount)")
                .padding(.top, 5)
        }
        .padding(20)
        .frame(maxWidth: .infinity)
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }
}

struct MetadataCard: View {
    let song: UnifiedSong
    
    var body: some View {
        VStack(spacing: 14) {
            if let releaseDate = song.releaseDate {
                MetadataItem(label: "Release Date", value: releaseDate, formatter: .date)
            }
            if let genre = song.genre {
                MetadataItem(label: "Genre", value: genre)
            }
            if let lastPlayedDate = song.lastPlayedDate {
                MetadataItem(label: "Last Played", value: lastPlayedDate, formatter: .dateTime)
            }
        }
        .padding(20)
        .frame(maxWidth: .infinity)
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }
}

struct StatItem<Content: View>: View {
    let label: String
    let content: Content
    
    init(label: String, value: String) where Content == Text {
        self.label = label
        self.content = Text(value)
            .font(.title3)
            .bold()
    }
    
    init(label: String, @ViewBuilder content: () -> Content) {
        self.label = label
        self.content = content()
    }
    
    var body: some View {
        VStack(spacing: 5) {
            content
            Text(label)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
    }
}

struct MetadataItem: View {
    let label: String
    let value: Any
    let formatter: Formatter?
    
    init(label: String, value: Any, formatter: Formatter? = nil) {
        self.label = label
        self.value = value
        self.formatter = formatter
    }
    
    var body: some View {
        HStack {
            Text(label)
                .foregroundColor(.secondary)
            Spacer()
            if let formatter = formatter, let date = value as? Date {
                Text(formatter.string(for: date) ?? "")
                    .foregroundColor(.primary)
            } else {
                Text("\(value)")
                    .foregroundColor(.primary)
            }
        }
    }
}

extension Formatter {
    static let date: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter
    }()
    
    static let dateTime: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter
    }()
}
