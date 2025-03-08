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
        isLoading = true
        defer { isLoading = false }
        await fetchSongInfo(mediaItem: mediaItem, rankedSong: nil)
    }
    
    @MainActor
    func loadSongInfo(from rankedSong: Song) async {
        isLoading = true
        defer { isLoading = false }
        await fetchSongInfo(mediaItem: nil, rankedSong: rankedSong)
    }
    
    @MainActor
    func refreshSongInfo(from rankedSong: Song) async {
        isLoading = true
        defer { isLoading = false }
        await fetchSongInfo(mediaItem: nil, rankedSong: rankedSong)
    }
    
    private func fetchSongInfo(mediaItem: MPMediaItem?, rankedSong: Song?) async {
        // Determine base song info
        let title = mediaItem?.title ?? rankedSong?.title ?? "Unknown"
        let artist = mediaItem?.artist ?? rankedSong?.artist ?? "Unknown"
        let album = mediaItem?.albumTitle ?? rankedSong?.albumArt ?? ""
        
        // Fetch MPMediaItem if not provided (for rankedSong case)
        let localMediaItem: MPMediaItem?
        if let mediaItem = mediaItem {
            localMediaItem = mediaItem
        } else {
            let query = MPMediaQuery.songs()
            let titlePredicate = MPMediaPropertyPredicate(
                value: title,
                forProperty: MPMediaItemPropertyTitle,
                comparisonType: .equalTo
            )
            let artistPredicate = MPMediaPropertyPredicate(
                value: artist,
                forProperty: MPMediaItemPropertyArtist,
                comparisonType: .equalTo
            )
            query.addFilterPredicate(titlePredicate)
            query.addFilterPredicate(artistPredicate)
            localMediaItem = query.items?.first
        }
        
        // Check ranking status using MusicAPIManager
        let rankingInfo = await musicAPI.checkIfSongIsRanked(title: title, artist: artist)
        let isRanked = rankingInfo?.isRanked ?? false
        let rank = rankingInfo?.rank
        let score = rankingInfo?.score
        let sentiment = rankingInfo != nil ? rankedSong?.sentiment ?? rankingManager.rankedSongs.first(where: { $0.title.lowercased() == title.lowercased() && $0.artist.lowercased() == artist.lowercased() })?.sentiment : nil
        
        // Fetch MusicKit data
        do {
            var request = MusicCatalogSearchRequest(term: "\(title) \(artist)", types: [MusicKit.Song.self])
            request.limit = 1
            let response = try await request.response()
            if let musicKitSong = response.songs.first {
                await MainActor.run {
                    unifiedSong = UnifiedSong(
                        title: title,
                        artist: artist,
                        album: musicKitSong.albumTitle ?? album,
                        playCount: localMediaItem?.playCount ?? 0,
                        lastPlayedDate: localMediaItem?.lastPlayedDate,
                        releaseDate: musicKitSong.releaseDate,
                        genre: musicKitSong.genreNames.first,
                        artworkURL: musicKitSong.artwork?.url(width: 300, height: 300) ?? rankedSong?.artworkURL ?? localMediaItem?.artwork?.image(at: CGSize(width: 300, height: 300)).flatMap { _ in URL(string: "placeholder://") },
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
                        playCount: localMediaItem?.playCount ?? 0,
                        lastPlayedDate: localMediaItem?.lastPlayedDate,
                        releaseDate: nil,
                        genre: nil,
                        artworkURL: rankedSong?.artworkURL ?? localMediaItem?.artwork?.image(at: CGSize(width: 300, height: 300)).flatMap { _ in URL(string: "placeholder://") },
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
                unifiedSong = UnifiedSong(
                    title: title,
                    artist: artist,
                    album: album,
                    playCount: localMediaItem?.playCount ?? 0,
                    lastPlayedDate: localMediaItem?.lastPlayedDate,
                    releaseDate: nil,
                    genre: nil,
                    artworkURL: rankedSong?.artworkURL ?? localMediaItem?.artwork?.image(at: CGSize(width: 300, height: 300)).flatMap { _ in URL(string: "placeholder://") },
                    isRanked: isRanked,
                    rank: rank,
                    score: score,
                    sentiment: sentiment
                )
            }
        }
    }
}
