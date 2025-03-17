import Foundation
import MusicKit
import SwiftUI
import os.log

@MainActor
class MusicAPIManager: ObservableObject {
    @Published var searchResults: [MusicItem] = []
    @Published var isSearching = false
    @Published var errorMessage: String?
    @Published var authorizationStatus: MusicAuthorization.Status = .notDetermined
    @Published var recentSongs: [MusicItem] = []
    @Published var recentAlbums: [MusicItem] = []
    @Published var recentArtists: [MusicItem] = []
    @Published var listeningHistory: [ListeningHistoryItem] = []
    @Published var currentPlayingSong: Song? = nil // Still maintained for compatibility
    
    private var artworkCache: [String: URL] = [:]
    private var activeTask: Task<Void, Never>?
    
    private let logger = Logger(subsystem: "com.Nadav.record", category: "MusicAPIManager")
    private var rankingManager: MusicRankingManager?
    
    init() {
        Task {
            await checkMusicAuthorizationStatus()
        }
    }
    
    func setRankingManager(_ manager: MusicRankingManager) {
        self.rankingManager = manager
    }
    
    func checkIfSongIsRanked(title: String, artist: String) -> (isRanked: Bool, rank: Int, score: Double)? {
        guard let rankingManager = self.rankingManager else {
            return nil
        }
        
        if let index = rankingManager.rankedSongs.firstIndex(where: {
            $0.title.lowercased() == title.lowercased() &&
            $0.artist.lowercased() == artist.lowercased()
        }) {
            let song = rankingManager.rankedSongs[index]
            return (true, index + 1, song.score)
        }
        
        return (false, 0, 0.0)
    }
    
    func checkMusicAuthorizationStatus() async {
        self.authorizationStatus = MusicAuthorization.currentStatus
        
        if self.authorizationStatus != .authorized {
            self.authorizationStatus = await MusicAuthorization.request()
        }
    }
    
    func searchMusic(query: String) async {
        await search(query: query, type: MusicKit.Song.self)
    }
    
    func searchAlbums(query: String) async {
        await search(query: query, type: MusicKit.Album.self)
    }
    
    func searchArtists(query: String) async {
        await search(query: query, type: MusicKit.Artist.self)
    }
    
    private func search<T: MusicCatalogSearchable>(query: String, type: T.Type) async {
        activeTask?.cancel()
        
        if query.isEmpty {
            self.searchResults = []
            self.isSearching = false
            self.errorMessage = nil
            return
        }
        
        self.isSearching = true
        self.errorMessage = nil
        
        let task = Task {
            do {
                logger.debug("Searching for '\(query)' with type \(String(describing: type))")
                
                var request = MusicCatalogSearchRequest(term: query, types: [type])
                request.limit = 25
                
                let response = try await request.response()
                
                if Task.isCancelled {
                    logger.debug("Search cancelled after response")
                    return
                }
                
                var items: [MusicItem] = []
                
                if type == MusicKit.Song.self {
                    for song in response.songs {
                        if Task.isCancelled { return }
                        
                        let id = song.id.description
                        if let artwork = song.artwork {
                            self.artworkCache[id] = artwork.url(width: 300, height: 300)
                        }
                        
                        items.append(MusicItem(
                            id: id,
                            title: song.title,
                            artist: song.artistName,
                            albumName: song.albumTitle ?? "",
                            artworkID: id,
                            type: .song
                        ))
                    }
                } else if type == MusicKit.Album.self {
                    for album in response.albums {
                        if Task.isCancelled { return }
                        
                        let id = album.id.description
                        if let artwork = album.artwork {
                            self.artworkCache[id] = artwork.url(width: 300, height: 300)
                        }
                        
                        items.append(MusicItem(
                            id: id,
                            title: album.title,
                            artist: album.artistName,
                            albumName: album.title,
                            artworkID: id,
                            type: .album
                        ))
                    }
                } else if type == MusicKit.Artist.self {
                    for artist in response.artists {
                        if Task.isCancelled { return }
                        
                        let id = artist.id.description
                        if self.artworkCache[id] == nil {
                            var albumRequest = MusicCatalogSearchRequest(term: artist.name, types: [MusicKit.Album.self])
                            albumRequest.limit = 1
                            if let albumResponse = try? await albumRequest.response(),
                               let album = albumResponse.albums.first,
                               let artwork = album.artwork {
                                self.artworkCache[id] = artwork.url(width: 300, height: 300)
                            }
                        }
                        
                        items.append(MusicItem(
                            id: id,
                            title: artist.name,
                            artist: artist.name,
                            albumName: "",
                            artworkID: id,
                            type: .artist
                        ))
                    }
                }
                
                if !Task.isCancelled {
                    logger.debug("Search completed: found \(items.count) results")
                    await MainActor.run {
                        self.searchResults = items
                        self.isSearching = false
                    }
                }
                
            } catch {
                if !Task.isCancelled {
                    logger.error("Search error: \(error.localizedDescription)")
                    await MainActor.run {
                        self.errorMessage = "Search failed: \(error.localizedDescription)"
                        self.isSearching = false
                    }
                }
            }
        }
        
        activeTask = task
        await task.value
    }
    
    func fetchRecentSongs(limit: Int = 10) async {
        guard authorizationStatus == .authorized else {
            logger.debug("Cannot fetch recent songs - not authorized")
            return
        }
        
        do {
            logger.debug("Fetching recent songs")
            var request = MusicRecentlyPlayedRequest<MusicKit.Song>()
            request.limit = limit
            let response = try await request.response()
            
            var songs: [MusicItem] = []
            var albums: [String: MusicItem] = [:]
            var artists: [String: MusicItem] = [:]
            
            for song in response.items {
                let id = song.id.description
                if let artwork = song.artwork {
                    self.artworkCache[id] = artwork.url(width: 300, height: 300)
                }
                
                let songItem = MusicItem(
                    id: id,
                    title: song.title,
                    artist: song.artistName,
                    albumName: song.albumTitle ?? "",
                    artworkID: id,
                    type: .song
                )
                songs.append(songItem)
                
                if let albumTitle = song.albumTitle, !albumTitle.isEmpty {
                    let albumKey = "\(albumTitle.lowercased())-\(song.artistName.lowercased())"
                    if albums[albumKey] == nil {
                        let albumItem = MusicItem(
                            id: UUID().uuidString,
                            title: albumTitle,
                            artist: song.artistName,
                            albumName: albumTitle,
                            artworkID: id,
                            type: .album
                        )
                        albums[albumKey] = albumItem
                    }
                }
                
                let artistKey = song.artistName.lowercased()
                if artists[artistKey] == nil {
                    let artistItem = MusicItem(
                        id: UUID().uuidString,
                        title: song.artistName,
                        artist: song.artistName,
                        albumName: "",
                        artworkID: id,
                        type: .artist
                    )
                    artists[artistKey] = artistItem
                }
            }
            
            await MainActor.run {
                self.recentSongs = songs
                self.recentAlbums = Array(albums.values.prefix(limit))
                self.recentArtists = Array(artists.values.prefix(limit))
                logger.debug("Fetched \(songs.count) songs, \(self.recentAlbums.count) albums, \(self.recentArtists.count) artists")
            }
            
        } catch {
            logger.error("Failed to fetch recent songs: \(error.localizedDescription)")
            await MainActor.run {
                self.errorMessage = "Failed to load recent items: \(error.localizedDescription)"
            }
        }
    }
    
    // Simplified to fetch listening history from MusicKit instead of MediaPlayer
    func fetchListeningHistory() async {
        guard authorizationStatus == .authorized else {
            logger.debug("Cannot fetch listening history - MusicKit not authorized")
            await MainActor.run {
                self.errorMessage = "Please grant access to Apple Music in Settings."
            }
            return
        }
        
        do {
            logger.debug("Fetching music history from MusicKit")
            
            // We'll use a combination of:
            // 1. Recently played songs from MusicKit
            // 2. Heavy rotation tracks from MusicKit
            // to simulate the play count/history that was previously available from MPMediaLibrary
            
            // Get recently played songs
            var recentlyPlayedRequest = MusicRecentlyPlayedRequest<MusicKit.Song>()
            recentlyPlayedRequest.limit = 50 // Get more items to have a better history sample
            let recentlyPlayedResponse = try await recentlyPlayedRequest.response()
            
            // Get heavy rotation items
            var heavyRotationRequest = MusicPersonalRecommendationsRequest()
            heavyRotationRequest.limit = 50
            let heavyRotationResponse = try await heavyRotationRequest.response()
            
            var heavyRotationSongs: [MusicKit.Song] = []
            
            // Extract songs from heavy rotation items
            if let heavyRotation = heavyRotationResponse.recommendations.first(where: { $0.title == "Heavy Rotation" }) {
                // Use the songs/tracks from heavy rotation as they represent frequently played items
                let tracks = heavyRotation.items.compactMap { $0 as? MusicKit.Song }
                heavyRotationSongs = tracks
            }
            
            // Combine both sources and create listening history items
            var seenIds = Set<String>() // Track unique IDs
            var historyItems: [ListeningHistoryItem] = []
            
            // Process recently played songs
            for (index, song) in recentlyPlayedResponse.items.enumerated() {
                let id = song.id.description
                if !seenIds.contains(id) {
                    seenIds.insert(id)
                    
                    // Cache artwork URL if available
                    if let artwork = song.artwork {
                        self.artworkCache[id] = artwork.url(width: 300, height: 300)
                    }
                    
                    // Create history item - for recently played, we'll use index as reverse play count
                    // (more recent = higher play count)
                    let playCount = recentlyPlayedResponse.items.count - index
                    
                    historyItems.append(ListeningHistoryItem(
                        id: id,
                        title: song.title,
                        artist: song.artistName,
                        albumName: song.albumTitle ?? "",
                        artworkID: id,
                        lastPlayedDate: Date().addingTimeInterval(-Double(index) * 3600), // Approximate last played
                        playCount: playCount,
                        musicKitId: song.id
                    ))
                }
            }
            
            // Process heavy rotation songs - these would have higher play counts
            for (index, song) in heavyRotationSongs.enumerated() {
                let id = song.id.description
                if !seenIds.contains(id) {
                    seenIds.insert(id)
                    
                    // Cache artwork URL if available
                    if let artwork = song.artwork {
                        self.artworkCache[id] = artwork.url(width: 300, height: 300)
                    }
                    
                    // Heavy rotation items get higher play counts
                    let playCount = 100 - index
                    
                    historyItems.append(ListeningHistoryItem(
                        id: id,
                        title: song.title,
                        artist: song.artistName,
                        albumName: song.albumTitle ?? "",
                        artworkID: id,
                        lastPlayedDate: Date().addingTimeInterval(-Double(index) * 1800), // More recent than normal items
                        playCount: playCount,
                        musicKitId: song.id
                    ))
                }
            }
            
            // Sort by play count (highest first)
            historyItems.sort { $0.playCount > $1.playCount }
            
            // Calculate top artists and fetch their artwork
            let topArtists = Dictionary(grouping: historyItems, by: { $0.artist })
                .map { (artist: $0.key, count: $0.value.reduce(0) { $0 + $1.playCount }) }
                .sorted { $0.count > $1.count }
                .prefix(10)
                .map { $0.artist }
            
            // Fetch artwork for top artists
            var artistArtworkTasks: [String: Task<Void, Never>] = [:]
            for artist in topArtists where artworkCache[artist] == nil {
                artistArtworkTasks[artist] = Task {
                    do {
                        var request = MusicCatalogSearchRequest(term: artist, types: [MusicKit.Artist.self])
                        request.limit = 1
                        let response = try await request.response()
                        if let artistItem = response.artists.first,
                           let artwork = artistItem.artwork {
                            await MainActor.run {
                                self.artworkCache[artist] = artwork.url(width: 100, height: 100)
                            }
                        }
                    } catch {
                        logger.error("Failed to fetch artwork for \(artist): \(error.localizedDescription)")
                    }
                }
            }
            
            for task in artistArtworkTasks.values {
                await task.value
            }
            
            await MainActor.run {
                self.listeningHistory = historyItems
                logger.debug("Updated listening history with \(historyItems.count) items from MusicKit")
            }
        } catch {
            logger.error("Failed to fetch listening history: \(error.localizedDescription)")
            await MainActor.run {
                self.errorMessage = "Failed to load listening history: \(error.localizedDescription)"
            }
        }
    }
    
    func setArtworkURL(_ url: URL, for title: String, artist: String) {
        let key = "\(title)-\(artist)".lowercased()
        artworkCache[key] = url
    }
    
    func getArtworkURL(for id: String) -> URL? {
        return artworkCache[id]
    }
    
    func convertToSong(_ item: MusicItem) -> Song {
        return Song(
            id: UUID(),
            title: item.title,
            artist: item.artist,
            albumArt: item.albumName,
            sentiment: .fine,
            artworkURL: artworkCache[item.artworkID]
        )
    }
    
    func convertToAlbum(_ item: MusicItem) -> Album {
        return Album(
            title: item.title,
            artist: item.artist,
            albumArt: item.id,
            artworkURL: artworkCache[item.artworkID]
        )
    }
    
    func getArtworkImage(for item: ListeningHistoryItem) -> UIImage? {
        // First check if we have a cached artwork URL
        if let url = artworkCache[item.artworkID],
           let imageData = try? Data(contentsOf: url),
           let image = UIImage(data: imageData) {
            return image
        }
        
        // If we have a MusicKit ID, try to fetch artwork from there
        if let musicKitId = item.musicKitId {
            // We can't directly fetch images synchronously from MusicKit,
            // so we'll return nil and rely on RemoteArtworkView to display it
            return nil
        }
        
        return nil
    }
    
    func getArtworkImage(for title: String, artist: String) -> UIImage? {
        // First check if we have the image URL cached
        let cacheKey = "\(title)-\(artist)".lowercased()
        if let url = artworkCache[cacheKey],
           let imageData = try? Data(contentsOf: url),
           let image = UIImage(data: imageData) {
            return image
        }
        
        // We can't synchronously fetch from MusicKit, but we can kick off an asynchronous task
        // to cache it for future calls. The caller will have to handle the nil return for now.
        Task {
            do {
                var request = MusicCatalogSearchRequest(term: "\(title) \(artist)", types: [MusicKit.Song.self])
                request.limit = 1
                let response = try await request.response()
                
                if let song = response.songs.first, let artwork = song.artwork {
                    let url = artwork.url(width: 300, height: 300)
                    await MainActor.run {
                        self.artworkCache[cacheKey] = url
                    }
                }
            } catch {
                logger.error("Failed to fetch artwork for \(title) by \(artist): \(error.localizedDescription)")
            }
        }
        
        return nil
    }

    // For testing purposes - set a sample song if nothing is playing
    func setDemoCurrentSong() {
        if currentPlayingSong == nil {
            // Find a song from listening history or recent songs to use as demo
            if let firstHistorySong = listeningHistory.first {
                let demoSong = Song(
                    id: UUID(),
                    title: firstHistorySong.title,
                    artist: firstHistorySong.artist,
                    albumArt: firstHistorySong.albumName,
                    sentiment: .fine,
                    score: 0.0
                )
                currentPlayingSong = demoSong
            } else {
                // Create a fallback demo song
                let demoSong = Song(
                    id: UUID(),
                    title: "Demo Song",
                    artist: "Demo Artist",
                    albumArt: "Demo Album",
                    sentiment: .fine,
                    score: 0.0
                )
                currentPlayingSong = demoSong
            }
        }
    }
}

extension URL {
    func apply(_ block: (Self, inout Self) throws -> Void) rethrows -> Self {
        var copy = self
        try block(self, &copy)
        return copy
    }
}
