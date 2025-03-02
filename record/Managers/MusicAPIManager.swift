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

@MainActor
class MusicAPIManager: ObservableObject {
    @Published var searchResults: [MusicItem] = []
    @Published var isSearching = false
    @Published var errorMessage: String?
    @Published var authorizationStatus: MusicAuthorization.Status = .notDetermined
    
    private var artworkCache: [String: URL] = [:]
    private var searchRequestTask: Task<Void, Never>?
    
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
    
    private func performSearch<T>(
        type: T.Type,
        query: String,
        transform: @escaping (T) async throws -> MusicItem
    ) async where T: MusicCatalogSearchable {
        do {
            var request = MusicCatalogSearchRequest(term: query, types: [type])
            request.limit = 25
            
            let response = try await request.response()
            var musicItems: [MusicItem] = []
            
            switch type {
            case is MusicKit.Song.Type:
                for song in response.songs {
                    if Task.isCancelled { return }
                    if let transformed = try? await transform(song as! T) {
                        musicItems.append(transformed)
                    }
                }
            case is MusicKit.Album.Type:
                for album in response.albums {
                    if Task.isCancelled { return }
                    if let transformed = try? await transform(album as! T) {
                        musicItems.append(transformed)
                    }
                }
            case is MusicKit.Artist.Type:
                for artist in response.artists {
                    if Task.isCancelled { return }
                    if let transformed = try? await transform(artist as! T) {
                        musicItems.append(transformed)
                    }
                }
            default:
                break
            }
            
            if !Task.isCancelled {
                self.searchResults = musicItems
            }
        } catch {
            if !Task.isCancelled {
                self.errorMessage = "Search failed: \(error.localizedDescription)"
            }
        }
        
        if !Task.isCancelled {
            self.isSearching = false
        }
    }
    
    func searchMusic(query: String) async {
        guard !query.isEmpty else {
            self.searchResults = []
            return
        }
        
        searchRequestTask?.cancel()
        self.isSearching = true
        self.errorMessage = nil
        
        searchRequestTask = Task {
            await performSearch(type: MusicKit.Song.self, query: query) { song in
                let song = song as! MusicKit.Song
                let id = song.id.description
                
                // Get the artwork URL if available
                if let artwork = try? await song.artwork {
                    self.artworkCache[id] = artwork.url(width: 300, height: 300)
                }
                
                return MusicItem(
                    id: id,
                    title: song.title,
                    artist: song.artistName,
                    albumName: song.albumTitle ?? "",
                    artworkID: id,
                    type: .song
                )
            }
        }
        
        await searchRequestTask?.value
    }
    
    func searchAlbums(query: String) async {
        guard !query.isEmpty else {
            self.searchResults = []
            return
        }
        
        searchRequestTask?.cancel()
        self.isSearching = true
        self.errorMessage = nil
        
        searchRequestTask = Task {
            await performSearch(type: MusicKit.Album.self, query: query) { album in
                let album = album as! MusicKit.Album
                let id = album.id.description
                
                // Get the artwork URL if available
                if let artwork = try? await album.artwork {
                    self.artworkCache[id] = artwork.url(width: 300, height: 300)
                }
                
                return MusicItem(
                    id: id,
                    title: album.title,
                    artist: album.artistName,
                    albumName: album.title,
                    artworkID: id,
                    type: .album
                )
            }
        }
        
        await searchRequestTask?.value
    }
    
    func searchArtists(query: String) async {
        guard !query.isEmpty else {
            self.searchResults = []
            return
        }
        
        searchRequestTask?.cancel()
        self.isSearching = true
        self.errorMessage = nil
        
        searchRequestTask = Task {
            await performSearch(type: MusicKit.Artist.self, query: query) { artist in
                let artist = artist as! MusicKit.Artist
                let id = artist.id.description
                
                // Try to get artwork from artist's top album
                if self.artworkCache[id] == nil {
                    var albumRequest = MusicCatalogSearchRequest(term: artist.name, types: [MusicKit.Album.self])
                    albumRequest.limit = 1
                    if let albumResponse = try? await albumRequest.response(),
                       let album = albumResponse.albums.first,
                       let artwork = try? await album.artwork {
                        self.artworkCache[id] = artwork.url(width: 300, height: 300)
                    }
                }
                
                return MusicItem(
                    id: id,
                    title: artist.name,
                    artist: artist.name,
                    albumName: "",
                    artworkID: id,
                    type: .artist
                )
            }
        }
        
        await searchRequestTask?.value
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
