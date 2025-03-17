//
//  PersistenceManager.swift
//  record
//
//

import Foundation
import SwiftUI
import Combine

class PersistenceManager: ObservableObject {
    // Singleton instance
    static let shared = PersistenceManager()
    
    // UserDefaults keys
    private enum Keys {
        static let rankedSongs = "rankedSongs"
        static let pinnedAlbums = "pinnedAlbums"
        static let pinnedArtists = "pinnedArtists"
        static let userProfile = "userProfile"
        static let artworkCache = "artworkCache"
        static let lastCloudSync = "lastCloudSync"
    }
    
    // Cache for artwork URLs
    private var artworkCache: [String: String] = [:]
    
    // Create a publisher to notify when data changes
    private let dataChangeSubject = PassthroughSubject<Void, Never>()
    var dataChangePublisher: AnyPublisher<Void, Never> {
        dataChangeSubject.eraseToAnyPublisher()
    }
    
    // CloudKit sync handler
    @Published var isSyncing = false
    @Published var lastSyncDate: Date? = nil
    
    private init() {
        // Load the artwork cache on initialization
        loadArtworkCache()
        
        // Load the last sync date
        let timeInterval = UserDefaults.standard.double(forKey: Keys.lastCloudSync)
        if timeInterval > 0 {
            lastSyncDate = Date(timeIntervalSince1970: timeInterval)
        }
    }
    
    // MARK: - Save Methods
    
    func saveRankedSongs(_ songs: [Song], syncToCloud: Bool = true) {
        save(songs, forKey: Keys.rankedSongs)
        saveArtworkURLs(from: songs)
        dataChangeSubject.send()
        
        // Sync to CloudKit if needed
        if syncToCloud, let userId = AuthManager.shared.userId {
            // If there are no songs, we need to delete the CloudKit record
            if songs.isEmpty {
                CloudKitSyncManager.shared.deleteRankedSongs(userId: userId) { error in
                    if let error = error {
                        print("Failed to delete ranked songs from CloudKit: \(error.localizedDescription)")
                    } else {
                        print("Successfully deleted ranked songs from CloudKit")
                        self.updateLastSyncDate()
                    }
                }
            } else {
                CloudKitSyncManager.shared.saveRankedSongs(songs, userId: userId) { error in
                    if let error = error {
                        print("Failed to sync ranked songs to CloudKit: \(error.localizedDescription)")
                    } else {
                        print("Successfully synced ranked songs to CloudKit")
                        self.updateLastSyncDate()
                    }
                }
            }
        }
    }
    
    func savePinnedAlbums(_ albums: [Album], syncToCloud: Bool = true) {
        do {
            let encoder = JSONEncoder()
            let data = try encoder.encode(albums)
            UserDefaults.standard.set(data, forKey: Keys.pinnedAlbums)
            
            // Extract and cache artwork URLs
            for album in albums {
                if let url = album.artworkURL {
                    artworkCache[album.id.uuidString] = url.absoluteString
                }
            }
            saveArtworkCache()
            dataChangeSubject.send()
            
            // Sync to CloudKit if needed
            if syncToCloud, let userId = AuthManager.shared.userId {
                CloudKitSyncManager.shared.savePinnedAlbums(albums, userId: userId) { error in
                    if let error = error {
                        print("Failed to sync pinned albums to CloudKit: \(error.localizedDescription)")
                    } else {
                        print("Successfully synced pinned albums to CloudKit")
                        self.updateLastSyncDate()
                    }
                }
            }
        } catch {
            print("Error saving albums: \(error.localizedDescription)")
        }
    }
    
    func savePinnedArtists(_ artists: [Artist], syncToCloud: Bool = true) {
        do {
            let encoder = JSONEncoder()
            let data = try encoder.encode(artists)
            UserDefaults.standard.set(data, forKey: Keys.pinnedArtists)
            
            // Extract and cache artwork URLs
            for artist in artists {
                if let url = artist.artworkURL {
                    artworkCache[artist.id.uuidString] = url.absoluteString
                }
            }
            saveArtworkCache()
            dataChangeSubject.send()
            
            // Sync to CloudKit if needed
            if syncToCloud, let userId = AuthManager.shared.userId {
                CloudKitSyncManager.shared.savePinnedArtists(artists, userId: userId) { error in
                    if let error = error {
                        print("Failed to sync pinned artists to CloudKit: \(error.localizedDescription)")
                    } else {
                        print("Successfully synced pinned artists to CloudKit")
                        self.updateLastSyncDate()
                    }
                }
            }
        } catch {
            print("Error saving artists: \(error.localizedDescription)")
        }
    }
    
    func saveUserProfile(username: String, bio: String, profileImage: String, syncToCloud: Bool = true) {
        let profile: [String: Any] = [
            "username": username,
            "bio": bio,
            "profileImage": profileImage
        ]
        UserDefaults.standard.set(profile, forKey: Keys.userProfile)
        dataChangeSubject.send()
        
        // Sync to CloudKit if needed
        if syncToCloud, let userId = AuthManager.shared.userId {
            CloudKitSyncManager.shared.saveUserProfile(username: username, bio: bio, userId: userId) { error in
                if let error = error {
                    print("Failed to sync user profile to CloudKit: \(error.localizedDescription)")
                } else {
                    print("Successfully synced user profile to CloudKit")
                    self.updateLastSyncDate()
                }
            }
        }
    }
    
    // MARK: - Load Methods
    
    func loadRankedSongs() -> [Song] {
        return load(forKey: Keys.rankedSongs) ?? []
    }
    
    func loadPinnedAlbums() -> [Album] {
        guard let data = UserDefaults.standard.data(forKey: Keys.pinnedAlbums) else {
            return []
        }
        
        do {
            let decoder = JSONDecoder()
            let albums = try decoder.decode([Album].self, from: data)
            
            // Restore artwork URLs from cache
            var restoredAlbums = albums
            for i in 0..<restoredAlbums.count {
                let albumId = restoredAlbums[i].id.uuidString
                if let urlString = artworkCache[albumId], let url = URL(string: urlString) {
                    restoredAlbums[i].artworkURL = url
                }
            }
            
            return restoredAlbums
        } catch {
            print("Error loading albums: \(error.localizedDescription)")
            return []
        }
    }
    
    func loadPinnedArtists() -> [Artist] {
        guard let data = UserDefaults.standard.data(forKey: Keys.pinnedArtists) else {
            return []
        }
        
        do {
            let decoder = JSONDecoder()
            let artists = try decoder.decode([Artist].self, from: data)
            
            // Restore artwork URLs from cache
            var restoredArtists = artists
            for i in 0..<restoredArtists.count {
                let artistId = restoredArtists[i].id.uuidString
                if let urlString = artworkCache[artistId], let url = URL(string: urlString) {
                    restoredArtists[i].artworkURL = url
                }
            }
            
            return restoredArtists
        } catch {
            print("Error loading artists: \(error.localizedDescription)")
            return []
        }
    }
    
    func loadUserProfile() -> (username: String, bio: String, profileImage: String)? {
        guard let profile = UserDefaults.standard.dictionary(forKey: Keys.userProfile) else {
            return nil
        }
        
        return (
            username: profile["username"] as? String ?? "",
            bio: profile["bio"] as? String ?? "",
            profileImage: profile["profileImage"] as? String ?? "profile_image"
        )
    }
    
    // MARK: - Album Ratings
        
    private enum AlbumRatingKeys {
        static let albumRatings = "albumRatings"
    }
    
    func saveAlbumRatings(_ ratings: [AlbumRating], syncToCloud: Bool = true) {
        save(ratings, forKey: AlbumRatingKeys.albumRatings)
        dataChangeSubject.send()
        
        // Sync to CloudKit if needed
        if syncToCloud, let userId = AuthManager.shared.userId {
            CloudKitSyncManager.shared.saveAlbumRatings(ratings, userId: userId) { error in
                if let error = error {
                    print("Failed to sync album ratings to CloudKit: \(error.localizedDescription)")
                } else {
                    print("Successfully synced album ratings to CloudKit")
                    self.updateLastSyncDate()
                }
            }
        }
    }
    
    func loadAlbumRatings() -> [AlbumRating] {
        return load(forKey: AlbumRatingKeys.albumRatings) ?? []
    }
    
    func saveAlbumRating(_ rating: AlbumRating) {
        var ratings = loadAlbumRatings()
        
        // Update existing or add new
        if let index = ratings.firstIndex(where: { $0.id == rating.id }) {
            ratings[index] = rating
        } else {
            ratings.append(rating)
        }
        
        saveAlbumRatings(ratings)
    }
    
    func deleteAlbumRating(withId id: UUID) {
        var ratings = loadAlbumRatings()
        ratings.removeAll(where: { $0.id == id })
        
        // Make sure to save with syncToCloud enabled to ensure CloudKit stays in sync
        saveAlbumRatings(ratings, syncToCloud: true)
        
        // Notify listeners about the change
        dataChangeSubject.send()
    }
    
    func getAlbumRating(forAlbumId albumId: String) -> AlbumRating? {
        let ratings = loadAlbumRatings()
        return ratings.first(where: { $0.albumId == albumId })
    }
    
    // MARK: - CloudKit Sync
    
    func syncWithCloudKit(completion: ((Error?) -> Void)? = nil) {
        guard let userId = AuthManager.shared.userId else {
            print("Cannot sync with CloudKit - no user ID")
            completion?(NSError(domain: "PersistenceManager", code: -1, userInfo: [NSLocalizedDescriptionKey: "No user ID available for sync"]))
            return
        }
        
        DispatchQueue.main.async {
            self.isSyncing = true
        }
        
        CloudKitSyncManager.shared.syncAllData(forUserId: userId) { error in
            DispatchQueue.main.async {
                self.isSyncing = false
                
                if let error = error {
                    print("Failed to sync with CloudKit: \(error.localizedDescription)")
                    completion?(error)
                } else {
                    print("Successfully synced with CloudKit")
                    self.updateLastSyncDate()
                    self.dataChangeSubject.send()
                    completion?(nil)
                }
            }
        }
    }
    
    private func updateLastSyncDate() {
        let now = Date()
        UserDefaults.standard.set(now.timeIntervalSince1970, forKey: Keys.lastCloudSync)
        DispatchQueue.main.async {
            self.lastSyncDate = now
        }
    }
    
    // MARK: - Helper Methods
    
    private func save<T: Encodable>(_ object: T, forKey key: String) {
        do {
            let encoder = JSONEncoder()
            let data = try encoder.encode(object)
            UserDefaults.standard.set(data, forKey: key)
        } catch {
            print("Error saving object for key \(key): \(error.localizedDescription)")
        }
    }
    
    private func load<T: Decodable>(forKey key: String) -> T? {
        guard let data = UserDefaults.standard.data(forKey: key) else {
            return nil
        }
        
        do {
            let decoder = JSONDecoder()
            return try decoder.decode(T.self, from: data)
        } catch {
            print("Error loading object for key \(key): \(error.localizedDescription)")
            return nil
        }
    }
    
    // Save artwork URLs from songs to the cache
    private func saveArtworkURLs(from songs: [Song]) {
        for song in songs {
            if let url = song.artworkURL {
                artworkCache[song.id.uuidString] = url.absoluteString
            }
        }
        saveArtworkCache()
    }
    
    // Save the artwork cache to UserDefaults
    private func saveArtworkCache() {
        UserDefaults.standard.set(artworkCache, forKey: Keys.artworkCache)
    }
    
    // Load the artwork cache from UserDefaults
    private func loadArtworkCache() {
        if let cache = UserDefaults.standard.dictionary(forKey: Keys.artworkCache) as? [String: String] {
            artworkCache = cache
        }
    }
    
    // MARK: - Clear Data (for development/testing)
    
    func clearAllData() {
        UserDefaults.standard.removeObject(forKey: Keys.rankedSongs)
        UserDefaults.standard.removeObject(forKey: Keys.pinnedAlbums)
        UserDefaults.standard.removeObject(forKey: Keys.pinnedArtists)
        UserDefaults.standard.removeObject(forKey: Keys.userProfile)
        UserDefaults.standard.removeObject(forKey: Keys.artworkCache)
        UserDefaults.standard.removeObject(forKey: Keys.lastCloudSync)
        artworkCache.removeAll()
        dataChangeSubject.send()
    }
}
