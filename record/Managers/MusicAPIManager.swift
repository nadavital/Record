//
//  MusicAPIManager.swift
//  record
//
//  Created by Nadav Avital on 2/24/25.
//

import Foundation
import MusicKit
import SwiftUI

class MusicAPIManager: ObservableObject {
    @Published var searchResults: [MusicItem] = []
    @Published var isSearching = false
    @Published var errorMessage: String?
    
    // Store fetched artwork URLs
    private var artworkCache: [String: URL] = [:]
    
    // Basic catalog search doesn't require user authorization
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
        
        do {
            // Create a catalog search request for songs
            var request = MusicCatalogSearchRequest(term: query, types: [MusicKit.Song.self])
            request.limit = 25
            
            // This API call doesn't require user authorization
            let response = try await request.response()
            
            // Process search results
            var musicItems: [MusicItem] = []
            
            for song in response.songs {
                // Safely get artwork URL
                if let artwork = song.artwork {
                    // Use a fixed size for artwork to avoid NaN issues
                    let artworkURL = artwork.url(width: 300, height: 300)
                    self.artworkCache[song.id.rawValue] = artworkURL
                }
                
                let item = MusicItem(
                    id: song.id.rawValue,
                    title: song.title,
                    artist: song.artistName ?? "Unknown Artist",
                    albumName: song.albumTitle ?? "",
                    artworkID: song.id.rawValue,
                    type: .song
                )
                musicItems.append(item)
            }
            
            DispatchQueue.main.async {
                self.searchResults = musicItems
                self.isSearching = false
            }
        } catch {
            DispatchQueue.main.async {
                self.searchResults = []
                self.isSearching = false
                self.errorMessage = "Search failed: \(error.localizedDescription)"
                print("Search error: \(error)")
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
        
        do {
            // Create a catalog search request for albums
            var request = MusicCatalogSearchRequest(term: query, types: [MusicKit.Album.self])
            request.limit = 25
            
            // This API call doesn't require user authorization
            let response = try await request.response()
            
            // Process search results
            var musicItems: [MusicItem] = []
            
            for album in response.albums {
                // Safely get artwork URL
                if let artwork = album.artwork {
                    // Use a fixed size for artwork to avoid NaN issues
                    let artworkURL = artwork.url(width: 300, height: 300)
                    self.artworkCache[album.id.rawValue] = artworkURL
                }
                
                let item = MusicItem(
                    id: album.id.rawValue,
                    title: album.title,
                    artist: album.artistName ?? "Unknown Artist",
                    albumName: album.title,
                    artworkID: album.id.rawValue,
                    type: .album
                )
                musicItems.append(item)
            }
            
            DispatchQueue.main.async {
                self.searchResults = musicItems
                self.isSearching = false
            }
        } catch {
            DispatchQueue.main.async {
                self.searchResults = []
                self.isSearching = false
                self.errorMessage = "Search failed: \(error.localizedDescription)"
                print("Search error: \(error)")
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
