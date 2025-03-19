import Foundation
import MediaPlayer
import SwiftUI
import os.log

@MainActor
class MediaPlayerManager: ObservableObject {
    @Published var topSongs: [MPMediaItem] = []
    @Published var topAlbums: [MPMediaItemCollection] = []
    @Published var topArtists: [MPMediaItemCollection] = []
    @Published var errorMessage: String?
    private let logger = Logger(subsystem: "com.Nadav.record", category: "MediaPlayerManager")
    
    init() {
        fetchTopSongs()
        fetchTopAlbums()
        fetchTopArtists()
    }
    
    func fetchTopSongs() {
        let query = MPMediaQuery.songs()
        query.addFilterPredicate(MPMediaPropertyPredicate(value: MPMediaType.music.rawValue, forProperty: MPMediaItemPropertyMediaType))
        query.groupingType = .title
        
        if let items = query.items?.filter({ $0.playCount > 0 }).sorted(by: { $0.playCount > $1.playCount }) {
            self.topSongs = items
            logger.info("Fetched \(items.count) songs with play counts")
        } else {
            self.errorMessage = "Failed to fetch top songs."
            logger.error("Failed to fetch top songs")
        }
    }

    func fetchTopAlbums() {
        let query = MPMediaQuery.albums()
        query.addFilterPredicate(MPMediaPropertyPredicate(value: MPMediaType.music.rawValue, forProperty: MPMediaItemPropertyMediaType))
        query.groupingType = .album
        
        if let collections = query.collections?.filter({ collection in
            // Only include albums that have at least one song with play count > 0
            return collection.items.contains(where: { $0.playCount > 0 })
        }).sorted(by: { firstCollection, secondCollection in
            // Calculate total play counts for all songs in the album
            let firstTotalPlays = firstCollection.items.reduce(0) { $0 + $1.playCount }
            let secondTotalPlays = secondCollection.items.reduce(0) { $0 + $1.playCount }
            return firstTotalPlays > secondTotalPlays
        }) {
            self.topAlbums = collections
            logger.info("Fetched \(collections.count) albums with play counts")
        } else {
            self.errorMessage = "Failed to fetch top albums."
            logger.error("Failed to fetch top albums")
        }
    }

    func fetchTopArtists() {
        let query = MPMediaQuery.artists()
        query.addFilterPredicate(MPMediaPropertyPredicate(value: MPMediaType.music.rawValue, forProperty: MPMediaItemPropertyMediaType))
        query.groupingType = .artist
        
        if let collections = query.collections?.filter({ collection in
            // Only include artists that have at least one song with play count > 0
            return collection.items.contains(where: { $0.playCount > 0 })
        }).sorted(by: { firstCollection, secondCollection in
            // Calculate total play counts for all songs by the artist
            let firstTotalPlays = firstCollection.items.reduce(0) { $0 + $1.playCount }
            let secondTotalPlays = secondCollection.items.reduce(0) { $0 + $1.playCount }
            return firstTotalPlays > secondTotalPlays
        }) {
            self.topArtists = collections
            logger.info("Fetched \(collections.count) artists with play counts")
        } else {
            self.errorMessage = "Failed to fetch top artists."
            logger.error("Failed to fetch top artists")
        }
    }
}
