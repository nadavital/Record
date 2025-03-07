import Foundation
import MusicKit
import SwiftUI
import MediaPlayer
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
    @Published var currentPlayingSong: Song? = nil
    
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
        let mediaAuthStatus = MPMediaLibrary.authorizationStatus()
        if mediaAuthStatus != .authorized {
            MPMediaLibrary.requestAuthorization { status in
                Task { await self.checkMusicAuthorizationStatus() }
            }
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
    
    // Simplified to fetch all-time stats only
    func fetchListeningHistory() async {
        guard MPMediaLibrary.authorizationStatus() == .authorized else {
            logger.debug("Cannot fetch listening history - MPMediaLibrary not authorized")
            await MainActor.run {
                self.errorMessage = "Please grant access to your music library in Settings."
            }
            return
        }
        
        do {
            logger.debug("Fetching all-time listening history")
            
            let query = MPMediaQuery.songs()
            guard let items = query.items else {
                logger.debug("No items found in media library")
                return
            }
            
            let historyItems = items
                .filter { $0.playCount > 0 }
                .map { item in
                    ListeningHistoryItem(
                        id: item.persistentID.description,
                        title: item.title ?? "Unknown",
                        artist: item.artist ?? "Unknown",
                        albumName: item.albumTitle ?? "",
                        artworkID: item.persistentID.description,
                        lastPlayedDate: item.lastPlayedDate,
                        playCount: item.playCount,
                        mediaItem: item // Store the MPMediaItem
                    )
                }
                .sorted { ($0.lastPlayedDate ?? Date.distantPast) > ($1.lastPlayedDate ?? Date.distantPast) }
            
            // Calculate top artists first (unchanged)...
            let topArtists = Dictionary(grouping: historyItems, by: { $0.artist })
                .map { (artist: $0.key, count: $0.value.reduce(0) { $0 + $1.playCount }) }
                .sorted { $0.count > $1.count }
                .prefix(10)
                .map { $0.artist }
            
            // Fetch artwork for top artists (unchanged)...
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
                logger.debug("Updated listening history with \(historyItems.count) items")
            }
        }
    }
    
    func getArtworkURL(for id: String) -> URL? {
        return artworkCache[id]
    }
    
    func convertToSong(_ item: MusicItem) -> Song {
        return Song(
            id: UUID(),
            title: item.title,
            artist: item.artist,
            albumArt: item.id,
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
        let query = MPMediaQuery.songs()
        let predicate = MPMediaPropertyPredicate(
            value: item.id,
            forProperty: MPMediaItemPropertyPersistentID
        )
        query.addFilterPredicate(predicate)
        if let mediaItem = query.items?.first,
           let artwork = mediaItem.artwork {
            return artwork.image(at: CGSize(width: 100, height: 100))
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
        
        // Try finding it in the media library
        let query = MPMediaQuery.songs()
        let titlePredicate = MPMediaPropertyPredicate(
            value: title,
            forProperty: MPMediaItemPropertyTitle,
            comparisonType: .contains
        )
        let artistPredicate = MPMediaPropertyPredicate(
            value: artist,
            forProperty: MPMediaItemPropertyArtist,
            comparisonType: .contains
        )
        query.addFilterPredicate(titlePredicate)
        query.addFilterPredicate(artistPredicate)
        
        if let mediaItem = query.items?.first,
           let artwork = mediaItem.artwork {
            return artwork.image(at: CGSize(width: 100, height: 100))
        }
        
        return nil
    }
    
    func setupNowPlayingMonitoring() {
        // Set up notification observer for music player changes
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleMusicPlayerNotification),
            name: .MPMusicPlayerControllerNowPlayingItemDidChange,
            object: MPMusicPlayerController.systemMusicPlayer
        )
        
        MPMusicPlayerController.systemMusicPlayer.beginGeneratingPlaybackNotifications()
        
        // Initial check for currently playing song
        updateCurrentPlayingSong()
    }

    @objc private func handleMusicPlayerNotification() {
        updateCurrentPlayingSong()
    }

    func updateCurrentPlayingSong() {
        guard let mediaItem = MPMusicPlayerController.systemMusicPlayer.nowPlayingItem else {
            // No song is currently playing
            currentPlayingSong = nil
            return
        }
        
        // Create Song object from MPMediaItem
        let title = mediaItem.title ?? "Unknown Title"
        let artist = mediaItem.artist ?? "Unknown Artist"
        var artworkURL: URL? = nil
        
        // Try to get artwork
        if let artwork = mediaItem.artwork {
            let image = artwork.image(at: CGSize(width: 300, height: 300))
            
            // Save artwork to temporary directory and create URL
            if let image = image, let data = image.jpegData(compressionQuality: 0.8) {
                let fileManager = FileManager.default
                let tempURL = fileManager.temporaryDirectory.appendingPathComponent("\(mediaItem.persistentID).jpg")
                try? data.write(to: tempURL)
                artworkURL = tempURL
            }
        }
        
        // Create song object
        let song = Song(
            id: UUID(),
            title: title,
            artist: artist,
            albumArt: mediaItem.albumTitle ?? "",
            sentiment: .fine,
            artworkURL: artworkURL,
            score: 0.0
        )
        
        // Check if song is already ranked
        if let rankingInfo = checkIfSongIsRanked(title: title, artist: artist),
           rankingInfo.isRanked,
           let index = rankingManager?.rankedSongs.firstIndex(where: {
               $0.title.lowercased() == title.lowercased() &&
               $0.artist.lowercased() == artist.lowercased()
           }) {
            // Update with ranked info
            let rankedSong = rankingManager!.rankedSongs[index]
            currentPlayingSong = rankedSong
        } else {
            currentPlayingSong = song
        }
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



