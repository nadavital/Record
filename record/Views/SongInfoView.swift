import SwiftUI
import MediaPlayer
import MusicKit

struct SongInfoView: View {
    @StateObject private var viewModel: SongInfoViewModel
    @EnvironmentObject private var rankingManager: MusicRankingManager
    @Environment(\.dismiss) var dismiss
    
    private let mediaItem: MPMediaItem?
    private let rankedSong: Song?
    @State private var reRankedSong: Song? // Track re-ranked song locally
    
    init(mediaItem: MPMediaItem? = nil, rankedSong: Song? = nil, musicAPI: MusicAPIManager, rankingManager: MusicRankingManager) {
        self._viewModel = StateObject(wrappedValue: SongInfoViewModel(musicAPI: musicAPI, rankingManager: rankingManager))
        self.mediaItem = mediaItem
        self.rankedSong = rankedSong
    }
    
    var body: some View {
        NavigationStack {
            Group {
                if viewModel.isLoading {
                    ProgressView()
                } else if let song = viewModel.unifiedSong {
                    ScrollView {
                        VStack(spacing: 20) {
                            if let url = song.artworkURL {
                                AsyncImage(url: url) { image in
                                    image.resizable().scaledToFit()
                                } placeholder: {
                                    Color.gray
                                }
                                .frame(width: 200, height: 200)
                                .cornerRadius(10)
                            }
                            VStack(spacing: 8) {
                                Text(song.title).font(.title).bold()
                                Text(song.artist).font(.title2).foregroundColor(.secondary)
                                Text(song.album).font(.subheadline).foregroundColor(.secondary)
                            }
                            HStack(spacing: 20) {
                                statView(label: "Plays", value: "\(song.playCount)")
                                if song.isRanked {
                                    statView(label: "Rank", value: "#\(song.rank ?? 0)")
                                    statView(label: "Score", value: String(format: "%.1f", song.score ?? 0))
                                }
                            }
                            if let releaseDate = song.releaseDate {
                                metadataView(label: "Release Date", value: releaseDate, formatter: .date)
                            }
                            if let genre = song.genre {
                                metadataView(label: "Genre", value: genre)
                            }
                            if let lastPlayed = song.lastPlayedDate {
                                metadataView(label: "Last Played", value: lastPlayed, formatter: .dateTime)
                            }
                            Button(action: {
                                reRankSong(currentSong: song)
                            }) {
                                Text("Re-rank Song")
                                    .frame(maxWidth: .infinity)
                                    .padding()
                                    .background(Color.blue)
                                    .foregroundColor(.white)
                                    .cornerRadius(10)
                            }
                            .padding(.top)
                        }
                        .padding()
                    }
                } else if let error = viewModel.errorMessage {
                    Text(error).foregroundColor(.red)
                } else {
                    Text("No song data available").foregroundColor(.gray)
                }
            }
            .navigationTitle("Song Info")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") { dismiss() }
                }
            }
            .onAppear {
                Task {
                    if let mediaItem = mediaItem {
                        await viewModel.loadSongInfo(from: mediaItem)
                    } else if let rankedSong = rankedSong {
                        await viewModel.loadSongInfo(from: rankedSong)
                    }
                }
            }
            .onChange(of: rankingManager.isRanking) { isRanking in
                if !isRanking, let reRankedSong = reRankedSong {
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
    
    private func statView(label: String, value: String) -> some View {
        VStack {
            Text(value).font(.headline)
            Text(label).font(.caption).foregroundColor(.secondary)
        }
    }
    
    private func metadataView(label: String, value: Any, formatter: Formatter? = nil) -> some View {
        HStack {
            Text(label + ":")
            Spacer()
            if let formatter = formatter, let date = value as? Date {
                Text(formatter.string(for: date) ?? "")
            } else {
                Text("\(value)")
            }
        }
        .font(.subheadline)
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
