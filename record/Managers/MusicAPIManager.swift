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
                request.limit = 25 // Now mutable with 'var'
                
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
            var albums: [String: MusicItem] = [:] // Use dictionary to avoid duplicates
            var artists: [String: MusicItem] = [:]
            
            for song in response.items {
                let id = song.id.description
                if let artwork = song.artwork {
                    self.artworkCache[id] = artwork.url(width: 300, height: 300)
                }
                
                // Add song
                let songItem = MusicItem(
                    id: id,
                    title: song.title,
                    artist: song.artistName,
                    albumName: song.albumTitle ?? "",
                    artworkID: id,
                    type: .song
                )
                songs.append(songItem)
                
                // Derive album (use album title and artist as a unique key)
                if let albumTitle = song.albumTitle, !albumTitle.isEmpty {
                    let albumKey = "\(albumTitle.lowercased())-\(song.artistName.lowercased())"
                    if albums[albumKey] == nil {
                        let albumItem = MusicItem(
                            id: UUID().uuidString, // No native ID, so generate one
                            title: albumTitle,
                            artist: song.artistName,
                            albumName: albumTitle,
                            artworkID: id, // Use song artwork
                            type: .album
                        )
                        albums[albumKey] = albumItem
                    }
                }
                
                // Derive artist
                let artistKey = song.artistName.lowercased()
                if artists[artistKey] == nil {
                    let artistItem = MusicItem(
                        id: UUID().uuidString, // No native ID
                        title: song.artistName,
                        artist: song.artistName,
                        albumName: "",
                        artworkID: id, // Use song artwork
                        type: .artist
                    )
                    artists[artistKey] = artistItem
                }
            }
            
            await MainActor.run {
                self.recentSongs = songs
                self.recentAlbums = Array(albums.values.prefix(limit)) // Limit to requested number
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
    
    // Remove standalone fetchRecentAlbums and fetchRecentArtists since they're derived from songs
    // If you need true recent albums/artists in the future, we'd need a different MusicKit approach
    
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
}

struct MusicItem: Identifiable {
    let id: String
    let title: String
    let artist: String
    let albumName: String
    let artworkID: String
    let type: MusicItemType
    
    enum MusicItemType {
        case song
        case album
        case artist
    }
}
