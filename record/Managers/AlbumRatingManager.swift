//
//  AlbumRatingManager.swift - Updated
//

import Foundation
import SwiftUI
import Combine

class AlbumRatingManager: ObservableObject {
    @Published var albumRatings: [AlbumRating] = []
    @Published var currentAlbum: Album? = nil
    @Published var showRatingView: Bool = false
    
    // Track subscriptions for cleanup
    private var cancellables = Set<AnyCancellable>()
    
    init() {
        // Load saved album ratings from PersistenceManager
        loadSavedRatings()
        
        // Subscribe to data change notifications
        PersistenceManager.shared.dataChangePublisher
            .receive(on: RunLoop.main)
            .sink { [weak self] _ in
                self?.loadSavedRatings()
            }
            .store(in: &cancellables)
    }
    
    // Load saved ratings from persistence
    private func loadSavedRatings() {
        self.albumRatings = PersistenceManager.shared.loadAlbumRatings()
    }
    
    // Start rating process for an album
    func rateAlbum(_ album: Album) {
        currentAlbum = album
        showRatingView = true
    }
    
    // Cancel the rating process
    func cancelRating() {
        currentAlbum = nil
        showRatingView = false
    }
    
    // Get rating for a specific album
    func getRating(forAlbumId albumId: String) -> AlbumRating? {
        return albumRatings.first(where: { $0.albumId == albumId })
    }
    
    // Add or update an album rating
    func saveRating(_ rating: AlbumRating) {
        // Validate rating is in 0.5 increments and between 0.5 and 5.0
        let validRating = max(0.0, min(5.0, round(rating.rating * 2) / 2))
        
        var updatedRating = rating
        updatedRating.rating = validRating
        
        // Save to persistence
        PersistenceManager.shared.saveAlbumRating(updatedRating)
        
        // Update local state (will be refreshed by the publisher)
    }
    
    // Delete a rating
    func deleteRating(_ rating: AlbumRating) {
        PersistenceManager.shared.deleteAlbumRating(withId: rating.id)
    }
    
    // Clear rating for an album
    func clearRating(forAlbumId albumId: String) {
        if let rating = getRating(forAlbumId: albumId) {
            deleteRating(rating)
        }
    }
    
    // Get all albums sorted by rating (highest first)
    func getAlbumsSortedByRating() -> [AlbumRating] {
        return albumRatings.sorted(by: { $0.rating > $1.rating })
    }
}
