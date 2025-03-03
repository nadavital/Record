import SwiftUI
import MusicKit

struct StatisticsView: View {
    @StateObject private var musicAPI = MusicAPIManager()
    @Environment(\.colorScheme) private var colorScheme
    @State private var isLoading = true
    
    // Derived statistics
    private var listeningHistory: [ListeningHistoryItem] {
        musicAPI.listeningHistory
    }
    
    private var totalPlays: Int {
        listeningHistory.reduce(0) { $0 + $1.playCount }
    }
    
    private var uniqueSongs: Int {
        listeningHistory.count
    }
    
    private var topSongs: [(song: ListeningHistoryItem, count: Int)] {
        let sortedSongs = listeningHistory
            .map { (song: $0, count: $0.playCount) }
            .sorted { $0.count > $1.count }
        return Array(sortedSongs.prefix(10))
    }
    
    private var topArtists: [(artist: String, count: Int)] {
        let artistCounts = Dictionary(grouping: listeningHistory, by: { $0.artist })
            .map { (artist: $0.key, count: $0.value.reduce(0) { $0 + $1.playCount }) }
            .sorted { $0.count > $1.count }
        return Array(artistCounts.prefix(10))
    }
    
    private var topAlbums: [(album: String, artist: String, count: Int)] {
        let albumCounts = Dictionary(grouping: listeningHistory, by: { "\($0.albumName)||\($0.artist)" })
            .map { key, value in
                let components = key.components(separatedBy: "||")
                return (
                    album: components.first ?? "",
                    artist: components.last ?? "",
                    count: value.reduce(0) { $0 + $1.playCount }
                )
            }
            .filter { !$0.album.isEmpty }
            .sorted { $0.count > $1.count }
        return Array(albumCounts.prefix(10))
    }
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    // Overview Section
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Overview")
                            .font(.headline)
                            .foregroundColor(.white)
                            .padding(.horizontal, 4)
                        HStack {
                            Image(systemName: "music.note.list")
                                .foregroundColor(Color(red: 0.94, green: 0.3, blue: 0.9))
                            Text("Total Plays")
                            Spacer()
                            Text("\(totalPlays)")
                                .foregroundColor(.gray)
                        }
                        .padding(.horizontal, 4)
                        HStack {
                            Image(systemName: "music.note")
                                .foregroundColor(Color(red: 0.94, green: 0.3, blue: 0.9))
                            Text("Unique Songs")
                            Spacer()
                            Text("\(uniqueSongs)")
                                .foregroundColor(.gray)
                        }
                        .padding(.horizontal, 4)
                    }
                    .padding()
                    .background(
                        RoundedRectangle(cornerRadius: 16)
                            .fill(Color(.secondarySystemGroupedBackground))
                    )
                    .padding(.horizontal)
                    
                    // Top Songs Section
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Top Songs")
                            .font(.headline)
                            .foregroundColor(.white)
                            .padding(.horizontal, 4)
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 16) {
                                if topSongs.isEmpty {
                                    Text("No data available")
                                        .foregroundColor(.gray)
                                        .padding(.vertical, 16)
                                } else {
                                    ForEach(topSongs, id: \.song.id) { song in
                                        songView(song: song.song, count: song.count)
                                    }
                                }
                            }
                            .padding(.horizontal, 4)
                            .padding(.vertical, 8)
                        }
                    }
                    .padding()
                    .background(
                        RoundedRectangle(cornerRadius: 16)
                            .fill(Color(.secondarySystemGroupedBackground))
                    )
                    .padding(.horizontal)
                    
                    // Top Artists Section
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Top Artists")
                            .font(.headline)
                            .foregroundColor(.white)
                            .padding(.horizontal, 4)
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 16) {
                                if topArtists.isEmpty {
                                    Text("No data available")
                                        .foregroundColor(.gray)
                                        .padding(.vertical, 16)
                                } else {
                                    ForEach(topArtists, id: \.artist) { artist in
                                        artistView(artist: artist.artist, count: artist.count)
                                    }
                                }
                            }
                            .padding(.horizontal, 4)
                            .padding(.vertical, 8)
                        }
                    }
                    .padding()
                    .background(
                        RoundedRectangle(cornerRadius: 16)
                            .fill(Color(.secondarySystemGroupedBackground))
                    )
                    .padding(.horizontal)
                    
                    // Top Albums Section
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Top Albums")
                            .font(.headline)
                            .foregroundColor(.white)
                            .padding(.horizontal, 4)
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 16) {
                                if topAlbums.isEmpty {
                                    Text("No data available")
                                        .foregroundColor(.gray)
                                        .padding(.vertical, 16)
                                } else {
                                    ForEach(topAlbums, id: \.album) { album in
                                        albumView(album: album.album, artist: album.artist, count: album.count)
                                    }
                                }
                            }
                            .padding(.horizontal, 4)
                            .padding(.vertical, 8)
                        }
                    }
                    .padding()
                    .background(
                        RoundedRectangle(cornerRadius: 16)
                            .fill(Color(.secondarySystemGroupedBackground))
                    )
                    .padding(.horizontal)
                }
                .padding(.vertical)
            }
            .background(
                LinearGradient(
                    gradient: Gradient(colors: [
                        Color.black.opacity(0.8),
                        Color(red: 0.1, green: 0.05, blue: 0.2)
                    ]),
                    startPoint: .top,
                    endPoint: .bottom
                )
                .ignoresSafeArea()
            )
            .navigationTitle("Music Insights")
            .foregroundColor(.white)
            .overlay {
                if isLoading {
                    ProgressView("Loading Insights...")
                        .foregroundColor(.white)
                }
            }
        }
        .task {
            isLoading = true
            await musicAPI.checkMusicAuthorizationStatus()
            await musicAPI.fetchListeningHistory()
            isLoading = false
        }
    }
    
    // Song view with artwork
    private func songView(song: ListeningHistoryItem, count: Int) -> some View {
        VStack(alignment: .center, spacing: 6) {
            if let artworkImage = musicAPI.getArtworkImage(for: song) {
                Image(uiImage: artworkImage)
                    .resizable()
                    .scaledToFill()
                    .frame(width: 100, height: 100)
                    .cornerRadius(8)
                    .shadow(radius: 2)
            } else {
                Rectangle()
                    .fill(Color.gray.opacity(0.3))
                    .frame(width: 100, height: 100)
                    .cornerRadius(8)
                    .overlay(
                        Text(song.title.prefix(1).uppercased())
                            .font(.system(size: 32, weight: .bold))
                            .foregroundColor(.white)
                    )
                    .shadow(radius: 2)
            }
            Text(song.title)
                .font(.caption)
                .fontWeight(.medium)
                .lineLimit(1)
                .frame(width: 100)
                .multilineTextAlignment(.center)
            Text(song.artist)
                .font(.caption2)
                .foregroundColor(.gray)
                .lineLimit(1)
                .frame(width: 100)
                .multilineTextAlignment(.center)
            Text("\(count) plays")
                .font(.caption2)
                .foregroundColor(.gray)
        }
    }
    
    // Artist view with placeholder
    private func artistView(artist: String, count: Int) -> some View {
        VStack(alignment: .center, spacing: 6) {
            if let artworkURL = musicAPI.getArtworkURL(for: artist) {
                AsyncImage(url: artworkURL) { phase in
                    switch phase {
                    case .success(let image):
                        image
                            .resizable()
                            .scaledToFill()
                            .frame(width: 85, height: 85)
                            .clipShape(Circle())
                            .shadow(radius: 2)
                    case .failure(_), .empty:
                        Circle()
                            .fill(Color.gray.opacity(0.3))
                            .frame(width: 85, height: 85)
                            .overlay(
                                Text(artist.prefix(1).uppercased())
                                    .font(.system(size: 32, weight: .bold))
                                    .foregroundColor(.white)
                            )
                            .shadow(radius: 2)
                    @unknown default:
                        EmptyView()
                    }
                }
            } else {
                Circle()
                    .fill(Color.gray.opacity(0.3))
                    .frame(width: 85, height: 85)
                    .overlay(
                        Text(artist.prefix(1).uppercased())
                            .font(.system(size: 32, weight: .bold))
                            .foregroundColor(.white)
                    )
                    .shadow(radius: 2)
            }
            Text(artist)
                .font(.caption)
                .fontWeight(.medium)
                .lineLimit(1)
                .frame(width: 85)
                .multilineTextAlignment(.center)
            Text("\(count) plays")
                .font(.caption2)
                .foregroundColor(.gray)
        }
    }
    
    // Album view with artwork
    private func albumView(album: String, artist: String, count: Int) -> some View {
        VStack(alignment: .center, spacing: 6) {
            if let firstSong = listeningHistory.first(where: { $0.albumName == album && $0.artist == artist }),
               let artworkImage = musicAPI.getArtworkImage(for: firstSong) {
                Image(uiImage: artworkImage)
                    .resizable()
                    .scaledToFill()
                    .frame(width: 100, height: 100)
                    .cornerRadius(8)
                    .shadow(radius: 2)
            } else {
                Rectangle()
                    .fill(Color.gray.opacity(0.3))
                    .frame(width: 100, height: 100)
                    .cornerRadius(8)
                    .overlay(
                        Text(album.prefix(1).uppercased())
                            .font(.system(size: 32, weight: .bold))
                            .foregroundColor(.white)
                    )
                    .shadow(radius: 2)
            }
            Text(album)
                .font(.caption)
                .fontWeight(.medium)
                .lineLimit(1)
                .frame(width: 100)
                .multilineTextAlignment(.center)
            Text(artist)
                .font(.caption2)
                .foregroundColor(.gray)
                .lineLimit(1)
                .frame(width: 100)
                .multilineTextAlignment(.center)
            Text("\(count) plays")
                .font(.caption2)
                .foregroundColor(.gray)
        }
    }
}

#Preview("Statistics View") {
    StatisticsView()
}
