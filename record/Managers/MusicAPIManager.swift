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
    
    // For catalog searches, we don't need to check authorization status
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
            // Use catalog search - this doesn't require personal account access
            var request = MusicCatalogSearchRequest(term: query, types: [MusicKit.Song.self])
            request.limit = 25
            
            let response = try await request.response()
            
            // Process search results
            var musicItems: [MusicItem] = []
            
            for song in response.songs {
                // Cache the artwork URL
                if let artworkURL = song.artwork?.url(width: 300, height: 300) {
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
            // Use catalog search - this doesn't require personal account access
            var request = MusicCatalogSearchRequest(term: query, types: [MusicKit.Album.self])
            request.limit = 25
            
            let response = try await request.response()
            
            // Process search results
            var musicItems: [MusicItem] = []
            
            for album in response.albums {
                // Cache the artwork URL
                if let artworkURL = album.artwork?.url(width: 300, height: 300) {
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
