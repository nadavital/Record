import Foundation
import SwiftUI
import MusicKit
import Combine

class AlbumInfoViewModel: ObservableObject {
    @Published var albumDetails: MusicKit.Album?
    @Published var albumSongs: [Track] = [] // Changed from [MusicKit.Song] to [Track]
    @Published var isLoadingAlbumDetails = true
    @Published var errorMessage: String?
    
    private var musicAPI: MusicAPIManager
    private var cancellables = Set<AnyCancellable>()
    
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
                print("Search term: \(album.title) \(album.artist), Found albums: \(response.albums.count)")
                
                if let fetchedAlbum = response.albums.first {
                    print("Fetching tracks for album: \(fetchedAlbum.title)")
                    let detailedAlbum = try await fetchedAlbum.with([.tracks])
                    let tracks = detailedAlbum.tracks ?? []
                    print("Total tracks fetched: \(tracks.count)")
                    
                    await MainActor.run {
                        self.albumDetails = detailedAlbum
                        self.albumSongs = Array(tracks) // Store tracks directly
                        self.isLoadingAlbumDetails = false
                        print("Loaded \(tracks.count) tracks")
                    }
                } else {
                    await MainActor.run {
                        self.isLoadingAlbumDetails = false
                        self.errorMessage = "Album not found"
                        print("No album found in catalog")
                    }
                }
            } catch {
                print("Error loading album details: \(error.localizedDescription)")
                await MainActor.run {
                    self.isLoadingAlbumDetails = false
                    self.errorMessage = "Failed to load album details: \(error.localizedDescription)"
                }
            }
        }
    }
    
    func getSongWithMostPlays() -> Track? { // Updated return type
        return albumSongs.first
    }
    
    func getRankedSongs(rankingManager: MusicRankingManager) -> [Track] { // Updated return type
        return albumSongs.filter { track in
            let songTitle = track.title
            let songArtist = track.artistName
            return rankingManager.rankedSongs.contains { rankedSong in
                rankedSong.title.lowercased() == songTitle.lowercased() &&
                rankedSong.artist.lowercased() == songArtist.lowercased()
            }
        }
    }
    
    func getUnrankedSongs(rankingManager: MusicRankingManager) -> [Track] { // Updated return type
        return albumSongs.filter { track in
            let songTitle = track.title
            let songArtist = track.artistName
            return !rankingManager.rankedSongs.contains { rankedSong in
                rankedSong.title.lowercased() == songTitle.lowercased() &&
                rankedSong.artist.lowercased() == songArtist.lowercased()
            }
        }
    }
}
