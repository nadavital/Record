import Foundation
import MusicKit
import SwiftUI
import os

@MainActor
class MusicPlayerManager: ObservableObject {
    @Published var currentSong: Song? = nil
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
    
    // Track the song identity to prevent flickering
    private var lastMusicKitSongId: String = ""
    private var lastPlaybackState: Bool = false
    
    init(musicAPI: MusicAPIManager? = nil) {
        self.musicAPI = musicAPI
        setupObservers()
        updatePlaybackState()
        
        // Set up a timer to periodically check playback state
        playbackTimer = Timer.scheduledTimer(withTimeInterval: 3.0, repeats: true) { [weak self] _ in
            Task { @MainActor [weak self] in
                self?.updatePlaybackState()
            }
        }
    }
    
    deinit {
        playbackTimer?.invalidate()
    }
    
    func playSong(mediaItem: MusicKit.Song) {
        logger.info("Playing song: \(mediaItem.title) by \(mediaItem.artistName)")
        
        Task {
            do {
                musicKitPlayer.queue = [mediaItem]
                try await musicKitPlayer.play()
                playbackSource = .appleMusic
                updateState(from: mediaItem, forceUpdate: true)
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
                logger.info("Setting queue for \(musicKitSong.title)")
                musicKitPlayer.queue = [musicKitSong]
                logger.info("Playing \(musicKitSong.title)")
                try await musicKitPlayer.play()
                playbackSource = .appleMusic
                updateState(from: musicKitSong, forceUpdate: true)
                logger.info("Successfully started playing \(musicKitSong.title)")
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
            logger.info("Toggle ignored due to debounce")
            return
        }
        lastToggleTime = now
        
        if isPlaying {
            logger.info("Pausing current song")
            if playbackSource == .appleMusic {
                musicKitPlayer.pause()
            }
            isPlaying = false
        } else {
            logger.info("Resuming playback")
            if playbackSource == .appleMusic && musicKitPlayer.queue.currentEntry != nil {
                Task {
                    do {
                        try await musicKitPlayer.play()
                        isPlaying = true
                        logger.info("Resumed MusicKit playback")
                    } catch {
                        logger.error("Failed to resume MusicKit playback: \(error.localizedDescription)")
                    }
                }
            } else {
                logger.warning("No song to resume playback for")
            }
        }
        updatePlaybackState()
    }
    
    func togglePlayPause() async throws {
        let now = Date()
        if let lastTime = lastToggleTime, now.timeIntervalSince(lastTime) < 0.5 {
            logger.info("Toggle ignored due to debounce")
            return
        }
        lastToggleTime = now
        
        if isPlaying {
            logger.info("Pausing current song")
            if playbackSource == .appleMusic {
                musicKitPlayer.pause()
            }
            isPlaying = false
        } else {
            logger.info("Resuming playback")
            if playbackSource == .appleMusic && musicKitPlayer.queue.currentEntry != nil {
                try await musicKitPlayer.play()
                isPlaying = true
                logger.info("Resumed MusicKit playback")
            } else {
                logger.warning("No song to resume playback for")
                throw PlaybackError.noSongAvailable
            }
        }
        updatePlaybackState()
    }
    
    func skipToNext() {
        if playbackSource == .appleMusic {
            Task {
                try? await musicKitPlayer.skipToNextEntry()
            }
        }
        updatePlaybackState()
    }
    
    func skipToNext() async throws {
        if playbackSource == .appleMusic {
            try await musicKitPlayer.skipToNextEntry()
        } else {
            throw PlaybackError.noPlaybackActive
        }
        updatePlaybackState()
    }
    
    func skipToPrevious() {
        if playbackSource == .appleMusic {
            Task {
                try? await musicKitPlayer.skipToPreviousEntry()
            }
        }
        updatePlaybackState()
    }
    
    func skipToPrevious() async throws {
        if playbackSource == .appleMusic {
            try await musicKitPlayer.skipToPreviousEntry()
        } else {
            throw PlaybackError.noPlaybackActive
        }
        updatePlaybackState()
    }
    
    private func fetchMusicKitSong(title: String, artist: String) async -> MusicKit.Song? {
        var request = MusicCatalogSearchRequest(term: "\(title) \(artist)", types: [MusicKit.Song.self])
        request.limit = 5 // Increased to improve matches
        do {
            let response = try await request.response()
            
            // Try to find an exact match first
            let exactMatch = response.songs.first { song in
                song.title.lowercased() == title.lowercased() &&
                song.artistName.lowercased() == artist.lowercased()
            }
            
            let selectedSong = exactMatch ?? response.songs.first
            
            if let song = selectedSong {
                logger.info("Found song: \(song.title) by \(song.artistName)")
                if let artwork = song.artwork, let url = artwork.url(width: 300, height: 300) {
                    musicAPI?.setArtworkURL(url, for: title, artist: artist)
                }
                return song
            } else {
                logger.warning("No songs found for \(title) by \(artist)")
                return nil
            }
        } catch {
            logger.error("Search failed for \(title) by \(artist): \(error.localizedDescription)")
            return nil
        }
    }
    
    private func updateState(from musicKitSong: MusicKit.Song, forceUpdate: Bool = false) {
        let currentMusicKitId = musicKitSong.id.rawValue
        
        // Skip update if same song and not forced
        if !forceUpdate && currentMusicKitId == lastMusicKitSongId {
            return
        }
        
        lastMusicKitSongId = currentMusicKitId
        
        var artworkURL: URL? = nil
        
        if let artwork = musicKitSong.artwork {
            artworkURL = artwork.url(width: 300, height: 300)
        }
        
        let song = Song(
            id: UUID(),
            title: musicKitSong.title,
            artist: musicKitSong.artistName,
            albumArt: musicKitSong.albumTitle ?? "",
            sentiment: .fine,
            artworkURL: artworkURL,
            score: 0.0
        )
        
        currentSong = song
        musicAPI?.currentPlayingSong = song
        if let url = song.artworkURL {
            musicAPI?.setArtworkURL(url, for: song.title, artist: song.artist)
        }
        isPlaying = musicKitPlayer.state.playbackStatus == .playing
    }
    
    private func setupObservers() {
        // For MusicKit player, we'll rely on the timer for observation
        if musicKitPlayer.state.playbackStatus == .playing {
            playbackSource = .appleMusic
            if let song = musicKitPlayer.queue.currentEntry?.item as? MusicKit.Song {
                updateState(from: song, forceUpdate: true)
            }
        }
    }
    
    private func updatePlaybackState() {
        let isMusicKitPlaying = musicKitPlayer.state.playbackStatus == .playing
        
        // Update playing state
        if isMusicKitPlaying != lastPlaybackState {
            lastPlaybackState = isMusicKitPlaying
            isPlaying = isMusicKitPlaying
        }
        
        // Update playback source and current song if needed
        if isMusicKitPlaying {
            playbackSource = .appleMusic
            if let song = musicKitPlayer.queue.currentEntry?.item as? MusicKit.Song {
                let currentId = song.id.rawValue
                if currentId != lastMusicKitSongId {
                    updateState(from: song, forceUpdate: true)
                }
            }
        } else if !isPlaying && currentSong != nil {
            if musicKitPlayer.queue.currentEntry == nil {
                currentSong = nil
                musicAPI?.currentPlayingSong = nil
                playbackSource = .none
                lastMusicKitSongId = ""
            }
        }
    }
    
    enum PlaybackError: LocalizedError {
        case noSongAvailable
        case noPlaybackActive
        
        var errorDescription: String? {
            switch self {
            case .noSongAvailable:
                return "No song available to play"
            case .noPlaybackActive:
                return "No active playback session"
            }
        }
    }
}
