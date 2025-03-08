import Foundation
import SwiftUI
import MusicKit
import MediaPlayer

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
                    
                    // Calculate total play count from local library
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
        for track in tracks {
            let query = MPMediaQuery.songs()
            let titlePredicate = MPMediaPropertyPredicate(
                value: track.title,
                forProperty: MPMediaItemPropertyTitle,
                comparisonType: .equalTo
            )
            let artistPredicate = MPMediaPropertyPredicate(
                value: track.artistName,
                forProperty: MPMediaItemPropertyArtist,
                comparisonType: .equalTo
            )
            query.addFilterPredicate(titlePredicate)
            query.addFilterPredicate(artistPredicate)
            if let mediaItem = query.items?.first {
                total += mediaItem.playCount
            }
        }
        return total
    }
    
    func getRankedSongs(rankingManager: MusicRankingManager) -> [Track] {
        return albumSongs.filter { track in
            rankingManager.rankedSongs.contains { rankedSong in
                rankedSong.title.lowercased() == track.title.lowercased() &&
                rankedSong.artist.lowercased() == track.artistName.lowercased()
            }
        }
    }
    
    func getUnrankedSongs(rankingManager: MusicRankingManager) -> [Track] {
        return albumSongs.filter { track in
            !rankingManager.rankedSongs.contains { rankedSong in
                rankedSong.title.lowercased() == track.title.lowercased() &&
                rankedSong.artist.lowercased() == track.artistName.lowercased()
            }
        }
    }
}
