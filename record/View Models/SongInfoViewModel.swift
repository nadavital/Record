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
        let title = musicKitSong.title
        let artist = musicKitSong.artistName
        let albumTitle = musicKitSong.albumTitle ?? "Unknown Album"
        
        var artworkURL: URL? = nil
        if let artwork = musicKitSong.artwork {
            artworkURL = artwork.url(width: 300, height: 300)
        }
        if artworkURL == nil {
            let cacheKey = "\(title)-\(artist)".lowercased()
            artworkURL = await musicAPI.getArtworkURL(for: cacheKey)
        }
        
        let rankedSong = rankingManager.rankedSongs.first { ranked in
            ranked.title.trimmingCharacters(in: .whitespacesAndNewlines).lowercased() == title.trimmingCharacters(in: .whitespacesAndNewlines).lowercased() &&
            ranked.artist.trimmingCharacters(in: .whitespacesAndNewlines).lowercased() == artist.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        }
        
        var musicKitAlbum: MusicKit.Album?
        var playCount: Int = 0
        var lastPlayedDate: Date?
        
        // Fetch full song metadata from catalog
        do {
            var catalogRequest = MusicCatalogSearchRequest(term: "\(title) \(artist)", types: [MusicKit.Song.self])
            catalogRequest.limit = 1
            let catalogResponse = try await catalogRequest.response()
            if let catalogSong = catalogResponse.songs.first {
                // Attempt to fetch extended properties (though playCount isn't directly here)
                let detailedSong = try await catalogSong.with([.albums])
                musicKitAlbum = detailedSong.albums?.first
                // playCount isn't populated from catalog alone; check library next
            }
        } catch {
            print("Failed to fetch catalog song: \(error)")
        }
        
        // Check library for user-specific play count
        do {
            var libraryRequest = MusicLibraryRequest<MusicKit.Song>()
            libraryRequest.filter(text: "\(title) \(artist)")
            let libraryResponse = try await libraryRequest.response()
            if let librarySong = libraryResponse.items.first(where: {
                $0.title.lowercased() == title.lowercased() &&
                $0.artistName.lowercased() == artist.lowercased()
            }) {
                playCount = librarySong.playCount ?? 0
                lastPlayedDate = librarySong.lastPlayedDate
                print("Library playCount for \(title) by \(artist): \(playCount)")
            } else {
                // If not in library, try recently played for catalog songs
                let recentlyPlayedRequest = MusicRecentlyPlayedRequest<MusicKit.Song>()
                let recentlyPlayedResponse = try await recentlyPlayedRequest.response()
                if let playedSong = recentlyPlayedResponse.items.first(where: {
                    $0.title.lowercased() == title.lowercased() &&
                    $0.artistName.lowercased() == artist.lowercased()
                }) {
                    playCount = playedSong.playCount ?? 0
                    lastPlayedDate = playedSong.lastPlayedDate
                    print("Recently played playCount for \(title) by \(artist): \(playCount)")
                } else {
                    print("No play data for \(title) by \(artist)")
                }
            }
        } catch {
            print("Failed to fetch play count: \(error)")
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
        let rankedSong = rankingManager.rankedSongs.first { ranked in
            ranked.title.trimmingCharacters(in: .whitespacesAndNewlines).lowercased() == song.title.trimmingCharacters(in: .whitespacesAndNewlines).lowercased() &&
            ranked.artist.trimmingCharacters(in: .whitespacesAndNewlines).lowercased() == song.artist.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        }
        
        var musicKitAlbum: MusicKit.Album?
        var correctedAlbumTitle = song.albumArt
        var releaseDate: Date?
        var genre: String?
        var playCount = 0
        var lastPlayedDate: Date?
        
        // Fetch from catalog
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
        } catch {
            print("Error fetching MusicKit data: \(error)")
        }
        
        // Fetch play count
        do {
            var libraryRequest = MusicLibraryRequest<MusicKit.Song>()
            libraryRequest.filter(text: "\(song.title) \(song.artist)")
            let libraryResponse = try await libraryRequest.response()
            if let librarySong = libraryResponse.items.first(where: {
                $0.title.lowercased() == song.title.lowercased() &&
                $0.artistName.lowercased() == song.artist.lowercased()
            }) {
                playCount = librarySong.playCount ?? 0
                lastPlayedDate = librarySong.lastPlayedDate
                print("Library playCount for \(song.title) by \(song.artist): \(playCount)")
            } else {
                let recentlyPlayedRequest = MusicRecentlyPlayedRequest<MusicKit.Song>()
                let recentlyPlayedResponse = try await recentlyPlayedRequest.response()
                if let playedSong = recentlyPlayedResponse.items.first(where: {
                    $0.title.lowercased() == song.title.lowercased() &&
                    $0.artistName.lowercased() == song.artist.lowercased()
                }) {
                    playCount = playedSong.playCount ?? 0
                    lastPlayedDate = playedSong.lastPlayedDate
                    print("Recently played playCount for \(song.title) by \(song.artist): \(playCount)")
                } else {
                    print("No play data for \(song.title) by \(song.artist)")
                }
            }
        } catch {
            print("Failed to fetch play count: \(error)")
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
