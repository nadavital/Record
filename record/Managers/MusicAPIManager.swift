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
    
    private var artworkCache: [String: URL] = [:]
    private var activeTask: Task<Void, Never>?
    
    private let logger = Logger(subsystem: "com.Nadav.record", category: "MusicAPIManager")
    
    init() {
        Task {
            await checkMusicAuthorizationStatus()
        }
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
        // Cancel any active search
        activeTask?.cancel()
        
        // Handle empty query
        if query.isEmpty {
            self.searchResults = []
            self.isSearching = false
            self.errorMessage = nil
            return
        }
        
        // Set searching state
        self.isSearching = true
        self.errorMessage = nil
        
        // Create and store the task
        let task = Task {
            do {
                logger.debug("Searching for '\(query)' with type \(String(describing: type))")
                
                // Create search request
                var request = MusicCatalogSearchRequest(term: query, types: [type])
                request.limit = 25
                
                // Get response
                let response = try await request.response()
                
                // Check if cancelled
                if Task.isCancelled {
                    logger.debug("Search cancelled after response")
                    return
                }
                
                // Process results
                var items: [MusicItem] = []
                
                if type == MusicKit.Song.self {
                    for song in response.songs {
                        if Task.isCancelled { return }
                        
                        let id = song.id.description
                        
                        // Get artwork
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
                        
                        // Get artwork
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
                        
                        // Try to get artwork from artist's top album
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
                
                // Only update state if not cancelled
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
        
        // Store the task
        activeTask = task
        
        // Wait for task to complete
        await task.value
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
}

// Model for search results
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
