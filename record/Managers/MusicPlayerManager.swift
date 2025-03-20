import Foundation
import MusicKit
import SwiftUI
import os
import MediaPlayer

@MainActor
class MusicPlayerManager: ObservableObject {
    @Published var currentSong: Song? = nil {
        didSet {
            if let song = currentSong {
                logger.debug("currentSong updated: \(song.title) by \(song.artist)")
            } else {
                logger.debug("currentSong set to nil")
            }
        }
    }
    @Published var isPlaying: Bool = false
    @Published var playbackSource: PlaybackSource = .none
    
    enum PlaybackSource {
        case none
        case appleMusic
    }
    
    private let musicKitPlayer = SystemMusicPlayer.shared
    private let logger = Logger(subsystem: "com.Nadav.record", category: "MusicPlayerManager")
    private weak var musicAPI: MusicAPIManager?
    private var lastToggleTime: Date?
    private var playbackTimer: Timer?
    
    private var lastMusicKitSongId: String = ""
    private var applicationMusicPlayer: ApplicationMusicPlayer?
    private var nowPlayingInfoObserver: Any?
    
    init(musicAPI: MusicAPIManager? = nil) {
        self.musicAPI = musicAPI
        logger.debug("MusicPlayerManager initialized")
        
        // Initialize additional player
        self.applicationMusicPlayer = ApplicationMusicPlayer.shared
        
        // Check Apple Music authorization status
        Task {
            let status = MusicAuthorization.currentStatus
            logger.debug("MusicKit authorization status: \(status.rawValue)")
        }
        
        // Check current state immediately
        updateCurrentSong()
        
        // Set up a more frequent timer for checking playback state
        playbackTimer = Timer.scheduledTimer(withTimeInterval: 0.5, repeats: true) { [weak self] _ in
            Task { @MainActor [weak self] in
                self?.updateCurrentSong()
            }
        }
        
        // Also check on app becoming active
        NotificationCenter.default.addObserver(
            self, 
            selector: #selector(applicationDidBecomeActive), 
            name: UIApplication.didBecomeActiveNotification, 
            object: nil
        )
        
        // Add observer for MPMusicPlayerController nowPlayingItem changes
        setupNowPlayingObserver()
        
        logger.debug("MusicPlayerManager setup complete")
    }
    
    deinit {
        playbackTimer?.invalidate()
        NotificationCenter.default.removeObserver(self)
        
        if let observer = nowPlayingInfoObserver {
            NotificationCenter.default.removeObserver(observer)
        }
    }
    
    private func setupNowPlayingObserver() {
        // Register for MPMusicPlayerController notifications
        let musicPlayer = MPMusicPlayerController.systemMusicPlayer
        musicPlayer.beginGeneratingPlaybackNotifications()
        
        // Add observer for now playing item changes
        nowPlayingInfoObserver = NotificationCenter.default.addObserver(
            forName: .MPMusicPlayerControllerNowPlayingItemDidChange,
            object: musicPlayer,
            queue: .main) { [weak self] _ in
                self?.handleNowPlayingItemChanged()
            }
        
        // Also observe playback state changes
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handlePlaybackStateChanged),
            name: .MPMusicPlayerControllerPlaybackStateDidChange,
            object: musicPlayer
        )
    }
    
    @objc private func handlePlaybackStateChanged() {
        Task { @MainActor in
            // Check if music is playing and update
            let mpPlayer = MPMusicPlayerController.systemMusicPlayer
            isPlaying = mpPlayer.playbackState == .playing
            
            // If playing, make sure we have the right song info
            if isPlaying {
                handleNowPlayingItemChanged()
            }
        }
    }
    
    private func handleNowPlayingItemChanged() {
        Task { @MainActor in
            // Check both MPMusicPlayerController and MusicKit
            
            // First try MPMusicPlayerController
            if let mediaItem = MPMusicPlayerController.systemMusicPlayer.nowPlayingItem {
                // Only update if it's different from what we have
                let title = mediaItem.title ?? "Unknown Title"
                let artist = mediaItem.artist ?? "Unknown Artist"
                
                if currentSong == nil || 
                   currentSong?.title != title || 
                   currentSong?.artist != artist {
                    
                    logger.debug("MPMusicPlayerController now playing: \(title) by \(artist)")
                    
                    // Create a Song from the MPMediaItem
                    var artworkURL: URL? = nil
                    if let artwork = mediaItem.artwork?.image(at: CGSize(width: 300, height: 300)) {
                        // Try to get an artwork URL from the musicAPI cache if available
                        artworkURL = musicAPI?.getArtworkURL(for: "\(title)-\(artist)".lowercased())
                    }
                    
                    let song = Song(
                        id: UUID(),
                        title: title,
                        artist: artist,
                        albumArt: mediaItem.albumTitle ?? "",
                        sentiment: .fine,
                        artworkURL: artworkURL,
                        score: 0.0
                    )
                    
                    currentSong = song
                    musicAPI?.currentPlayingSong = song
                    playbackSource = .appleMusic
                    
                    // If we have no artwork URL, try to fetch one
                    if artworkURL == nil {
                        fetchSongArtwork(title: title, artist: artist)
                    }
                }
                
                isPlaying = MPMusicPlayerController.systemMusicPlayer.playbackState == .playing
            } 
            else {
                // Fallback to MusicKit player
                await tryUpdateFromMusicKit()
            }
        }
    }
    
    private func fetchSongArtwork(title: String, artist: String) {
        Task {
            do {
                var request = MusicCatalogSearchRequest(term: "\(title) \(artist)", types: [MusicKit.Song.self])
                request.limit = 1
                
                let response = try await request.response()
                if let song = response.songs.first,
                   let artwork = song.artwork,
                   let url = artwork.url(width: 300, height: 300) {
                    
                    // Update our current song with the artwork URL
                    if var updatedSong = currentSong {
                        updatedSong.artworkURL = url
                        currentSong = updatedSong
                        
                        // Cache the artwork URL
                        musicAPI?.setArtworkURL(url, for: title, artist: artist)
                    }
                }
            } catch {
                logger.error("Failed to fetch artwork for \(title) by \(artist): \(error.localizedDescription)")
            }
        }
    }
    
    private func tryUpdateFromMusicKit() async {
        // Check MusicKit player state
        if musicKitPlayer.state.playbackStatus == .playing {
            // Try to get current song from MusicKit
            if let currentItem = musicKitPlayer.queue.currentEntry?.item as? MusicKit.Song {
                updateSongInfo(from: currentItem)
            } else {
                try? await fetchNowPlayingItem()
            }
        } else {
            // Check if media is playing through some other means 
            // but MusicKit isn't reporting it correctly
            let mpPlaybackState = MPMusicPlayerController.systemMusicPlayer.playbackState
            if mpPlaybackState == .playing && currentSong == nil {
                try? await fetchNowPlayingItem()
            }
        }
    }
    
    func playSong(mediaItem: MusicKit.Song) {
        logger.info("Playing song: \(mediaItem.title) by \(mediaItem.artistName)")
        
        Task {
            do {
                musicKitPlayer.queue = [mediaItem]
                try await musicKitPlayer.play()
                playbackSource = .appleMusic
                updateSongInfo(from: mediaItem)
            } catch {
                logger.error("Failed to play song: \(error.localizedDescription)")
            }
        }
    }
    
    func playSong(title: String, artist: String, completion: @escaping (Bool) -> Void) {
        Task {
            logger.info("Attempting to play Apple Music song: \(title) by \(artist)")
            
            guard let musicKitSong = await fetchMusicKitSong(title: title, artist: artist) else {
                logger.error("No song found for \(title) by \(artist)")
                completion(false)
                return
            }
            
            do {
                musicKitPlayer.queue = [musicKitSong]
                try await musicKitPlayer.play()
                playbackSource = .appleMusic
                updateSongInfo(from: musicKitSong)
                completion(true)
            } catch {
                logger.error("Failed to play \(title) by \(artist): \(error.localizedDescription)")
                completion(false)
            }
        }
    }
    
    func togglePlayPause() {
        let now = Date()
        if let lastTime = lastToggleTime, now.timeIntervalSince(lastTime) < 0.5 {
            return // Debounce
        }
        lastToggleTime = now
        
        if isPlaying {
            if playbackSource == .appleMusic {
                musicKitPlayer.pause()
            }
            isPlaying = false
        } else {
            if playbackSource == .appleMusic {
                Task {
                    try? await musicKitPlayer.play()
                    isPlaying = true
                }
            }
        }
    }
    
    func skipToNext() {
        if playbackSource == .appleMusic {
            Task {
                try? await musicKitPlayer.skipToNextEntry()
                // The timer will pick up the change
            }
        }
    }
    
    func skipToPrevious() {
        if playbackSource == .appleMusic {
            Task {
                try? await musicKitPlayer.skipToPreviousEntry()
                // The timer will pick up the change
            }
        }
    }
    
    private func fetchMusicKitSong(title: String, artist: String) async -> MusicKit.Song? {
        var request = MusicCatalogSearchRequest(term: "\(title) \(artist)", types: [MusicKit.Song.self])
        request.limit = 5
        
        do {
            let response = try await request.response()
            
            // Try to find an exact match first
            let exactMatch = response.songs.first { song in
                song.title.lowercased() == title.lowercased() &&
                song.artistName.lowercased() == artist.lowercased()
            }
            
            let selectedSong = exactMatch ?? response.songs.first
            
            if let song = selectedSong {
                if let artwork = song.artwork, let url = artwork.url(width: 300, height: 300) {
                    musicAPI?.setArtworkURL(url, for: title, artist: artist)
                }
                return song
            }
            return nil
        } catch {
            logger.error("Search failed for \(title) by \(artist): \(error.localizedDescription)")
            return nil
        }
    }
    
    @objc private func applicationDidBecomeActive() {
        // When app becomes active, immediately check for any currently playing music
        logger.info("App became active, checking for playing music")
        
        // Check MPMusicPlayerController first
        handleNowPlayingItemChanged()
        
        // Then fallback to MusicKit
        updateCurrentSong()
        
        // Also perform a more extensive check
        Task {
            try? await fetchNowPlayingItem()
        }
    }
    
    private func fetchNowPlayingItem() async throws {
        // Try to get information about what's currently playing from both players
        
        // First try system player
        let systemState = musicKitPlayer.state
        
        // Check if music is playing in the system player
        if systemState.playbackStatus == .playing,
           let currentItem = musicKitPlayer.queue.currentEntry?.item as? MusicKit.Song {
            updateSongInfo(from: currentItem)
            return
        }
        
        // Next try application player
        if let appPlayer = self.applicationMusicPlayer,
           appPlayer.state.playbackStatus == .playing,
           let currentItem = appPlayer.queue.currentEntry?.item as? MusicKit.Song {
            updateSongInfo(from: currentItem)
            return
        }
        
        // If still no result, try an alternative approach using the recently played music
        if musicKitPlayer.state.playbackStatus == .playing {
            // Try to find what's playing using a catalog search for recently played music
            var request = MusicRecentlyPlayedRequest<MusicKit.Song>()
            request.limit = 1
            
            do {
                let response = try await request.response()
                if let recentSong = response.items.first {
                    // Assume this might be playing now
                    updateSongInfo(from: recentSong)
                }
            } catch {
                logger.error("Failed to get recently played: \(error.localizedDescription)")
            }
        }
    }
    
    private func updateCurrentSong() {
        // First check MPMusicPlayerController
        let mpPlayer = MPMusicPlayerController.systemMusicPlayer
        let mpPlaying = mpPlayer.playbackState == .playing
        
        // Next check MusicKit player
        let mkPlaying = musicKitPlayer.state.playbackStatus == .playing
        
        // Update isPlaying based on either player
        let nowPlaying = mpPlaying || mkPlaying
        if isPlaying != nowPlaying {
            isPlaying = nowPlaying
            logger.debug("Playback state changed: \(nowPlaying ? "playing" : "paused")")
        }
        
        // If anything is playing, check for song info
        if nowPlaying {
            if mpPlaying && mpPlayer.nowPlayingItem != nil {
                // Already handled in handleNowPlayingItemChanged
                handleNowPlayingItemChanged()
                return
            }
            
            // Try MusicKit if MPMusicPlayerController has no info
            playbackSource = .appleMusic
            
            // Get the current song from the queue if available
            if let currentItem = musicKitPlayer.queue.currentEntry?.item as? MusicKit.Song {
                let currentId = currentItem.id.rawValue
                
                // Update if it's a different song or we don't have a current song
                if currentId != lastMusicKitSongId || currentSong == nil {
                    updateSongInfo(from: currentItem)
                    logger.debug("Updated current song: \(currentItem.title) by \(currentItem.artistName)")
                }
            } else {
                // If we can't get currentEntry but something is playing,
                // try our alternative method
                Task {
                    try? await fetchNowPlayingItem()
                }
            }
        }
    }
    
    private func updateSongInfo(from musicKitSong: MusicKit.Song) {
        lastMusicKitSongId = musicKitSong.id.rawValue
        
        // Extract artwork URL if available
        var artworkURL: URL? = nil
        if let artwork = musicKitSong.artwork {
            artworkURL = artwork.url(width: 300, height: 300)
        }
        
        logger.debug("Creating Song object from MusicKit.Song: \(musicKitSong.title)")
        
        // Create a Song object with the information
        let song = Song(
            id: UUID(),
            title: musicKitSong.title,
            artist: musicKitSong.artistName,
            albumArt: musicKitSong.albumTitle ?? "",
            sentiment: .fine,
            artworkURL: artworkURL,
            score: 0.0
        )
        
        // Update published properties
        DispatchQueue.main.async {
            self.currentSong = song
            self.musicAPI?.currentPlayingSong = song
            
            // Cache artwork URL
            if let url = artworkURL {
                self.musicAPI?.setArtworkURL(url, for: song.title, artist: song.artist)
            }
        }
    }
}
