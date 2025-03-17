import Foundation
import MusicKit

class SongInfoViewModel: ObservableObject {
    @Published var unifiedSong: UnifiedSong?
    @Published var associatedAlbum: MusicKit.Album?
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    private let musicAPI: MusicAPIManager
    private let rankingManager: MusicRankingManager
    
    init(musicAPI: MusicAPIManager, rankingManager: MusicRankingManager) {
        self.musicAPI = musicAPI
        self.rankingManager = rankingManager
    }
    
    func loadSongInfo(from musicKitSong: MusicKit.Song) async {
        await MainActor.run { isLoading = true }
        let (song, album) = await createUnifiedSong(from: musicKitSong)
        await MainActor.run {
            self.unifiedSong = song
            self.associatedAlbum = album
            self.isLoading = false
        }
    }
    
    func loadSongInfo(from song: Song) async {
        await MainActor.run { isLoading = true }
        let (unifiedSong, album) = await createUnifiedSong(from: song)
        await MainActor.run {
            self.unifiedSong = unifiedSong
            self.associatedAlbum = album
            self.isLoading = false
        }
    }
    
    func refreshSongInfo(from song: Song) async {
        let (unifiedSong, album) = await createUnifiedSong(from: song)
        await MainActor.run {
            self.unifiedSong = unifiedSong
            self.associatedAlbum = album
        }
    }
    
    private func createUnifiedSong(from musicKitSong: MusicKit.Song) async -> (UnifiedSong, MusicKit.Album?) {
        await MainActor.run { isLoading = true }
        
        let title = musicKitSong.title
        let artist = musicKitSong.artistName
        let albumTitle = musicKitSong.albumTitle ?? "Unknown Album"
        
        // Get artwork URL from the song
        var artworkURL: URL? = nil
        if let artwork = musicKitSong.artwork {
            artworkURL = artwork.url(width: 300, height: 300)
        }
        
        // If no artwork from MusicKit song, check if we have it cached
        if artworkURL == nil {
            // Try to find it in musicAPI's artwork cache
            let cacheKey = "\(title)-\(artist)".lowercased()
            artworkURL = await musicAPI.getArtworkURL(for: cacheKey)
        }
        
        // Fetch ranked song
        let rankedSong = rankingManager.rankedSongs.first { ranked in
            ranked.title.trimmingCharacters(in: .whitespacesAndNewlines).lowercased() == title.trimmingCharacters(in: .whitespacesAndNewlines).lowercased() &&
            ranked.artist.trimmingCharacters(in: .whitespacesAndNewlines).lowercased() == artist.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        }
        
        // Fetch MusicKit album for additional metadata
        var musicKitAlbum: MusicKit.Album?
        do {
            var request = MusicCatalogSearchRequest(term: "\(title) \(artist)", types: [MusicKit.Song.self])
            request.limit = 1
            let response = try await request.response()
            if let track = response.songs.first {
                let trackWithAlbum = try await track.with([.albums])
                musicKitAlbum = trackWithAlbum.albums?.first
            }
        } catch {
            print("Failed to fetch MusicKit album: \(error)")
        }
        
        // Get play count from the API's listening history data
        var playCount = 0
        var lastPlayedDate: Date? = nil
        let historyItem = await musicAPI.listeningHistory.first { item in 
            item.title.lowercased() == title.lowercased() && 
            item.artist.lowercased() == artist.lowercased()
        }
        
        if let historyItem = historyItem {
            playCount = historyItem.playCount
            lastPlayedDate = historyItem.lastPlayedDate
        }
        
        return (
            UnifiedSong(
                title: title,
                artist: artist,
                album: albumTitle,
                playCount: playCount,
                lastPlayedDate: lastPlayedDate,
                releaseDate: musicKitAlbum?.releaseDate,
                genre: musicKitAlbum?.genres?.first?.name,
                artworkURL: artworkURL,
                isRanked: rankedSong != nil,
                rank: rankedSong != nil ? (rankingManager.rankedSongs.firstIndex(of: rankedSong!)! + 1) : nil,
                score: rankedSong?.score,
                sentiment: rankedSong?.sentiment
            ),
            musicKitAlbum
        )
    }
    
    private func createUnifiedSong(from song: Song) async -> (UnifiedSong, MusicKit.Album?) {
        await MainActor.run { isLoading = true }
        
        let rankedSong = rankingManager.rankedSongs.first { ranked in
            ranked.title.trimmingCharacters(in: .whitespacesAndNewlines).lowercased() == song.title.trimmingCharacters(in: .whitespacesAndNewlines).lowercased() &&
            ranked.artist.trimmingCharacters(in: .whitespacesAndNewlines).lowercased() == song.artist.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        }
        
        var playCount = 0
        var lastPlayedDate: Date?
        var musicKitAlbum: MusicKit.Album?
        var releaseDate: Date?
        var genre: String?
        var correctedAlbumTitle = song.albumArt
        
        // If albumArt looks like junk, fetch from MusicKit
        if song.albumArt.count < 3 || song.albumArt.rangeOfCharacter(from: CharacterSet.alphanumerics.inverted) == nil {
            do {
                var request = MusicCatalogSearchRequest(term: "\(song.title) \(song.artist)", types: [MusicKit.Song.self])
                request.limit = 1
                let response = try await request.response()
                if let track = response.songs.first {
                    let trackWithAlbum = try await track.with([.albums])
                    musicKitAlbum = trackWithAlbum.albums?.first
                    correctedAlbumTitle = musicKitAlbum?.title ?? song.albumArt
                    releaseDate = musicKitAlbum?.releaseDate
                    genre = musicKitAlbum?.genres?.first?.name
                }
                
                // Get play count from the API's listening history data
                let historyItem = await musicAPI.listeningHistory.first { item in 
                    item.title.lowercased() == song.title.lowercased() && 
                    item.artist.lowercased() == song.artist.lowercased()
                }
                
                if let historyItem = historyItem {
                    playCount = historyItem.playCount
                    lastPlayedDate = historyItem.lastPlayedDate
                }
                
            } catch {
                print("Error fetching MusicKit data: \(error)")
            }
        }
        
        return (
            UnifiedSong(
                title: song.title,
                artist: song.artist,
                album: correctedAlbumTitle,
                playCount: playCount,
                lastPlayedDate: lastPlayedDate,
                releaseDate: releaseDate ?? musicKitAlbum?.releaseDate,
                genre: genre ?? musicKitAlbum?.genres?.first?.name,
                artworkURL: song.artworkURL,
                isRanked: rankedSong != nil,
                rank: rankedSong != nil ? (rankingManager.rankedSongs.firstIndex(of: rankedSong!)! + 1) : nil,
                score: rankedSong?.score,
                sentiment: rankedSong?.sentiment
            ),
            musicKitAlbum
        )
    }
}
