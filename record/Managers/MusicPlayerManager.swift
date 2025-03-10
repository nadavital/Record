import Foundation
import MediaPlayer
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
        case localLibrary
        case appleMusic
    }
    
    private let systemPlayer = MPMusicPlayerController.systemMusicPlayer
    private let musicKitPlayer = SystemMusicPlayer.shared
    private let logger = Logger(subsystem: "com.Nadav.record", category: "MusicPlayerManager")
    private weak var musicAPI: MusicAPIManager?
    private var lastToggleTime: Date?
    private var playbackTimer: Timer?
    
    // Track the song identity to prevent flickering
    private var lastSystemSongId: String = ""
    private var lastMusicKitSongId: String = ""
    private var lastPlaybackState: Bool = false
    
    init(musicAPI: MusicAPIManager? = nil) {
        self.musicAPI = musicAPI
        setupObservers()
        updatePlaybackState()
        
        // Set up a timer to periodically check playback state
        // Reduced frequency to minimize flickering
        playbackTimer = Timer.scheduledTimer(withTimeInterval: 3.0, repeats: true) { [weak self] _ in
            Task { @MainActor [weak self] in
                self?.updatePlaybackState()
            }
        }
    }
    
    deinit {
        playbackTimer?.invalidate()
        NotificationCenter.default.removeObserver(self)
        systemPlayer.endGeneratingPlaybackNotifications()
    }
    
    func playSong(mediaItem: MPMediaItem) {
        logger.info("Playing local song: \(mediaItem.title ?? "Unknown") by \(mediaItem.artist ?? "Unknown")")
        
        // First stop any Apple Music playback
        if musicKitPlayer.state.playbackStatus == .playing {
            musicKitPlayer.pause()
        }
        
        systemPlayer.setQueue(with: MPMediaItemCollection(items: [mediaItem]))
        systemPlayer.play()
        playbackSource = .localLibrary
        updateState(from: mediaItem, forceUpdate: true)
    }
    
    func playSong(title: String, artist: String, completion: @escaping (Bool) -> Void) {
        Task {
            logger.info("Attempting to play Apple Music song: \(title) by \(artist)")
            
            // First stop any local library playback
            if systemPlayer.playbackState == .playing {
                systemPlayer.pause()
            }
            
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
            if playbackSource == .localLibrary {
                systemPlayer.pause()
            } else if playbackSource == .appleMusic {
                musicKitPlayer.pause()
            }
            isPlaying = false
        } else {
            logger.info("Resuming playback")
            if playbackSource == .localLibrary && systemPlayer.nowPlayingItem != nil {
                systemPlayer.play()
                isPlaying = true
                logger.info("Resumed local library playback")
            } else if playbackSource == .appleMusic && musicKitPlayer.queue.currentEntry != nil {
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
    
    func skipToNext() {
        if playbackSource == .appleMusic {
            Task {
                try? await musicKitPlayer.skipToNextEntry()
            }
        } else if playbackSource == .localLibrary {
            systemPlayer.skipToNextItem()
        }
        updatePlaybackState()
    }
    
    func skipToPrevious() {
        if playbackSource == .appleMusic {
            Task {
                try? await musicKitPlayer.skipToPreviousEntry()
            }
        } else if playbackSource == .localLibrary {
            systemPlayer.skipToPreviousItem()
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
    
    private func getArtworkURL(for mediaItem: MPMediaItem) -> URL? {
        // Try to get the artwork from the media item
        if let artwork = mediaItem.artwork,
           let image = artwork.image(at: CGSize(width: 300, height: 300)),
           let imageData = image.jpegData(compressionQuality: 0.8) {
            
            let persistentID = String(mediaItem.persistentID)
            let url = FileManager.default.temporaryDirectory.appendingPathComponent("\(persistentID).jpg")
            
            do {
                try imageData.write(to: url)
                return url
            } catch {
                logger.error("Failed to write artwork to temp file: \(error.localizedDescription)")
            }
        }
        
        return nil
    }
    
    private func updateState(from mediaItem: MPMediaItem, forceUpdate: Bool = false) {
        let currentSystemId = String(mediaItem.persistentID)
        
        // Skip update if same song and not forced
        if !forceUpdate && currentSystemId == lastSystemSongId {
            return
        }
        
        lastSystemSongId = currentSystemId
        
        let artworkURL = getArtworkURL(for: mediaItem)
        
        let song = Song(
            id: UUID(),
            title: mediaItem.title ?? "Unknown Title",
            artist: mediaItem.artist ?? "Unknown Artist",
            albumArt: mediaItem.albumTitle ?? "",
            sentiment: .fine,
            artworkURL: artworkURL,
            score: 0.0
        )
        
        currentSong = song
        musicAPI?.currentPlayingSong = song
        isPlaying = systemPlayer.playbackState == .playing
        
        // If we don't have artwork from the local library, try to fetch it from Apple Music
        if artworkURL == nil {
            Task {
                if let title = mediaItem.title, let artist = mediaItem.artist,
                   let musicKitSong = await fetchMusicKitSong(title: title, artist: artist),
                   let artwork = musicKitSong.artwork,
                   let url = artwork.url(width: 300, height: 300) {
                    
                    // Only update if still the same song
                    if lastSystemSongId == currentSystemId {
                        await MainActor.run {
                            var updatedSong = song
                            updatedSong.artworkURL = url
                            currentSong = updatedSong
                            musicAPI?.currentPlayingSong = updatedSong
                            musicAPI?.setArtworkURL(url, for: title, artist: artist)
                        }
                    }
                }
            }
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
        systemPlayer.beginGeneratingPlaybackNotifications()
        
        NotificationCenter.default.addObserver(
            forName: .MPMusicPlayerControllerNowPlayingItemDidChange,
            object: systemPlayer,
            queue: .main
        ) { [weak self] _ in
            guard let self = self, let item = systemPlayer.nowPlayingItem else { return }
            self.playbackSource = .localLibrary
            // Force update when the item changes through notification
            self.updateState(from: item, forceUpdate: true)
        }
        
        NotificationCenter.default.addObserver(
            forName: .MPMusicPlayerControllerPlaybackStateDidChange,
            object: systemPlayer,
            queue: .main
        ) { [weak self] _ in
            self?.updatePlaybackState()
        }
        
        // For MusicKit player, we'll rely on the timer instead of direct observation
        if musicKitPlayer.state.playbackStatus == .playing {
            playbackSource = .appleMusic
            if let song = musicKitPlayer.queue.currentEntry?.item as? MusicKit.Song {
                updateState(from: song, forceUpdate: true)
            }
        }
    }
    
    private func updatePlaybackState() {
        let isSystemPlaying = systemPlayer.playbackState == .playing
        let isMusicKitPlaying = musicKitPlayer.state.playbackStatus == .playing
        
        let currentPlaybackState = isSystemPlaying || isMusicKitPlaying
        
        // Update playing state
        if currentPlaybackState != lastPlaybackState {
            lastPlaybackState = currentPlaybackState
            isPlaying = currentPlaybackState
        }
        
        // Update playback source if needed
        if isSystemPlaying {
            playbackSource = .localLibrary
            if let item = systemPlayer.nowPlayingItem {
                let currentId = String(item.persistentID)
                if currentId != lastSystemSongId {
                    updateState(from: item, forceUpdate: true)
                }
            }
        } else if isMusicKitPlaying {
            playbackSource = .appleMusic
            if let song = musicKitPlayer.queue.currentEntry?.item as? MusicKit.Song {
                let currentId = song.id.rawValue
                if currentId != lastMusicKitSongId {
                    updateState(from: song, forceUpdate: true)
                }
            }
        } else if !isPlaying && currentSong != nil {
            if systemPlayer.nowPlayingItem == nil && musicKitPlayer.queue.currentEntry == nil {
                currentSong = nil
                musicAPI?.currentPlayingSong = nil
                playbackSource = .none
                lastSystemSongId = ""
                lastMusicKitSongId = ""
            }
        }
    }
}
