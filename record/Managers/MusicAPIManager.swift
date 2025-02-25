//
//  MusicAPIManager.swift
//  record
//
//  Created by Nadav Avital on 2/24/25.
//

import Foundation
import MusicKit
import SwiftUI
import os.log

class MusicAPIManager: ObservableObject {
    @Published var searchResults: [MusicItem] = []
    @Published var isSearching = false
    @Published var errorMessage: String?
    @Published var authorizationStatus: MusicAuthorization.Status = .notDetermined
    
    // Store fetched artwork URLs
    private var artworkCache: [String: URL] = [:]
    
    init() {
        // Check current authorization status on init
        Task {
            await checkMusicAuthorizationStatus()
        }
    }
    
    @MainActor
    func checkMusicAuthorizationStatus() async {
        // For catalog searches, we only need developer token authorization
        // No need for full user authorization
        self.authorizationStatus = MusicAuthorization.currentStatus
        
        if self.authorizationStatus != .authorized {
            // Request authorization for catalog access only (no personal data)
            self.authorizationStatus = await MusicAuthorization.request()
            print("Music authorization status: \(self.authorizationStatus)")
        }
    }
    
    // Basic catalog search doesn't require user library authorization
    func searchMusic(query: String) async {
        guard !query.isEmpty else {
            DispatchQueue.main.async {
                self.searchResults = []
                self.isSearching = false
            }
            return
        }
        
        DispatchQueue.main.async {
            self.isSearching = true
            self.errorMessage = nil
        }
        
        // Make sure we have checked authorization
        await checkMusicAuthorizationStatus()
        
        do {
            print("Starting music search for query: \(query)")
            
            // Create a catalog search request for songs
            var request = MusicCatalogSearchRequest(term: query, types: [MusicKit.Song.self])
            request.limit = 25
            
            print("Sending MusicKit search request...")
            
            // This API call uses the developer token for catalog access
            let response = try await request.response()
            
            print("Received response with \(response.songs.count) songs")
            
            // Process search results
            var musicItems: [MusicItem] = []
            
            for (index, song) in response.songs.enumerated() {
                print("Processing song \(index+1): \(song.title) by \(song.artistName ?? "Unknown")")
                
                // Safely get artwork URL
                var artworkURL: URL? = nil
                if let artwork = song.artwork {
                    // Use a fixed size for artwork to avoid NaN issues
                    artworkURL = artwork.url(width: 300, height: 300)
                    let id = song.id.rawValue
                    self.artworkCache[id] = artworkURL
                    print("  - Artwork URL cached for ID: \(id)")
                } else {
                    print("  - No artwork available")
                }
                
                let id = song.id.rawValue
                let item = MusicItem(
                    id: id,
                    title: song.title,
                    artist: song.artistName ?? "Unknown Artist",
                    albumName: song.albumTitle ?? "",
                    artworkID: id,
                    type: .song
                )
                musicItems.append(item)
                print("  - Added song to results list")
            }
            
            DispatchQueue.main.async {
                print("Search completed successfully with \(musicItems.count) results")
                self.searchResults = musicItems
                self.isSearching = false
            }
        } catch {
            print("------------- SEARCH ERROR -------------")
            print("Error type: \(type(of: error))")
            print("Error description: \(error.localizedDescription)")
            print("Detailed error: \(error)")
            
            if let decodingError = error as? DecodingError {
                print("Decoding error context: \(decodingError)")
                switch decodingError {
                case .dataCorrupted(let context):
                    print("Data corrupted at path: \(context.codingPath)")
                    print("Debug description: \(context.debugDescription)")
                    if let underlyingError = context.underlyingError {
                        print("Underlying error: \(underlyingError)")
                    }
                case .keyNotFound(let key, let context):
                    print("Key not found: \(key) at path: \(context.codingPath)")
                case .valueNotFound(let type, let context):
                    print("Value not found for type: \(type) at path: \(context.codingPath)")
                case .typeMismatch(let type, let context):
                    print("Type mismatch for type: \(type) at path: \(context.codingPath)")
                @unknown default:
                    print("Unknown decoding error")
                }
            }
            
            print("---------------------------------------")
            
            DispatchQueue.main.async {
                self.searchResults = []
                self.isSearching = false
                self.errorMessage = "Search failed: \(error.localizedDescription)"
            }
        }
    }
    
    // Catalog search for albums
    func searchAlbums(query: String) async {
        guard !query.isEmpty else {
            DispatchQueue.main.async {
                self.searchResults = []
                self.isSearching = false
            }
            return
        }
        
        DispatchQueue.main.async {
            self.isSearching = true
            self.errorMessage = nil
        }
        
        // Make sure we have checked authorization
        await checkMusicAuthorizationStatus()
        
        do {
            print("Starting album search for query: \(query)")
            
            // Create a catalog search request for albums
            var request = MusicCatalogSearchRequest(term: query, types: [MusicKit.Album.self])
            request.limit = 25
            
            print("Sending MusicKit album search request...")
            
            // This API call uses the developer token for catalog access
            let response = try await request.response()
            
            print("Received album response with \(response.albums.count) albums")
            
            // Process search results
            var musicItems: [MusicItem] = []
            
            for (index, album) in response.albums.enumerated() {
                print("Processing album \(index+1): \(album.title) by \(album.artistName ?? "Unknown")")
                
                // Safely get artwork URL
                var artworkURL: URL? = nil
                if let artwork = album.artwork {
                    // Use a fixed size for artwork to avoid NaN issues
                    artworkURL = artwork.url(width: 300, height: 300)
                    let id = album.id.rawValue
                    self.artworkCache[id] = artworkURL
                    print("  - Album artwork URL cached for ID: \(id)")
                } else {
                    print("  - No album artwork available")
                }
                
                let id = album.id.rawValue
                let item = MusicItem(
                    id: id,
                    title: album.title,
                    artist: album.artistName ?? "Unknown Artist",
                    albumName: album.title,
                    artworkID: id,
                    type: .album
                )
                musicItems.append(item)
                print("  - Added album to results list")
            }
            
            DispatchQueue.main.async {
                print("Album search completed successfully with \(musicItems.count) results")
                self.searchResults = musicItems
                self.isSearching = false
            }
        } catch {
            print("------------- ALBUM SEARCH ERROR -------------")
            print("Error type: \(type(of: error))")
            print("Error description: \(error.localizedDescription)")
            print("Detailed error: \(error)")
            
            if let decodingError = error as? DecodingError {
                print("Decoding error context: \(decodingError)")
                switch decodingError {
                case .dataCorrupted(let context):
                    print("Data corrupted at path: \(context.codingPath)")
                    print("Debug description: \(context.debugDescription)")
                    if let underlyingError = context.underlyingError {
                        print("Underlying error: \(underlyingError)")
                    }
                case .keyNotFound(let key, let context):
                    print("Key not found: \(key) at path: \(context.codingPath)")
                case .valueNotFound(let type, let context):
                    print("Value not found for type: \(type) at path: \(context.codingPath)")
                case .typeMismatch(let type, let context):
                    print("Type mismatch for type: \(type) at path: \(context.codingPath)")
                @unknown default:
                    print("Unknown decoding error")
                }
            }
            
            print("---------------------------------------")
            
            DispatchQueue.main.async {
                self.searchResults = []
                self.isSearching = false
                self.errorMessage = "Search failed: \(error.localizedDescription)"
            }
        }
    }
    
    func getArtworkURL(for id: String) -> URL? {
        return artworkCache[id]
    }
    
    // Convert MusicItem to Song model
    func convertToSong(_ item: MusicItem) -> Song {
        return Song(
            id: UUID(),
            title: item.title,
            artist: item.artist,
            albumArt: item.id,
            sentiment: .neutral,
            artworkURL: artworkCache[item.artworkID]
        )
    }
    
    // Convert MusicItem to Album model
    func convertToAlbum(_ item: MusicItem) -> UserProfileManager.Album {
        return UserProfileManager.Album(
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
    }
}
