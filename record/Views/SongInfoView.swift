struct SongInfoView: View {
    @ObservedObject var viewModel: SongInfoViewModel
    @Environment(\.dismiss) var dismiss
    
    init(mediaItem: MPMediaItem? = nil, rankedSong: Song? = nil, musicAPI: MusicAPIManager, rankingManager: MusicRankingManager) {
        self.viewModel = SongInfoViewModel(musicAPI: musicAPI, rankingManager: rankingManager)
        if let mediaItem = mediaItem {
            Task { await viewModel.loadSongInfo(from: mediaItem) }
        } else if let rankedSong = rankedSong {
            Task { await viewModel.loadSongInfo(from: rankedSong) }
        }
    }
    
    var body: some View {
        NavigationStack {
            Group {
                if viewModel.isLoading {
                    ProgressView()
                } else if let song = viewModel.unifiedSong {
                    ScrollView {
                        VStack(spacing: 20) {
                            // Artwork
                            if let url = song.artworkURL {
                                AsyncImage(url: url) { image in
                                    image.resizable().scaledToFit()
                                } placeholder: {
                                    Color.gray
                                }
                                .frame(width: 200, height: 200)
                                .cornerRadius(10)
                            }
                            
                            // Song Details
                            VStack(spacing: 8) {
                                Text(song.title).font(.title).bold()
                                Text(song.artist).font(.title2).foregroundColor(.secondary)
                                Text(song.album).font(.subheadline).foregroundColor(.secondary)
                            }
                            
                            // Stats and Ranking
                            HStack(spacing: 20) {
                                statView(label: "Plays", value: "\(song.playCount)")
                                if song.isRanked {
                                    statView(label: "Rank", value: "#\(song.rank ?? 0)")
                                    statView(label: "Score", value: String(format: "%.1f", song.score ?? 0))
                                }
                            }
                            
                            // Additional Metadata
                            if let releaseDate = song.releaseDate {
                                metadataView(label: "Release Date", value: releaseDate, formatter: .date)
                            }
                            if let genre = song.genre {
                                metadataView(label: "Genre", value: genre)
                            }
                            if let lastPlayed = song.lastPlayedDate {
                                metadataView(label: "Last Played", value: lastPlayed, formatter: .dateTime)
                            }
                            
                            // Re-rank Button
                            Button(action: { viewModel.reRankSong() }) {
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
                }
            }
            .navigationTitle("Song Info")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") { dismiss() }
                }
            }
        }
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

// Formatter for dates
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