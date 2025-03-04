import Foundation
import SwiftUI
import MediaPlayer
import MusicKit

class SongInfoViewModel: ObservableObject {
    @Published var unifiedSong: UnifiedSong?
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    private let musicAPI: MusicAPIManager
    private let rankingManager: MusicRankingManager
    
    init(musicAPI: MusicAPIManager, rankingManager: MusicRankingManager) {
        self.musicAPI = musicAPI
        self.rankingManager = rankingManager
    }
    
    @MainActor
    func loadSongInfo(from mediaItem: MPMediaItem) async {
        self.isLoading = true
        defer { self.isLoading = false }
        await fetchSongInfo(from: mediaItem)
    }
    
    @MainActor
    func loadSongInfo(from rankedSong: Song) async {
        self.isLoading = true
        defer { self.isLoading = false }
        await fetchSongInfo(from: rankedSong)
    }
    
    private func fetchSongInfo(from mediaItem: MPMediaItem) async {
        let title = mediaItem.title ?? "Unknown"
        let artist = mediaItem.artist ?? "Unknown"
        let album = mediaItem.albumTitle ?? ""
        
        // Check if the song is ranked
        let rankedSong = rankingManager.rankedSongs.first {
            $0.title.lowercased() == title.lowercased() &&
            $0.artist.lowercased() == artist.lowercased()
        }
        let isRanked = rankedSong != nil
        let rank = rankedSong.map { rankingManager.rankedSongs.firstIndex(of: $0)! + 1 }
        let score = rankedSong?.score
        let sentiment = rankedSong?.sentiment
        
        do {
            var request = MusicCatalogSearchRequest(term: "\(title) \(artist)", types: [MusicKit.Song.self])
            request.limit = 1
            let response = try await request.response()
            if let musicKitSong = response.songs.first {
                await MainActor.run {
                    unifiedSong = UnifiedSong(
                        title: title,
                        artist: artist,
                        album: album,
                        playCount: mediaItem.playCount,
                        lastPlayedDate: mediaItem.lastPlayedDate,
                        releaseDate: musicKitSong.releaseDate,
                        genre: musicKitSong.genreNames.first,
                        artworkURL: musicKitSong.artwork?.url(width: 300, height: 300) ?? rankedSong?.artworkURL,
                        isRanked: isRanked,
                        rank: rank,
                        score: score,
                        sentiment: sentiment
                    )
                }
            } else {
                await MainActor.run {
                    unifiedSong = UnifiedSong(
                        title: title,
                        artist: artist,
                        album: album,
                        playCount: mediaItem.playCount,
                        lastPlayedDate: mediaItem.lastPlayedDate,
                        releaseDate: nil,
                        genre: nil,
                        artworkURL: mediaItem.artwork?.image(at: CGSize(width: 300, height: 300)).flatMap { _ in URL(string: "placeholder://") } ?? rankedSong?.artworkURL,
                        isRanked: isRanked,
                        rank: rank,
                        score: score,
                        sentiment: sentiment
                    )
                }
            }
        } catch {
            await MainActor.run {
                errorMessage = "Failed to load song info: \(error.localizedDescription)"
            }
        }
    }
    
    private func fetchSongInfo(from rankedSong: Song) async {
        let title = rankedSong.title
        let artist = rankedSong.artist
        
        let query = MPMediaQuery.songs()
        let predicate = MPMediaPropertyPredicate(value: title, forProperty: MPMediaItemPropertyTitle, comparisonType: .contains)
        query.addFilterPredicate(predicate)
        let items = query.items?.filter { $0.artist?.lowercased() == artist.lowercased() }
        let mediaItem = items?.first
        
        do {
            var request = MusicCatalogSearchRequest(term: "\(title) \(artist)", types: [MusicKit.Song.self])
            request.limit = 1
            let response = try await request.response()
            if let musicKitSong = response.songs.first {
                await MainActor.run {
                    unifiedSong = UnifiedSong(
                        title: title,
                        artist: artist,
                        album: musicKitSong.albumTitle ?? rankedSong.albumArt,
                        playCount: mediaItem?.playCount ?? 0,
                        lastPlayedDate: mediaItem?.lastPlayedDate,
                        releaseDate: musicKitSong.releaseDate,
                        genre: musicKitSong.genreNames.first,
                        artworkURL: musicKitSong.artwork?.url(width: 300, height: 300) ?? rankedSong.artworkURL,
                        isRanked: true,
                        rank: rankingManager.rankedSongs.firstIndex(of: rankedSong).map { $0 + 1 } ?? 0,
                        score: rankedSong.score,
                        sentiment: rankedSong.sentiment
                    )
                }
            } else {
                await MainActor.run {
                    unifiedSong = UnifiedSong(
                        title: title,
                        artist: artist,
                        album: rankedSong.albumArt,
                        playCount: mediaItem?.playCount ?? 0,
                        lastPlayedDate: mediaItem?.lastPlayedDate,
                        releaseDate: nil,
                        genre: nil,
                        artworkURL: rankedSong.artworkURL,
                        isRanked: true,
                        rank: rankingManager.rankedSongs.firstIndex(of: rankedSong).map { $0 + 1 } ?? 0,
                        score: rankedSong.score,
                        sentiment: rankedSong.sentiment
                    )
                }
            }
        } catch {
            await MainActor.run {
                errorMessage = "Failed to load song info: \(error.localizedDescription)"
            }
        }
    }
    
    @MainActor
    func refreshSongInfo(from rankedSong: Song) async {
        isLoading = true
        defer { isLoading = false }
        await fetchSongInfo(from: rankedSong)
    }
}

struct UnifiedSong {
    let title: String
    let artist: String
    let album: String
    let playCount: Int
    let lastPlayedDate: Date?
    let releaseDate: Date?
    let genre: String?
    let artworkURL: URL?
    let isRanked: Bool
    let rank: Int?
    let score: Double?
    let sentiment: SongSentiment?
}
