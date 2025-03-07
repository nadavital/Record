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
    @Published var pinnedAlbums: [Album] = []
    @Published var pinnedArtists: [Artist] = []
    @Published var albumRatings: [AlbumRating] = []
    
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
        
        // Load pinned albums and artists
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
    
    // Load album ratings
    func loadAlbumRatings() {
        albumRatings = PersistenceManager.shared.loadAlbumRatings()
    }
    
    // Get a specific album rating
    func getAlbumRating(forAlbumId albumId: String) -> AlbumRating? {
        return albumRatings.first(where: { $0.albumId == albumId })
    }
    
    // Save album rating
    func saveAlbumRating(_ rating: AlbumRating) {
        var updatedRating = rating
        
        // Ensure rating is in 0.5 increments and within range
        let validRating = max(0.0, min(5.0, round(rating.rating * 2) / 2))
        updatedRating.rating = validRating
        
        PersistenceManager.shared.saveAlbumRating(updatedRating)
        
        // Update local state
        if let index = albumRatings.firstIndex(where: { $0.id == rating.id }) {
            albumRatings[index] = updatedRating
        } else {
            albumRatings.append(updatedRating)
        }
    }
    
    // Delete album rating
    func deleteAlbumRating(_ rating: AlbumRating) {
        PersistenceManager.shared.deleteAlbumRating(withId: rating.id)
        albumRatings.removeAll(where: { $0.id == rating.id })
    }
    
    // Get top rated albums
    func getTopRatedAlbums(limit: Int = 5) -> [AlbumRating] {
        return albumRatings
            .filter { $0.rating > 0 }
            .sorted(by: { $0.rating > $1.rating })
            .prefix(limit)
            .map { $0 }
    }
    
    // Get recently rated albums
    func getRecentlyRatedAlbums(limit: Int = 5) -> [AlbumRating] {
        return albumRatings
            .sorted(by: { $0.dateAdded > $1.dateAdded })
            .prefix(limit)
            .map { $0 }
    }
}
