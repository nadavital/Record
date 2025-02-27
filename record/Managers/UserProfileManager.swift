//
//  UserProfileManager.swift
//  record
//
//  Created by Nadav Avital on 2/24/25.
//

import SwiftUI
import Combine

class UserProfileManager: ObservableObject {
    @Published var username: String = "VinylLover"
    @Published var bio: String = "Music enthusiast with eclectic taste."
    @Published var profileImage: String = "profile_image"
    @Published var accentColor: Color = Color(red: 0.94, green: 0.3, blue: 0.9)
    @Published var pinnedSongs: [Song] = []
    @Published var pinnedAlbums: [Album] = []
    
    // Track subscriptions for cleanup
    private var cancellables = Set<AnyCancellable>()
    
    struct Album: Identifiable, Codable {
        let id: UUID
        let title: String
        let artist: String
        let albumArt: String
        var artworkURL: URL?
        
        init(id: UUID = UUID(), title: String, artist: String, albumArt: String, artworkURL: URL? = nil) {
            self.id = id
            self.title = title
            self.artist = artist
            self.albumArt = albumArt
            self.artworkURL = artworkURL
        }
        
        // Custom coding for handling URL optionals
        enum CodingKeys: String, CodingKey {
            case id, title, artist, albumArt
            case artworkURLString
        }
        
        init(from decoder: Decoder) throws {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            
            id = try container.decode(UUID.self, forKey: .id)
            title = try container.decode(String.self, forKey: .title)
            artist = try container.decode(String.self, forKey: .artist)
            albumArt = try container.decode(String.self, forKey: .albumArt)
            
            // Handle URL conversion
            if let urlString = try container.decodeIfPresent(String.self, forKey: .artworkURLString) {
                artworkURL = URL(string: urlString)
            } else {
                artworkURL = nil
            }
        }
        
        func encode(to encoder: Encoder) throws {
            var container = encoder.container(keyedBy: CodingKeys.self)
            
            try container.encode(id, forKey: .id)
            try container.encode(title, forKey: .title)
            try container.encode(artist, forKey: .artist)
            try container.encode(albumArt, forKey: .albumArt)
            
            // Handle URL conversion
            if let url = artworkURL {
                try container.encode(url.absoluteString, forKey: .artworkURLString)
            }
        }
    }
    
    init() {
        // Load saved data from PersistenceManager
        loadSavedData()
        
        // Subscribe to data change notifications
        PersistenceManager.shared.dataChangePublisher
            .receive(on: RunLoop.main)
            .sink { [weak self] _ in
                self?.loadSavedData()
            }
            .store(in: &cancellables)
    }
    
    // Load saved data from persistence
    private func loadSavedData() {
        // Load profile data
        if let profile = PersistenceManager.shared.loadUserProfile() {
            self.username = profile.username
            self.bio = profile.bio
            self.profileImage = profile.profileImage
            self.accentColor = profile.accentColor
        }
        
        // Load pinned songs
        self.pinnedSongs = PersistenceManager.shared.loadPinnedSongs()
        
        // Load pinned albums
        self.pinnedAlbums = PersistenceManager.shared.loadPinnedAlbums()
        
        // If no data exists, use sample data
        if pinnedSongs.isEmpty {
            pinnedSongs = [
                Song(title: "Blinding Lights", artist: "The Weeknd", albumArt: "blinding_lights", sentiment: .love),
                Song(title: "Levitating", artist: "Dua Lipa", albumArt: "levitating", sentiment: .love)
            ]
            savePinnedSongs()
        }
        
        if pinnedAlbums.isEmpty {
            pinnedAlbums = [
                Album(title: "Future Nostalgia", artist: "Dua Lipa", albumArt: "future_nostalgia"),
                Album(title: "After Hours", artist: "The Weeknd", albumArt: "after_hours")
            ]
            savePinnedAlbums()
        }
    }
    
    // Save profile data when it changes
    func saveUserProfile() {
        PersistenceManager.shared.saveUserProfile(
            username: username, 
            bio: bio,
            profileImage: profileImage, 
            accentColor: accentColor
        )
    }
    
    // Save pinned songs
    func savePinnedSongs() {
        PersistenceManager.shared.savePinnedSongs(pinnedSongs)
    }
    
    // Save pinned albums
    func savePinnedAlbums() {
        PersistenceManager.shared.savePinnedAlbums(pinnedAlbums)
    }
    
    // Add a song to pinned songs
    func addPinnedSong(_ song: Song) {
        // Check if we already have this song
        if !pinnedSongs.contains(where: { $0.id == song.id }) {
            pinnedSongs.append(song)
            savePinnedSongs()
        }
    }
    
    // Add an album to pinned albums
    func addPinnedAlbum(_ album: Album) {
        // Check if we already have this album
        if !pinnedAlbums.contains(where: { $0.id == album.id }) {
            pinnedAlbums.append(album)
            savePinnedAlbums()
        }
    }
    
    // Remove a song from pinned songs
    func removePinnedSong(_ song: Song) {
        if let index = pinnedSongs.firstIndex(where: { $0.id == song.id }) {
            pinnedSongs.remove(at: index)
            savePinnedSongs()
        }
    }
    
    // Remove an album from pinned albums
    func removePinnedAlbum(_ album: Album) {
        if let index = pinnedAlbums.firstIndex(where: { $0.id == album.id }) {
            pinnedAlbums.remove(at: index)
            savePinnedAlbums()
        }
    }
}
