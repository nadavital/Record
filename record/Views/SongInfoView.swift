import SwiftUI
import MediaPlayer
import MusicKit

struct SongInfoView: View {
    @StateObject private var viewModel: SongInfoViewModel
    @EnvironmentObject private var musicAPI: MusicAPIManager
    @EnvironmentObject private var rankingManager: MusicRankingManager
    @Environment(\.dismiss) var dismiss
    
    // Keep track of how the view was presented
    private let presentationStyle: PresentationStyle
    
    enum PresentationStyle {
        case fullscreen  // View is presented as a full screen (push navigation)
        case sheetFromAlbum  // View is presented as a sheet from album view
        case sheetFromNowPlaying  // View is presented as a sheet from now playing bar
    }
    
    private let mediaItem: MPMediaItem?
    private let rankedSong: Song?
    @State private var reRankedSong: Song?
    private let onReRankButtonTapped: (() -> Void)?
    private let onShowAlbum: (() -> Void)? // Callback to handle album navigation in parent
    
    // State for in-view navigation
    @State private var navigateToAlbum = false
    @State private var albumToShow: Album? = nil
    
    init(
        mediaItem: MPMediaItem? = nil,
        rankedSong: Song? = nil,
        musicAPI: MusicAPIManager,
        rankingManager: MusicRankingManager,
        presentationStyle: PresentationStyle = .fullscreen, // Default to fullscreen
        onReRankButtonTapped: (() -> Void)? = nil,
        onShowAlbum: (() -> Void)? = nil
    ) {
        self._viewModel = StateObject(wrappedValue: SongInfoViewModel(musicAPI: musicAPI, rankingManager: rankingManager))
        self.mediaItem = mediaItem
        self.rankedSong = rankedSong
        self.presentationStyle = presentationStyle
        self.onReRankButtonTapped = onReRankButtonTapped
        self.onShowAlbum = onShowAlbum
    }
    
    var body: some View {
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
                    onShowAlbum: {
                        handleAlbumNavigation(song: song)
                    }
                )
            } else if let error = viewModel.errorMessage {
                Text(error).foregroundColor(.red)
            } else {
                Text("No song data available").foregroundColor(.gray)
            }
        }
        .navigationTitle(viewModel.unifiedSong?.title ?? "Song Info")
        .navigationBarTitleDisplayMode(.inline)
        .navigationDestination(isPresented: $navigateToAlbum) {
            if let album = albumToShow {
                AlbumInfoView(
                    album: album,
                    musicAPI: musicAPI
                )
                .environmentObject(musicAPI)
                .environmentObject(rankingManager)
            }
        }
        .onAppear {
            Task {
                if let mediaItem = mediaItem {
                    await viewModel.loadSongInfo(from: mediaItem)
                } else if let rankedSong = rankedSong {
                    await viewModel.loadSongInfo(from: rankedSong)
                } else {
                    assertionFailure("No song data provided")
                }
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
    
    // Handle album navigation based on presentation style
    private func handleAlbumNavigation(song: UnifiedSong) {
        // Create the album regardless of navigation path
        let album = Album(
            id: UUID(),
            title: song.album,
            artist: song.artist,
            albumArt: song.album,
            artworkURL: song.artworkURL
        )
        
        switch presentationStyle {
        case .fullscreen:
            // Use NavigationStack destination for smooth in-stack navigation
            albumToShow = album
            navigateToAlbum = true
        case .sheetFromAlbum:
            // Just dismiss the sheet if we came from album view
            dismiss()
        case .sheetFromNowPlaying:
            // Store album info before dismissing
            albumToShow = album
            // Dismiss this sheet and tell parent to navigate
            dismiss()
            // Use the callback to tell NowPlayingBar to navigate
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                onShowAlbum?()
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
                id: UUID(),
                title: currentSong.title,
                artist: currentSong.artist,
                albumArt: currentSong.album,
                sentiment: currentSong.sentiment ?? .fine,
                artworkURL: currentSong.artworkURL,
                score: currentSong.score ?? 0.0
            )
        }
        reRankedSong = rankedSong
        rankingManager.addNewSong(song: rankedSong)
    }
}

// Rest of the view structs remain unchanged

struct SongInfoContentView: View {
    let song: UnifiedSong
    let onReRank: () -> Void
    let onShowAlbum: () -> Void
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                ArtworkCard(song: song, onShowAlbum: onShowAlbum)
                StatsCard(song: song)
                MetadataCard(song: song)
                
                Button(action: onReRank) {
                    Text(song.isRanked ? "Re-rank Song" : "Rank Song")
                        .fontWeight(.semibold)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.accentColor)
                        .foregroundColor(.white)
                        .cornerRadius(12)
                        .shadow(radius: 3)
                }
                .padding(.top, 5)
                
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
}

// The ArtworkCard is updated with better visual cues
struct ArtworkCard: View {
    let song: UnifiedSong
    let onShowAlbum: () -> Void
    
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
            }
            
            VStack(spacing: 8) {
                Text(song.title)
                    .font(.title2)
                    .bold()
                Text(song.artist)
                    .font(.title3)
                    .foregroundColor(.secondary)
                Button(action: onShowAlbum) {
                    HStack {
                        Text(song.album)
                            .font(.subheadline)
                            .foregroundColor(.accentColor)
                        Image(systemName: "chevron.right")
                            .font(.caption)
                            .foregroundColor(.accentColor)
                    }
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
}

// Rest of the code remains unchanged

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
            if let lastPlayed = song.lastPlayedDate {
                MetadataItem(label: "Last Played", value: lastPlayed, formatter: .dateTime)
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
