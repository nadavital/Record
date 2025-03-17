import Foundation
import MediaPlayer
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
    
    func loadSongInfo(from mediaItem: MPMediaItem) async {
        await MainActor.run { isLoading = true }
        let (song, album) = await createUnifiedSong(from: mediaItem)
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
    
    private func createUnifiedSong(from mediaItem: MPMediaItem) async -> (UnifiedSong, MusicKit.Album?) {
        let title = mediaItem.title ?? "Unknown Title"
        let artist = mediaItem.artist ?? "Unknown Artist"
        let albumTitle = mediaItem.albumTitle ?? "Unknown Album"
        
        // First, try to get artwork from MPMediaItem directly
        var artworkURL: URL? = nil
        if let artwork = mediaItem.artwork,
           let image = artwork.image(at: CGSize(width: 300, height: 300)) {
           // Create a temporary file URL for the image
           let tempDir = FileManager.default.temporaryDirectory
           let fileName = "\(UUID().uuidString).jpg"
           let fileURL = tempDir.appendingPathComponent(fileName)
           
           if let jpegData = image.jpegData(compressionQuality: 0.8) {
               try? jpegData.write(to: fileURL)
               artworkURL = fileURL
           }
        }
        
        // If no artwork from MPMediaItem, check if we have it cached
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
        
        return (
            UnifiedSong(
                title: title,
                artist: artist,
                album: albumTitle,
                playCount: mediaItem.playCount,
                lastPlayedDate: mediaItem.lastPlayedDate,
                releaseDate: mediaItem.releaseDate ?? musicKitAlbum?.releaseDate,
                genre: mediaItem.genre ?? musicKitAlbum?.genres?.first?.name,
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
        let query = MPMediaQuery.songs()
        let titlePredicate = MPMediaPropertyPredicate(
            value: song.title,
            forProperty: MPMediaItemPropertyTitle,
            comparisonType: .equalTo
        )
        let artistPredicate = MPMediaPropertyPredicate(
            value: song.artist,
            forProperty: MPMediaItemPropertyArtist,
            comparisonType: .equalTo
        )
        query.addFilterPredicate(titlePredicate)
        query.addFilterPredicate(artistPredicate)
        if let mediaItem = query.items?.first {
            playCount = mediaItem.playCount
            lastPlayedDate = mediaItem.lastPlayedDate
        }
        
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
            } catch {
                print("Failed to fetch MusicKit album: \(error)")
            }
        }
        
        let unifiedSong = UnifiedSong(
            title: song.title,
            artist: song.artist,
            album: correctedAlbumTitle,
            playCount: playCount,
            lastPlayedDate: lastPlayedDate,
            releaseDate: releaseDate,
            genre: genre,
            artworkURL: song.artworkURL ?? musicKitAlbum?.artwork?.url(width: 300, height: 300),
            isRanked: rankedSong != nil,
            rank: rankedSong != nil ? (rankingManager.rankedSongs.firstIndex(of: rankedSong!)! + 1) : nil,
            score: rankedSong?.score,
            sentiment: rankedSong?.sentiment
        )
        print("UnifiedSong from Song: title=\(song.title), album=\(correctedAlbumTitle)")
        return (unifiedSong, musicKitAlbum)
    }
}
