//
//  UserProfileManager.swift
//  record
//
//  Created by Nadav Avital on 2/24/25.
//

import SwiftUI
import Combine

class UserProfileManager: ObservableObject {
    @Published var username: String = ""
    @Published var bio: String = ""
    @Published var profileImage: String = "profile_image"
    @Published var pinnedSongs: [Song] = []
    @Published var pinnedAlbums: [Album] = []
    @Published var pinnedArtists: [Artist] = []
    
    // Track subscriptions for cleanup
    private var cancellables = Set<AnyCancellable>()
    
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
        }
        
        // Load pinned songs, albums, and artists
        self.pinnedSongs = PersistenceManager.shared.loadPinnedSongs()
        self.pinnedAlbums = PersistenceManager.shared.loadPinnedAlbums()
        self.pinnedArtists = PersistenceManager.shared.loadPinnedArtists()
    }
    
    // Save profile data when it changes
    func saveUserProfile() {
        PersistenceManager.shared.saveUserProfile(
            username: username, 
            bio: bio,
            profileImage: profileImage
        )
    }
    
    // Save pinned albums
    func savePinnedAlbums() {
        PersistenceManager.shared.savePinnedAlbums(pinnedAlbums)
    }
    
    // Save pinned artists
    func savePinnedArtists() {
        PersistenceManager.shared.savePinnedArtists(pinnedArtists)
    }
    
    // Add a song to pinned songs
    func addPinnedSong(_ song: Song) {
        // Check if we already have this song
        if !pinnedSongs.contains(where: { $0.id == song.id }) {
            pinnedSongs.append(song)
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
    
    // Add an artist to pinned artists
    func addPinnedArtist(_ artist: Artist) {
        // Check if we already have this artist
        if !pinnedArtists.contains(where: { $0.name == artist.name }) {
            pinnedArtists.append(artist)
            savePinnedArtists()
        }
    }
    
    // Remove a song from pinned songs
    func removePinnedSong(_ song: Song) {
        if let index = pinnedSongs.firstIndex(where: { $0.id == song.id }) {
            pinnedSongs.remove(at: index)
        }
    }
    
    // Remove an album from pinned albums
    func removePinnedAlbum(_ album: Album) {
        if let index = pinnedAlbums.firstIndex(where: { $0.id == album.id }) {
            pinnedAlbums.remove(at: index)
            savePinnedAlbums()
        }
    }
    
    // Remove an artist from pinned artists
    func removePinnedArtist(_ artist: Artist) {
        if let index = pinnedArtists.firstIndex(where: { $0.id == artist.id }) {
            pinnedArtists.remove(at: index)
            savePinnedArtists()
        }
    }
}
