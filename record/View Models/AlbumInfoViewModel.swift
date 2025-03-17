import Foundation
import SwiftUI
import MusicKit

class AlbumInfoViewModel: ObservableObject {
    @Published var albumDetails: MusicKit.Album?
    @Published var albumSongs: [Track] = []
    @Published var totalPlayCount: Int = 0
    @Published var isLoadingAlbumDetails = true
    @Published var errorMessage: String?
    
    private var musicAPI: MusicAPIManager
    
    init(musicAPI: MusicAPIManager) {
        self.musicAPI = musicAPI
    }
    
    func loadAlbumDetails(album: Album) {
        isLoadingAlbumDetails = true
        
        Task {
            do {
                var request = MusicCatalogSearchRequest(term: "\(album.title) \(album.artist)", types: [MusicKit.Album.self])
                request.limit = 1
                
                let response = try await request.response()
                if let fetchedAlbum = response.albums.first {
                    let detailedAlbum = try await fetchedAlbum.with([.tracks])
                    let tracks = detailedAlbum.tracks ?? []
                    
                    // Calculate total play count from MusicKit listening history
                    let playCount = await calculateTotalPlayCount(for: tracks)
                    
                    await MainActor.run {
                        self.albumDetails = detailedAlbum
                        self.albumSongs = Array(tracks)
                        self.totalPlayCount = playCount
                        self.isLoadingAlbumDetails = false
                    }
                } else {
                    await MainActor.run {
                        self.isLoadingAlbumDetails = false
                        self.errorMessage = "Album not found"
                    }
                }
            } catch {
                await MainActor.run {
                    self.isLoadingAlbumDetails = false
                    self.errorMessage = "Failed to load album details: \(error.localizedDescription)"
                }
            }
        }
    }
    
    private func calculateTotalPlayCount(for tracks: MusicItemCollection<Track>) async -> Int {
        var total = 0
        
        // Use the listening history from MusicAPI to calculate play counts
        for track in tracks {
            let historyItem = await musicAPI.listeningHistory.first { item in
                item.title.lowercased() == track.title.lowercased() &&
                item.artist.lowercased() == track.artistName.lowercased()
            }
            
            if let historyItem = historyItem {
                total += historyItem.playCount
            }
        }
        
        return total
    }
    
    // Add methods for getting ranked and unranked songs
    func getRankedSongs(rankingManager: MusicRankingManager) -> [Track] {
        return albumSongs.filter { track in
            rankingManager.rankedSongs.contains { song in
                song.title.lowercased() == track.title.lowercased() &&
                song.artist.lowercased() == track.artistName.lowercased()
            }
        }
    }
    
    func getUnrankedSongs(rankingManager: MusicRankingManager) -> [Track] {
        return albumSongs.filter { track in
            !rankingManager.rankedSongs.contains { song in
                song.title.lowercased() == track.title.lowercased() &&
                song.artist.lowercased() == track.artistName.lowercased()
            }
        }
    }
}
