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
    
    func loadSongInfo(from mediaItem: MPMediaItem) async {
        isLoading = true
        defer { isLoading = false }
        
        let title = mediaItem.title ?? "Unknown"
        let artist = mediaItem.artist ?? "Unknown"
        let album = mediaItem.albumTitle ?? ""
        
        // Check ranking
        let rankingInfo = musicAPI.checkIfSongIsRanked(title: title, artist: artist)
        let rankedSong = rankingManager.rankedSongs.first {
            $0.title.lowercased() == title.lowercased() &&
            $0.artist.lowercased() == artist.lowercased()
        }
        
        // Fetch MusicKit data
        do {
            var request = MusicCatalogSearchRequest(term: "\(title) \(artist)", types: [MusicKit.Song.self])
            request.limit = 1
            let response = try await request.response()
            if let musicKitSong = response.songs.first {
                unifiedSong = UnifiedSong(
                    title: title,
                    artist: artist,
                    album: album,
                    playCount: mediaItem.playCount,
                    lastPlayedDate: mediaItem.lastPlayedDate,
                    releaseDate: musicKitSong.releaseDate,
                    genre: musicKitSong.genreNames.first,
                    artworkURL: musicKitSong.artwork?.url(width: 300, height: 300),
                    isRanked: rankingInfo?.isRanked ?? false,
                    rank: rankingInfo?.rank,
                    score: rankingInfo?.score,
                    sentiment: rankedSong?.sentiment
                )
            } else {
                // Fallback if no MusicKit match
                unifiedSong = UnifiedSong(
                    title: title,
                    artist: artist,
                    album: album,
                    playCount: mediaItem.playCount,
                    lastPlayedDate: mediaItem.lastPlayedDate,
                    releaseDate: nil,
                    genre: nil,
                    artworkURL: mediaItem.artwork?.image(at: CGSize(width: 300, height: 300)).flatMap { URL(string: "placeholder://") }, // Placeholder
                    isRanked: rankingInfo?.isRanked ?? false,
                    rank: rankingInfo?.rank,
                    score: rankingInfo?.score,
                    sentiment: rankedSong?.sentiment
                )
            }
        } catch {
            errorMessage = "Failed to load song info: \(error.localizedDescription)"
        }
    }
    
    func loadSongInfo(from rankedSong: Song) async {
        isLoading = true
        defer { isLoading = false }
        
        let title = rankedSong.title
        let artist = rankedSong.artist
        
        // Fetch MediaPlayer data
        let query = MPMediaQuery.songs()
        let predicate = MPMediaPropertyPredicate(value: title, forProperty: MPMediaItemPropertyTitle, comparisonType: .contains)
        query.addFilterPredicate(predicate)
        let items = query.items?.filter { $0.artist?.lowercased() == artist.lowercased() }
        let mediaItem = items?.first
        
        // Fetch MusicKit data
        do {
            var request = MusicCatalogSearchRequest(term: "\(title) \(artist)", types: [MusicKit.Song.self])
            request.limit = 1
            let response = try await request.response()
            if let musicKitSong = response.songs.first {
                unifiedSong = UnifiedSong(
                    title: title,
                    artist: artist,
                    album: musicKitSong.albumTitle ?? "",
                    playCount: mediaItem?.playCount ?? 0,
                    lastPlayedDate: mediaItem?.lastPlayedDate,
                    releaseDate: musicKitSong.releaseDate,
                    genre: musicKitSong.genreNames.first,
                    artworkURL: musicKitSong.artwork?.url(width: 300, height: 300) ?? rankedSong.artworkURL,
                    isRanked: true,
                    rank: rankingManager.rankedSongs.firstIndex(of: rankedSong).map { $0 + 1 },
                    score: rankedSong.score,
                    sentiment: rankedSong.sentiment
                )
            }
        } catch {
            errorMessage = "Failed to load song info: \(error.localizedDescription)"
        }
    }
    
    func reRankSong() {
        guard let song = unifiedSong else { return }
        // Trigger ranking process (simplified; adjust based on MusicRankingManager)
        let rankedSong = Song(title: song.title, artist: song.artist, albumArt: song.album, sentiment: .fine, artworkURL: song.artworkURL)
        rankingManager.beginRanking(for: rankedSong)
    }
}