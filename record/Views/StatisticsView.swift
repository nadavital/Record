import SwiftUI
import MusicKit

struct StatisticsView: View {
    @EnvironmentObject private var musicAPI: MusicAPIManager
    @EnvironmentObject private var rankingManager: MusicRankingManager
    @Environment(\.colorScheme) private var colorScheme
    @State private var isRefreshing = false
    
    // Derived statistics
    private var listeningHistory: [ListeningHistoryItem] {
        musicAPI.listeningHistory
    }
    
    private var topSongs: [(song: ListeningHistoryItem, count: Int)] {
        let sortedSongs = listeningHistory
            .map { (song: $0, count: $0.playCount) }
            .sorted { $0.count > $1.count }
        return sortedSongs
    }
    
    private var topArtists: [(artist: String, count: Int)] {
        let artistCounts = Dictionary(grouping: listeningHistory, by: { $0.artist })
            .map { (artist: $0.key, count: $0.value.reduce(0) { $0 + $1.playCount }) }
            .sorted { $0.count > $1.count }
        return artistCounts
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
        return albumCounts
    }
    
    var body: some View {
        NavigationStack {
            mainContent
                .background(Color(.systemGroupedBackground).ignoresSafeArea())
                .navigationTitle("Music Insights")
                .navigationBarTitleDisplayMode(.large)
                .toolbar { toolbarContent }
                .refreshable { await refreshData() }
        }
    }
    
    // Main content view
    private var mainContent: some View {
        ScrollView {
            VStack(spacing: 20) {
                topSongsSection.padding(.horizontal)
                topArtistsSection.padding(.horizontal)
                topAlbumsSection.padding(.horizontal)
            }
            .padding(.vertical, 16)
        }
    }
    
    // Toolbar content
    private var toolbarContent: some ToolbarContent {
        ToolbarItem(placement: .navigationBarTrailing) {
            HStack {
                if isRefreshing {
                    ProgressView().controlSize(.small)
                }
                Button {
                    Task { await refreshData() }
                } label: {
                    Image(systemName: "arrow.clockwise")
                }
                .disabled(isRefreshing)
            }
        }
    }
    
    // Top Songs section with horizontal scroll
    private var topSongsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Top Songs").font(.headline).fontWeight(.semibold)
                Spacer()
                NavigationLink {
                    TopSongsListView(songs: topSongs, musicAPI: musicAPI, rankingManager: rankingManager)
                } label: {
                    Text("See All").font(.subheadline).foregroundColor(Color(.systemBlue))
                }
            }
            .padding(.horizontal, 4)
            
            if topSongs.isEmpty {
                Text("No listening data available")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .italic()
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.vertical, 16)
            } else {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 16) {
                        ForEach(topSongs.prefix(10), id: \.song.id) { item in
                            NavigationLink(destination: SongInfoView(mediaItem: item.song.mediaItem, musicAPI: musicAPI, rankingManager: rankingManager)) {
                                songView(song: item.song, count: item.count)
                            }
                        }
                    }
                    .padding(.horizontal, 4)
                    .padding(.vertical, 8)
                }
            }
        }
        .padding()
        .background(RoundedRectangle(cornerRadius: 16).fill(Color(.secondarySystemGroupedBackground)))
    }
    
    // Top Artists section with horizontal scroll
    private var topArtistsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Top Artists").font(.headline).fontWeight(.semibold)
                Spacer()
                NavigationLink {
                    TopArtistsListView(artists: topArtists)
                } label: {
                    Text("See All").font(.subheadline).foregroundColor(Color(.systemBlue))
                }
            }
            .padding(.horizontal, 4)
            
            if topArtists.isEmpty {
                Text("No artist data available")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .italic()
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.vertical, 16)
            } else {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 16) {
                        ForEach(topArtists.prefix(10), id: \.artist) { item in
                            artistView(artist: item.artist, count: item.count)
                        }
                    }
                    .padding(.horizontal, 4)
                    .padding(.vertical, 8)
                }
            }
        }
        .padding()
        .background(RoundedRectangle(cornerRadius: 16).fill(Color(.secondarySystemGroupedBackground)))
    }
    
    // Top Albums section with horizontal scroll
    private var topAlbumsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Top Albums").font(.headline).fontWeight(.semibold)
                Spacer()
                NavigationLink {
                    TopAlbumsListView(albums: topAlbums)
                } label: {
                    Text("See All").font(.subheadline).foregroundColor(Color(.systemBlue))
                }
            }
            .padding(.horizontal, 4)
            
            if topAlbums.isEmpty {
                Text("No album data available")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .italic()
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.vertical, 16)
            } else {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 16) {
                        ForEach(topAlbums.prefix(10), id: \.album) { item in
                            albumView(album: item.album, artist: item.artist, count: item.count)
                        }
                    }
                    .padding(.horizontal, 4)
                    .padding(.vertical, 8)
                }
            }
        }
        .padding()
        .background(RoundedRectangle(cornerRadius: 16).fill(Color(.secondarySystemGroupedBackground)))
    }
    
    // Song view with artwork for horizontal scroll
    private func songView(song: ListeningHistoryItem, count: Int) -> some View {
        VStack(alignment: .center, spacing: 8) {
            Group {
                if let artworkImage = musicAPI.getArtworkImage(for: song) {
                    Image(uiImage: artworkImage).resizable().scaledToFill()
                } else {
                    Rectangle()
                        .fill(generateGradient(from: song.title))
                        .overlay(Text(song.title.prefix(1).uppercased()).font(.system(size: 30, weight: .bold)).foregroundColor(.white))
                }
            }
            .frame(width: 110, height: 110)
            .cornerRadius(8)
            .shadow(radius: 2)
            
            VStack(spacing: 2) {
                Text(song.title).font(.callout).fontWeight(.medium).lineLimit(1).multilineTextAlignment(.center)
                Text(song.artist).font(.caption).foregroundColor(.secondary).lineLimit(1)
                Text("\(count) plays").font(.caption2).foregroundColor(.secondary).padding(.top, 2)
            }
            .frame(width: 110)
        }
    }
    
    // Artist view for horizontal scroll
    private func artistView(artist: String, count: Int) -> some View {
        VStack(alignment: .center, spacing: 8) {
            Group {
                if let artworkURL = musicAPI.getArtworkURL(for: artist) {
                    AsyncImage(url: artworkURL) { phase in
                        switch phase {
                        case .success(let image): image.resizable().scaledToFill()
                        case .failure(_), .empty: Circle().fill(generateGradient(from: artist)).overlay(Text(artist.prefix(1).uppercased()).font(.system(size: 30, weight: .bold)).foregroundColor(.white))
                        @unknown default: EmptyView()
                        }
                    }
                } else {
                    Circle().fill(generateGradient(from: artist)).overlay(Text(artist.prefix(1).uppercased()).font(.system(size: 30, weight: .bold)).foregroundColor(.white))
                }
            }
            .frame(width: 90, height: 90)
            .clipShape(Circle())
            .shadow(radius: 2)
            
            VStack(spacing: 2) {
                Text(artist).font(.callout).fontWeight(.medium).lineLimit(1).multilineTextAlignment(.center)
                Text("\(count) plays").font(.caption2).foregroundColor(.secondary).padding(.top, 2)
            }
            .frame(width: 100)
        }
    }
    
    // Album view for horizontal scroll
    private func albumView(album: String, artist: String, count: Int) -> some View {
        VStack(alignment: .center, spacing: 8) {
            Group {
                if let firstSong = listeningHistory.first(where: { $0.albumName == album && $0.artist == artist }),
                   let artworkImage = musicAPI.getArtworkImage(for: firstSong) {
                    Image(uiImage: artworkImage).resizable().scaledToFill()
                } else {
                    Rectangle().fill(generateGradient(from: album)).overlay(Text(album.prefix(1).uppercased()).font(.system(size: 30, weight: .bold)).foregroundColor(.white))
                }
            }
            .frame(width: 110, height: 110)
            .cornerRadius(8)
            .shadow(radius: 2)
            
            VStack(spacing: 2) {
                Text(album).font(.callout).fontWeight(.medium).lineLimit(1).multilineTextAlignment(.center)
                Text(artist).font(.caption).foregroundColor(.secondary).lineLimit(1)
                Text("\(count) plays").font(.caption2).foregroundColor(.secondary).padding(.top, 2)
            }
            .frame(width: 110)
        }
    }
    
    // Refresh data function
    private func refreshData() async {
        isRefreshing = true
        await musicAPI.checkMusicAuthorizationStatus()
        await musicAPI.fetchListeningHistory()
        isRefreshing = false
    }
    
    // Generate a consistent gradient based on input text
    private func generateGradient(from text: String) -> LinearGradient {
        let seed = text.isEmpty ? "A" : text
        let hash = abs(seed.hashValue)
        let hue1 = Double(hash % 360) / 360.0
        let hue2 = Double((hash / 360) % 360) / 360.0
        let brightness1 = colorScheme == .dark ? 0.7 : 0.85
        let brightness2 = colorScheme == .dark ? 0.5 : 0.7
        let color1 = Color(hue: hue1, saturation: 0.6, brightness: brightness1)
        let color2 = Color(hue: hue2, saturation: 0.7, brightness: brightness2)
        return LinearGradient(gradient: Gradient(colors: [color1, color2]), startPoint: .topLeading, endPoint: .bottomTrailing)
    }
}

// New Views for full lists
struct TopSongsListView: View {
    let songs: [(song: ListeningHistoryItem, count: Int)]
    let musicAPI: MusicAPIManager
    let rankingManager: MusicRankingManager
    
    var body: some View {
        List {
            ForEach(Array(songs.enumerated()), id: \.element.song.id) { index, item in
                NavigationLink(destination: SongInfoView(mediaItem: item.song.mediaItem, musicAPI: musicAPI, rankingManager: rankingManager)) {
                    HStack(spacing: 12) {
                        Text("#\(index + 1)")
                            .foregroundStyle(.secondary)
                            .frame(width: 40, alignment: .leading)
                            .font(.subheadline)
                        songRowView(song: item.song, count: item.count)
                    }
                }
            }
        }
        .navigationTitle("Top Songs")
        .navigationBarTitleDisplayMode(.inline)
    }
    
    private func songRowView(song: ListeningHistoryItem, count: Int) -> some View {
        HStack(spacing: 12) {
            Group {
                if let artworkImage = musicAPI.getArtworkImage(for: song) {
                    Image(uiImage: artworkImage).resizable().scaledToFill()
                } else {
                    Rectangle().fill(generateGradient(from: song.title)).overlay(Text(song.title.prefix(1).uppercased()).font(.system(size: 16, weight: .bold)).foregroundColor(.white))
                }
            }
            .frame(width: 50, height: 50)
            .cornerRadius(6)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(song.title).font(.body).lineLimit(1)
                Text(song.artist).font(.subheadline).foregroundColor(.secondary).lineLimit(1)
            }
            Spacer()
            Text("\(count) plays").font(.caption).foregroundColor(.secondary)
        }
    }
    
    private func generateGradient(from text: String) -> LinearGradient {
        // Copy the existing generateGradient implementation here
        let seed = text.isEmpty ? "A" : text
        let hash = abs(seed.hashValue)
        let hue1 = Double(hash % 360) / 360.0
        let hue2 = Double((hash / 360) % 360) / 360.0
        let brightness1 = 0.85
        let brightness2 = 0.7
        let color1 = Color(hue: hue1, saturation: 0.6, brightness: brightness1)
        let color2 = Color(hue: hue2, saturation: 0.7, brightness: brightness2)
        return LinearGradient(gradient: Gradient(colors: [color1, color2]), startPoint: .topLeading, endPoint: .bottomTrailing)
    }
}

struct TopArtistsListView: View {
    let artists: [(artist: String, count: Int)]
    
    var body: some View {
        List {
            ForEach(Array(artists.enumerated()), id: \.element.artist) { index, item in
                HStack(spacing: 12) {
                    Text("#\(index + 1)")
                        .foregroundStyle(.secondary)
                        .frame(width: 40, alignment: .leading)
                        .font(.subheadline)
                    Text(item.artist)
                        .font(.body)
                    Spacer()
                    Text("\(item.count) plays")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
        }
        .navigationTitle("Top Artists")
        .navigationBarTitleDisplayMode(.inline)
    }
}

struct TopAlbumsListView: View {
    let albums: [(album: String, artist: String, count: Int)]
    
    var body: some View {
        List {
            ForEach(Array(albums.enumerated()), id: \.element.album) { index, item in
                HStack(spacing: 12) {
                    Text("#\(index + 1)")
                        .foregroundStyle(.secondary)
                        .frame(width: 40, alignment: .leading)
                        .font(.subheadline)
                    VStack(alignment: .leading, spacing: 2) {
                        Text(item.album)
                            .font(.body)
                        Text(item.artist)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    Spacer()
                    Text("\(item.count) plays")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
        }
        .navigationTitle("Top Albums")
        .navigationBarTitleDisplayMode(.inline)
    }
}

#Preview("Statistics View") {
    StatisticsView()
        .environmentObject(MusicAPIManager())
        .environmentObject(MusicRankingManager())
}
