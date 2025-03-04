import SwiftUI
import MusicKit

struct StatisticsView: View {
    @EnvironmentObject private var musicAPI: MusicAPIManager
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
        // Show all songs in detail view
        return sortedSongs
    }
    
    private var topArtists: [(artist: String, count: Int)] {
        let artistCounts = Dictionary(grouping: listeningHistory, by: { $0.artist })
            .map { (artist: $0.key, count: $0.value.reduce(0) { $0 + $1.playCount }) }
            .sorted { $0.count > $1.count }
        // Show all artists in detail view
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
        // Show all albums in detail view
        return albumCounts
    }
    
    @State private var showingSongsList = false
    @State private var showingArtistsList = false
    @State private var showingAlbumsList = false
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    // Top Songs Section
                    topSongsSection
                        .padding(.horizontal)
                    
                    // Top Artists Section
                    topArtistsSection
                        .padding(.horizontal)
                    
                    // Top Albums Section
                    topAlbumsSection
                        .padding(.horizontal)
                }
                .padding(.vertical, 16)
            }
            .background(Color(.systemGroupedBackground).ignoresSafeArea())
            .navigationTitle("Music Insights")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    HStack {
                        if isRefreshing {
                            ProgressView()
                                .controlSize(.small)
                        }
                        
                        Button {
                            Task {
                                await refreshData()
                            }
                        } label: {
                            Image(systemName: "arrow.clockwise")
                        }
                        .disabled(isRefreshing)
                    }
                }
            }
            .refreshable {
                await refreshData()
            }
            .sheet(isPresented: $showingSongsList) {
                NavigationStack {
                    List {
                        ForEach(Array(topSongs.enumerated()), id: \.element.song.id) { index, item in
                            HStack(spacing: 12) {
                                Text("#\(index + 1)")
                                    .foregroundStyle(.secondary)
                                    .frame(width: 40, alignment: .leading)
                                    .font(.subheadline)
                                
                                songRowView(song: item.song, count: item.count)
                            }
                        }
                    }
                    .navigationTitle("Top Songs")
                    .navigationBarTitleDisplayMode(.inline)
                    .toolbar {
                        ToolbarItem(placement: .navigationBarTrailing) {
                            Button("Done") {
                                showingSongsList = false
                            }
                        }
                    }
                }
            }
            .sheet(isPresented: $showingArtistsList) {
                NavigationStack {
                    List {
                        ForEach(Array(topArtists.enumerated()), id: \.element.artist) { index, item in
                            HStack(spacing: 12) {
                                Text("#\(index + 1)")
                                    .foregroundStyle(.secondary)
                                    .frame(width: 40, alignment: .leading)
                                    .font(.subheadline)
                                
                                artistRowView(artist: item.artist, count: item.count)
                            }
                        }
                    }
                    .navigationTitle("Top Artists")
                    .navigationBarTitleDisplayMode(.inline)
                    .toolbar {
                        ToolbarItem(placement: .navigationBarTrailing) {
                            Button("Done") {
                                showingArtistsList = false
                            }
                        }
                    }
                }
            }
            .sheet(isPresented: $showingAlbumsList) {
                NavigationStack {
                    List {
                        ForEach(Array(topAlbums.enumerated()), id: \.element.album) { index, item in
                            HStack(spacing: 12) {
                                Text("#\(index + 1)")
                                    .foregroundStyle(.secondary)
                                    .frame(width: 40, alignment: .leading)
                                    .font(.subheadline)
                                
                                albumRowView(album: item.album, artist: item.artist, count: item.count)
                            }
                        }
                    }
                    .navigationTitle("Top Albums")
                    .navigationBarTitleDisplayMode(.inline)
                    .toolbar {
                        ToolbarItem(placement: .navigationBarTrailing) {
                            Button("Done") {
                                showingAlbumsList = false
                            }
                        }
                    }
                }
            }
        }
    }
    
    // Refresh data function
    private func refreshData() async {
        isRefreshing = true
        await musicAPI.checkMusicAuthorizationStatus()
        await musicAPI.fetchListeningHistory()
        isRefreshing = false
    }
    
    // Top Songs section with horizontal scroll
    private var topSongsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header with see all button
            HStack {
                Text("Top Songs")
                    .font(.headline)
                    .fontWeight(.semibold)
                
                Spacer()
                
                Button {
                    showingSongsList = true
                } label: {
                    Text("See All")
                        .font(.subheadline)
                        .foregroundColor(Color(.systemBlue))
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
                            songView(song: item.song, count: item.count)
                        }
                    }
                    .padding(.horizontal, 4)
                    .padding(.vertical, 8)
                }
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.secondarySystemGroupedBackground))
        )
    }
    
    // Top Artists section with horizontal scroll
    private var topArtistsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header with see all button
            HStack {
                Text("Top Artists")
                    .font(.headline)
                    .fontWeight(.semibold)
                
                Spacer()
                
                Button {
                    showingArtistsList = true
                } label: {
                    Text("See All")
                        .font(.subheadline)
                        .foregroundColor(Color(.systemBlue))
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
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.secondarySystemGroupedBackground))
        )
    }
    
    // Top Albums section with horizontal scroll
    private var topAlbumsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header with see all button
            HStack {
                Text("Top Albums")
                    .font(.headline)
                    .fontWeight(.semibold)
                
                Spacer()
                
                Button {
                    showingAlbumsList = true
                } label: {
                    Text("See All")
                        .font(.subheadline)
                        .foregroundColor(Color(.systemBlue))
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
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.secondarySystemGroupedBackground))
        )
    }
    
    // Song view with artwork for horizontal scroll
    private func songView(song: ListeningHistoryItem, count: Int) -> some View {
        VStack(alignment: .center, spacing: 8) {
            // Artwork with shadow
            Group {
                if let artworkImage = musicAPI.getArtworkImage(for: song) {
                    Image(uiImage: artworkImage)
                        .resizable()
                        .scaledToFill()
                } else {
                    Rectangle()
                        .fill(generateGradient(from: song.title))
                        .overlay(
                            Text(song.title.prefix(1).uppercased())
                                .font(.system(size: 30, weight: .bold))
                                .foregroundColor(.white)
                        )
                }
            }
            .frame(width: 110, height: 110)
            .cornerRadius(8)
            .shadow(radius: 2)
            
            // Song info
            VStack(spacing: 2) {
                Text(song.title)
                    .font(.callout)
                    .fontWeight(.medium)
                    .lineLimit(1)
                    .multilineTextAlignment(.center)
                
                Text(song.artist)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .lineLimit(1)
                
                Text("\(count) plays")
                    .font(.caption2)
                    .foregroundColor(.secondary)
                    .padding(.top, 2)
            }
            .frame(width: 110)
        }
    }
    
    // Artist view for horizontal scroll
    private func artistView(artist: String, count: Int) -> some View {
        VStack(alignment: .center, spacing: 8) {
            // Artist image
            Group {
                if let artworkURL = musicAPI.getArtworkURL(for: artist) {
                    AsyncImage(url: artworkURL) { phase in
                        switch phase {
                        case .success(let image):
                            image
                                .resizable()
                                .scaledToFill()
                        case .failure(_), .empty:
                            Circle()
                                .fill(generateGradient(from: artist))
                                .overlay(
                                    Text(artist.prefix(1).uppercased())
                                        .font(.system(size: 30, weight: .bold))
                                        .foregroundColor(.white)
                                )
                        @unknown default:
                            EmptyView()
                        }
                    }
                } else {
                    Circle()
                        .fill(generateGradient(from: artist))
                        .overlay(
                            Text(artist.prefix(1).uppercased())
                                .font(.system(size: 30, weight: .bold))
                                .foregroundColor(.white)
                        )
                }
            }
            .frame(width: 90, height: 90)
            .clipShape(Circle())
            .shadow(radius: 2)
            
            // Artist info
            VStack(spacing: 2) {
                Text(artist)
                    .font(.callout)
                    .fontWeight(.medium)
                    .lineLimit(1)
                    .multilineTextAlignment(.center)
                
                Text("\(count) plays")
                    .font(.caption2)
                    .foregroundColor(.secondary)
                    .padding(.top, 2)
            }
            .frame(width: 100)
        }
    }
    
    // Album view for horizontal scroll
    private func albumView(album: String, artist: String, count: Int) -> some View {
        VStack(alignment: .center, spacing: 8) {
            // Album artwork
            Group {
                if let firstSong = listeningHistory.first(where: { $0.albumName == album && $0.artist == artist }),
                   let artworkImage = musicAPI.getArtworkImage(for: firstSong) {
                    Image(uiImage: artworkImage)
                        .resizable()
                        .scaledToFill()
                } else {
                    Rectangle()
                        .fill(generateGradient(from: album))
                        .overlay(
                            Text(album.prefix(1).uppercased())
                                .font(.system(size: 30, weight: .bold))
                                .foregroundColor(.white)
                        )
                }
            }
            .frame(width: 110, height: 110)
            .cornerRadius(8)
            .shadow(radius: 2)
            
            // Album info
            VStack(spacing: 2) {
                Text(album)
                    .font(.callout)
                    .fontWeight(.medium)
                    .lineLimit(1)
                    .multilineTextAlignment(.center)
                
                Text(artist)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .lineLimit(1)
                
                Text("\(count) plays")
                    .font(.caption2)
                    .foregroundColor(.secondary)
                    .padding(.top, 2)
            }
            .frame(width: 110)
        }
    }
    
    // Song list row view
    private func songRowView(song: ListeningHistoryItem, count: Int) -> some View {
        HStack(spacing: 12) {
            // Artwork
            Group {
                if let artworkImage = musicAPI.getArtworkImage(for: song) {
                    Image(uiImage: artworkImage)
                        .resizable()
                        .scaledToFill()
                } else {
                    Rectangle()
                        .fill(generateGradient(from: song.title))
                        .overlay(
                            Text(song.title.prefix(1).uppercased())
                                .font(.system(size: 16, weight: .bold))
                                .foregroundColor(.white)
                        )
                }
            }
            .frame(width: 50, height: 50)
            .cornerRadius(6)
            
            // Song details
            VStack(alignment: .leading, spacing: 2) {
                Text(song.title)
                    .font(.body)
                    .lineLimit(1)
                
                Text(song.artist)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .lineLimit(1)
            }
            
            Spacer()
            
            // Play count
            Text("\(count) plays")
                .font(.caption)
                .foregroundColor(.secondary)
        }
    }
    
    // Artist list row view
    private func artistRowView(artist: String, count: Int) -> some View {
        HStack(spacing: 12) {
            // Artist avatar
            Group {
                if let artworkURL = musicAPI.getArtworkURL(for: artist) {
                    AsyncImage(url: artworkURL) { phase in
                        switch phase {
                        case .success(let image):
                            image
                                .resizable()
                                .scaledToFill()
                        case .failure(_), .empty:
                            Circle()
                                .fill(generateGradient(from: artist))
                                .overlay(
                                    Text(artist.prefix(1).uppercased())
                                        .font(.system(size: 16, weight: .bold))
                                        .foregroundColor(.white)
                                )
                        @unknown default:
                            EmptyView()
                        }
                    }
                } else {
                    Circle()
                        .fill(generateGradient(from: artist))
                        .overlay(
                            Text(artist.prefix(1).uppercased())
                                .font(.system(size: 16, weight: .bold))
                                .foregroundColor(.white)
                        )
                }
            }
            .frame(width: 50, height: 50)
            .clipShape(Circle())
            
            // Artist name
            Text(artist)
                .font(.body)
                .lineLimit(1)
            
            Spacer()
            
            // Play count
            Text("\(count) plays")
                .font(.caption)
                .foregroundColor(.secondary)
        }
    }
    
    // Album list row view
    private func albumRowView(album: String, artist: String, count: Int) -> some View {
        HStack(spacing: 12) {
            // Album artwork
            Group {
                if let firstSong = listeningHistory.first(where: { $0.albumName == album && $0.artist == artist }),
                   let artworkImage = musicAPI.getArtworkImage(for: firstSong) {
                    Image(uiImage: artworkImage)
                        .resizable()
                        .scaledToFill()
                } else {
                    Rectangle()
                        .fill(generateGradient(from: album))
                        .overlay(
                            Text(album.prefix(1).uppercased())
                                .font(.system(size: 16, weight: .bold))
                                .foregroundColor(.white)
                        )
                }
            }
            .frame(width: 50, height: 50)
            .cornerRadius(6)
            
            // Album details
            VStack(alignment: .leading, spacing: 2) {
                Text(album)
                    .font(.body)
                    .lineLimit(1)
                
                Text(artist)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .lineLimit(1)
            }
            
            Spacer()
            
            // Play count
            Text("\(count) plays")
                .font(.caption)
                .foregroundColor(.secondary)
        }
    }
    
    // Generate a consistent gradient based on input text
    private func generateGradient(from text: String) -> LinearGradient {
        let seed = text.isEmpty ? "A" : text
        let hash = abs(seed.hashValue)
        
        // Generate two colors based on the hash
        let hue1 = Double(hash % 360) / 360.0
        let hue2 = Double((hash / 360) % 360) / 360.0
        
        // Adjust brightness based on color scheme
        let brightness1 = colorScheme == .dark ? 0.7 : 0.85
        let brightness2 = colorScheme == .dark ? 0.5 : 0.7
        
        let color1 = Color(hue: hue1, saturation: 0.6, brightness: brightness1)
        let color2 = Color(hue: hue2, saturation: 0.7, brightness: brightness2)
        
        return LinearGradient(
            gradient: Gradient(colors: [color1, color2]),
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }
}

#Preview("Statistics View") {
    StatisticsView()
        .environmentObject(MusicAPIManager())
}
