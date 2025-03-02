//
//  PersistenceManager.swift
//  record
//
//  Created by GitHub Copilot on 4/2/25.
//

import Foundation
import SwiftUI
import Combine

class PersistenceManager {
    // Singleton instance
    static let shared = PersistenceManager()
    
    // UserDefaults keys
    private enum Keys {
        static let rankedSongs = "rankedSongs"
        static let pinnedSongs = "pinnedSongs"
        static let pinnedAlbums = "pinnedAlbums"
        static let pinnedArtists = "pinnedArtists"
        static let userProfile = "userProfile"
        static let artworkCache = "artworkCache"
    }
    
    // Cache for artwork URLs
    private var artworkCache: [String: String] = [:]
    
    // Create a publisher to notify when data changes
    private let dataChangeSubject = PassthroughSubject<Void, Never>()
    var dataChangePublisher: AnyPublisher<Void, Never> {
        dataChangeSubject.eraseToAnyPublisher()
    }
    
    private init() {
        // Load the artwork cache on initialization
        loadArtworkCache()
    }
    
    // MARK: - Save Methods
    
    func saveRankedSongs(_ songs: [Song]) {
        save(songs, forKey: Keys.rankedSongs)
        saveArtworkURLs(from: songs)
        dataChangeSubject.send()
    }
    
    func savePinnedSongs(_ songs: [Song]) {
        save(songs, forKey: Keys.pinnedSongs)
        saveArtworkURLs(from: songs)
        dataChangeSubject.send()
    }
    
    func savePinnedAlbums(_ albums: [Album]) {
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
        } catch {
            print("Error saving albums: \(error.localizedDescription)")
        }
    }
    
    func savePinnedArtists(_ artists: [Artist]) {
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
        } catch {
            print("Error saving artists: \(error.localizedDescription)")
        }
    }
    
    func saveUserProfile(username: String, bio: String, profileImage: String, accentColor: Color) {
        let colorComponents = UIColor(accentColor).cgColor.components ?? [0, 0, 0, 0]
        let profile: [String: Any] = [
            "username": username,
            "bio": bio,
            "profileImage": profileImage,
            "accentColorR": colorComponents[0],
            "accentColorG": colorComponents[1],
            "accentColorB": colorComponents[2],
            "accentColorA": colorComponents[3]
        ]
        UserDefaults.standard.set(profile, forKey: Keys.userProfile)
        dataChangeSubject.send()
    }
    
    // MARK: - Load Methods
    
    func loadRankedSongs() -> [Song] {
        return load(forKey: Keys.rankedSongs) ?? []
    }
    
    func loadPinnedSongs() -> [Song] {
        return load(forKey: Keys.pinnedSongs) ?? []
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
    
    func loadUserProfile() -> (username: String, bio: String, profileImage: String, accentColor: Color)? {
        guard let profile = UserDefaults.standard.dictionary(forKey: Keys.userProfile) else {
            return nil
        }
        
        // Extract the saved color components
        let r = profile["accentColorR"] as? CGFloat ?? 0.94
        let g = profile["accentColorG"] as? CGFloat ?? 0.3
        let b = profile["accentColorB"] as? CGFloat ?? 0.9
        let a = profile["accentColorA"] as? CGFloat ?? 1.0
        
        return (
            username: profile["username"] as? String ?? "VinylLover",
            bio: profile["bio"] as? String ?? "Music enthusiast with eclectic taste.",
            profileImage: profile["profileImage"] as? String ?? "profile_image",
            accentColor: Color(red: Double(r), green: Double(g), blue: Double(b), opacity: Double(a))
        )
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
        UserDefaults.standard.removeObject(forKey: Keys.pinnedSongs)
        UserDefaults.standard.removeObject(forKey: Keys.pinnedAlbums)
        UserDefaults.standard.removeObject(forKey: Keys.pinnedArtists)
        UserDefaults.standard.removeObject(forKey: Keys.userProfile)
        UserDefaults.standard.removeObject(forKey: Keys.artworkCache)
        artworkCache.removeAll()
        dataChangeSubject.send()
    }
}
