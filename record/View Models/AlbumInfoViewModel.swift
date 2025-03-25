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
                    let tracks = detailedAlbum.tracks ?? MusicItemCollection<MusicKit.Track>([])
                    
                    let (trackList, totalPlays) = await fetchTracksWithPlayCounts(from: tracks)
                    
                    await MainActor.run {
                        self.albumDetails = detailedAlbum
                        self.albumSongs = trackList
                        self.totalPlayCount = totalPlays
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
    
    private func fetchTracksWithPlayCounts(from tracks: MusicItemCollection<MusicKit.Track>) async -> ([Track], Int) {
        var trackList: [Track] = []
        var totalPlayCount = 0
        
        for track in tracks {
            var playCount = 0
            do {
                var libraryRequest = MusicLibraryRequest<MusicKit.Song>()
                libraryRequest.filter(text: "\(track.title) \(track.artistName)")
                let libraryResponse = try await libraryRequest.response()
                if let librarySong = libraryResponse.items.first(where: {
                    $0.title.lowercased() == track.title.lowercased() &&
                    $0.artistName.lowercased() == track.artistName.lowercased()
                }) {
                    playCount = librarySong.playCount ?? 0
                    print("Library playCount for \(track.title) by \(track.artistName): \(playCount)")
                } else {
                    let recentlyPlayedRequest = MusicRecentlyPlayedRequest<MusicKit.Song>()
                    let recentlyPlayedResponse = try await recentlyPlayedRequest.response()
                    if let playedSong = recentlyPlayedResponse.items.first(where: {
                        $0.title.lowercased() == track.title.lowercased() &&
                        $0.artistName.lowercased() == track.artistName.lowercased()
                    }) {
                        playCount = playedSong.playCount ?? 0
                        print("Recently played playCount for \(track.title) by \(track.artistName): \(playCount)")
                    } else {
                        print("No play data for \(track.title) by \(track.artistName)")
                    }
                }
            } catch {
                print("Failed to fetch play count for \(track.title) by \(track.artistName): \(error)")
            }
            
            trackList.append(Track(
                id: UUID(),
                title: track.title,
                artistName: track.artistName,
                playCount: playCount,
                trackNumber: track.trackNumber
            ))
            totalPlayCount += playCount
        }
        
        return (trackList, totalPlayCount)
    }
    
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

struct Track: Identifiable {
    let id: UUID
    let title: String
    let artistName: String
    let playCount: Int
    let trackNumber: Int?
}
