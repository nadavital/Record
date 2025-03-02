//
//  MusicRankingManager.swift
//  record
//
//  Created by Nadav Avital on 2/24/25.
//

import Foundation
import SwiftUI
import Combine

class MusicRankingManager: ObservableObject {
    @Published var rankedSongs: [Song] = []
    @Published var currentSong: Song?
    @Published var comparisonSong: Song?
    @Published var comparisonIndex: Int = 0
    @Published var isRanking: Bool = false
    @Published var showSentimentPicker: Bool = false
    @Published var showComparison: Bool = false
    @Published var isReranking: Bool = false // Track if we're reranking an existing song
    
    // Tracking the search bounds for binary search
    private var lowerBound: Int = 0
    private var upperBound: Int = 0
    
    // Track comparison history to avoid repetition
    private var comparedIndices: Set<Int> = []
    
    // Cancellable for data change subscription
    private var cancellables = Set<AnyCancellable>()
    
    // Init method with persistence support
    init() {
        // Load saved songs
        rankedSongs = PersistenceManager.shared.loadRankedSongs()
        updateScores()
        setupDataChangeSubscription() // Set up subscription for data changes
    }
    
    // Check if a song is already ranked by title and artist
    func isSongAlreadyRanked(title: String, artist: String) -> (isRanked: Bool, song: Song?) {
        if let matchingIndex = rankedSongs.firstIndex(where: { 
            $0.title.lowercased() == title.lowercased() && 
            $0.artist.lowercased() == artist.lowercased() 
        }) {
            return (true, rankedSongs[matchingIndex])
        }
        return (false, nil)
    }
    
    // Add a new song to be ranked
    func addNewSong(song: Song) {
        // Check if this song is already ranked
        let (isRanked, existingSong) = isSongAlreadyRanked(title: song.title, artist: song.artist)
        
        if isRanked, let existingSong = existingSong {
            // If song already exists, prepare for reranking
            isReranking = true
            
            // Remove the existing song from the ranked list before reranking
            if let index = rankedSongs.firstIndex(where: { $0.id == existingSong.id }) {
                rankedSongs.remove(at: index)
            }
        } else {
            isReranking = false
        }
        
        // Ensure we preserve the artworkURL when setting currentSong
        currentSong = song
        showSentimentPicker = true
    }
    
    // Set sentiment for the current song and start comparison process
    func setSentiment(_ sentiment: SongSentiment) {
        guard var song = currentSong else { return }
        song.sentiment = sentiment
        currentSong = song  // Keep the same song object with updated sentiment
        showSentimentPicker = false
        
        // Skip comparison if ranked list is empty
        if rankedSongs.isEmpty {
            rankedSongs.append(song)
            updateScores()
            finishRanking()
            return
        }
        
        // Start binary search process based on sentiment
        startComparison()
    }
    
    // Initialize comparison process
    func startComparison() {
        isRanking = true
        showComparison = true
        comparedIndices.removeAll()
        
        // Calculate initial index based on sentiment
        initialPlacement()
    }
    
    // Set the initial comparison point based on song sentiment
    private func initialPlacement() {
        guard let sentiment = currentSong?.sentiment else { return }
        
        // Clear comparison history
        comparedIndices.removeAll()
        
        // First, ensure songs are in proper sentiment order
        ensureSentimentOrder()
        
        // When list is small, use a simpler approach to establish rough position
        if rankedSongs.count <= 4 {
            // For very small lists, start with the middle or appropriate end
            if rankedSongs.count <= 2 {
                comparisonIndex = 0 // Start with first song
            } else {
                // With 3-4 songs, pick a more strategic starting point based on sentiment
                switch sentiment {
                case .love:
                    comparisonIndex = 0 // Compare with top song
                case .fine:
                    comparisonIndex = rankedSongs.count / 2 // Middle
                case .dislike:
                    comparisonIndex = rankedSongs.count - 1 // Bottom
                }
            }
            
            // Set bounds to include the entire list initially
            lowerBound = 0
            upperBound = rankedSongs.count - 1
            
            // Mark as compared and set comparison song
            comparedIndices.insert(comparisonIndex)
            comparisonSong = rankedSongs[comparisonIndex]
            return
        }
        
        // For larger lists, use sentiment groups to narrow the search area
        let loveIndices = rankedSongs.indices.filter { rankedSongs[$0].sentiment == .love }
        let fineIndices = rankedSongs.indices.filter { rankedSongs[$0].sentiment == .fine }
        
        // Set bounds based on sentiment
        switch sentiment {
        case .love:
            // For Love songs, only compare within the Love group or at the top
            lowerBound = 0
            upperBound = loveIndices.isEmpty ? 0 : loveIndices.last!
        case .fine:
            // For Fine songs, compare within the Fine group or right after Love songs
            lowerBound = loveIndices.isEmpty ? 0 : loveIndices.last! + 1
            upperBound = fineIndices.isEmpty ? lowerBound : fineIndices.last!
        case .dislike:
            // For Dislike songs, compare within Dislike group or after Fine/Love songs
            let lastBetterIndex = (loveIndices + fineIndices).max() ?? -1
            lowerBound = lastBetterIndex + 1
            upperBound = rankedSongs.count - 1
        }
        
        // Safety adjustments for bounds
        lowerBound = max(0, min(lowerBound, rankedSongs.count - 1))
        upperBound = max(lowerBound, min(upperBound, rankedSongs.count - 1))
        
        // For larger sentiment groups, pick a more strategic starting point
        let groupSize = upperBound - lowerBound + 1
        
        if groupSize <= 1 {
            // If only one position is valid, use it
            comparisonIndex = lowerBound
        } else if groupSize <= 4 {
            // For small groups, start in the middle
            comparisonIndex = lowerBound + groupSize / 2
        } else {
            // For larger groups, use the 1/3 or 2/3 position based on sentiment
            switch sentiment {
            case .love:
                // For love songs, start 1/3 of the way down the love group
                comparisonIndex = lowerBound + groupSize / 3
            case .fine:
                // For fine songs, start right in the middle of the fine group
                comparisonIndex = lowerBound + groupSize / 2
            case .dislike:
                // For dislike songs, start 2/3 of the way down the dislike group
                comparisonIndex = lowerBound + (groupSize * 2) / 3
            }
        }
        
        // Final safety check for valid index
        comparisonIndex = max(lowerBound, min(upperBound, comparisonIndex))
        
        // Mark this index as compared
        comparedIndices.insert(comparisonIndex)
        
        // Set the comparison song
        if rankedSongs.indices.contains(comparisonIndex) {
            comparisonSong = rankedSongs[comparisonIndex]
        } else {
            // If we can't find a valid comparison (should never happen with proper bounds)
            placeSongBySentiment()
        }
    }
    
    // Place a song automatically based on its sentiment
    private func placeSongBySentiment() {
        guard let song = currentSong, let sentiment = currentSong?.sentiment else { return }
        
        // Insert at the right position for this sentiment
        let insertIndex: Int
        
        switch sentiment {
        case .love:
            // Put it at the beginning of the love group or at the top
            insertIndex = 0
        case .fine:
            // Put it at the beginning of the fine group
            let lastLoveIndex = rankedSongs.lastIndex(where: { $0.sentiment == .love }) ?? -1
            insertIndex = lastLoveIndex + 1
        case .dislike:
            // Put it at the beginning of the dislike group
            let lastBetterIndex = rankedSongs.lastIndex(where: { 
                $0.sentiment == .fine || $0.sentiment == .love 
            }) ?? -1
            insertIndex = lastBetterIndex + 1
        }
        
        // Insert song and update scores
        let safeIndex = min(rankedSongs.count, max(0, insertIndex))
        rankedSongs.insert(song, at: safeIndex)
        updateScores()
        finishRanking()
    }
    
    // Handle user selection in comparison
    func comparePreferred(currentSongIsBetter: Bool, tooClose: Bool = false) {
        guard let song = currentSong else { return }
        
        // Edge cases: empty list or single song
        if rankedSongs.isEmpty {
            rankedSongs.append(song)
            updateScores()
            finishRanking()
            return
        } else if rankedSongs.count == 1 {
            let index = currentSongIsBetter ? 0 : 1
            rankedSongs.insert(song, at: index)
            updateScores()
            finishRanking()
            return
        }
        
        // Handle "too close" case differently - use linear stepping
        if tooClose {
            handleTooCloseComparison(currentSongIsBetter: currentSongIsBetter)
            return
        }
        
        // Update our bounds based on the comparison result
        if currentSongIsBetter {
            // Current song is better than the comparison song
            // Move our upper bound down to exclude the current comparison index
            upperBound = comparisonIndex - 1
        } else {
            // Comparison song is better than current song
            // Move our lower bound up to exclude the current comparison index
            lowerBound = comparisonIndex + 1
        }
        
        // Check if we've narrowed down to a final position
        if lowerBound > upperBound {
            let insertionIndex = currentSongIsBetter ? comparisonIndex : comparisonIndex + 1
            rankedSongs.insert(song, at: max(0, min(rankedSongs.count, insertionIndex)))
            updateScores()
            finishRanking()
            return
        }
        
        // Determine next comparison index
        var nextComparisonIndex: Int
        
        // If we've already compared with a lot of indices, use a linear approach for the final steps
        if comparedIndices.count > 3 && upperBound - lowerBound <= 3 {
            // In final stages, just compare sequentially from the bottom up
            nextComparisonIndex = lowerBound
            while comparedIndices.contains(nextComparisonIndex) && nextComparisonIndex <= upperBound {
                nextComparisonIndex += 1
            }
            
            // If we've compared all indices, insert at the appropriate position
            if nextComparisonIndex > upperBound {
                // Insert based on last comparison result
                let insertPosition = currentSongIsBetter ? comparisonIndex : comparisonIndex + 1
                rankedSongs.insert(song, at: max(0, min(rankedSongs.count, insertPosition)))
                updateScores()
                finishRanking()
                return
            }
        } else {
            // Standard binary search - pick the middle of the current range
            nextComparisonIndex = lowerBound + (upperBound - lowerBound) / 2
            
            // If we've already compared with this index, find the closest uncompared index
            if comparedIndices.contains(nextComparisonIndex) {
                var uncomparedFound = false
                
                // Try to find any uncompared index within our bounds
                for i in lowerBound...upperBound {
                    if !comparedIndices.contains(i) {
                        nextComparisonIndex = i
                        uncomparedFound = true
                        break
                    }
                }
                
                // If all indices in our range have been compared, finalize
                if !uncomparedFound {
                    // Insert based on the most recent comparison
                    let insertPosition = currentSongIsBetter ? comparisonIndex : comparisonIndex + 1
                    rankedSongs.insert(song, at: max(0, min(rankedSongs.count, insertPosition)))
                    updateScores()
                    finishRanking()
                    return
                }
            }
        }
        
        // Ensure our next index is valid
        nextComparisonIndex = max(lowerBound, min(upperBound, nextComparisonIndex))
        
        // Update state and move to next comparison
        comparisonIndex = nextComparisonIndex
        comparedIndices.insert(comparisonIndex)
        
        if comparisonIndex >= 0 && comparisonIndex < rankedSongs.count {
            comparisonSong = rankedSongs[comparisonIndex]
        } else {
            // Safety fallback - should never happen with proper bounds checks
            let insertPosition = currentSongIsBetter ? 0 : rankedSongs.count
            rankedSongs.insert(song, at: insertPosition)
            updateScores()
            finishRanking()
        }
    }
    
    // Handle case where songs are too close to easily compare
    private func handleTooCloseComparison(currentSongIsBetter: Bool) {
        guard let song = currentSong else { return }
        
        // For songs that are too similar, we'll take smaller steps
        // and be more likely to finalize placement after minimal comparisons
        
        // If we're at an extreme position, just insert and be done
        if comparisonIndex == 0 || comparisonIndex == rankedSongs.count - 1 {
            let position = comparisonIndex == 0 && !currentSongIsBetter ? 1 : 
                          (currentSongIsBetter ? comparisonIndex : comparisonIndex + 1)
            
            // Preserve the currentSong exactly as is, including artworkURL
            rankedSongs.insert(song, at: position)
            updateScores()
            finishRanking()
            return
        }
        
        // Try an adjacent position for the next comparison
        let nextIndex = currentSongIsBetter ? comparisonIndex - 1 : comparisonIndex + 1
        
        // If we've already compared with adjacent positions, finalize placement
        if comparedIndices.contains(nextIndex) || 
           comparedIndices.count >= 3 ||  // Limit total comparisons to avoid fatigue
           (nextIndex != 0 && nextIndex != rankedSongs.count - 1 && 
            comparedIndices.contains(nextIndex - 1) && comparedIndices.contains(nextIndex + 1)) {
            
            // Insert at an appropriate position based on the comparison results
            let insertPosition = currentSongIsBetter ? comparisonIndex : comparisonIndex + 1
            rankedSongs.insert(song, at: max(0, min(rankedSongs.count, insertPosition)))
            updateScores()
            finishRanking()
            return
        }
        
        // Set up for the next comparison
        comparisonIndex = nextIndex
        comparedIndices.insert(comparisonIndex)
        comparisonSong = rankedSongs[comparisonIndex]
    }
    
    // Place the song at its final position
    private func finalizePlacement(currentSongIsBetter: Bool) {
        guard let song = currentSong else { return }
        
        let insertionIndex: Int
        
        if rankedSongs.isEmpty {
            // Empty list case
            insertionIndex = 0
        } else if comparisonIndex < 0 || (comparisonIndex == 0 && currentSongIsBetter) {
            // Insert at start if better than first song
            insertionIndex = 0
        } else if comparisonIndex >= rankedSongs.count - 1 && !currentSongIsBetter {
            // Append at end if worse than last song
            insertionIndex = rankedSongs.count
        } else {
            // Insert based on last comparison
            insertionIndex = currentSongIsBetter ? comparisonIndex : comparisonIndex + 1
        }
        
        // Safety check for bounds
        let safeIndex = min(rankedSongs.count, max(0, insertionIndex))
        // Preserve the currentSong exactly as is, including artworkURL
        rankedSongs.insert(song, at: safeIndex)
        
        // Update scores after inserting
        updateScores()
        
        // Finish the ranking process
        finishRanking()
    }
    
    // Place song at the end without comparison
    private func placeSongAtEnd() {
        guard let song = currentSong else { return }
        // Preserve the currentSong exactly as is, including artworkURL
        rankedSongs.append(song)
        updateScores()
        finishRanking()
    }
    
    // Update scores based on rankings with constraints by sentiment
    private func updateScores() {
        let count = rankedSongs.count
        if count <= 1 {
            // If only one song, give it a score based on sentiment
            if let first = rankedSongs.first {
                var song = first
                song.score = scoreBasedOnSentiment(song.sentiment, isTop: true)
                rankedSongs[0] = song
            }
            return
        }
        
        // First, sort songs to ensure proper sentiment order
        ensureSentimentOrder()
        
        // Group songs by sentiment
        let loveGroup = rankedSongs.filter { $0.sentiment == .love }
        let fineGroup = rankedSongs.filter { $0.sentiment == .fine }
        let dislikeGroup = rankedSongs.filter { $0.sentiment == .dislike }
        
        var updatedSongs: [Song] = []
        
        // Score each sentiment group separately
        if (!loveGroup.isEmpty) {
            updatedSongs.append(contentsOf: scoreGroup(loveGroup, scoreRange: (7.0, 10.0)))
        }
        
        if (!fineGroup.isEmpty) {
            updatedSongs.append(contentsOf: scoreGroup(fineGroup, scoreRange: (4.0, 6.9)))
        }
        
        if (!dislikeGroup.isEmpty) {
            updatedSongs.append(contentsOf: scoreGroup(dislikeGroup, scoreRange: (1.0, 3.9)))
        }
        
        // Replace the ranked songs with the updated scored songs
        rankedSongs = updatedSongs
        saveRankedSongs() // Save after updating scores
    }
    
    // Ensure songs are ordered by sentiment first
    private func ensureSentimentOrder() {
        // Sort the songs list by sentiment priority first, then by current order
        var indexes: [UUID: Int] = [:]
        for (index, song) in rankedSongs.enumerated() {
            indexes[song.id] = index
        }
        
        rankedSongs.sort { song1, song2 in
            if song1.sentiment != song2.sentiment {
                // Love > Fine > Dislike
                if song1.sentiment == .love { return true }
                if song2.sentiment == .love { return false }
                if song1.sentiment == .fine { return true }
                return false
            }
            
            // If same sentiment, keep their current order
            return (indexes[song1.id] ?? 0) < (indexes[song2.id] ?? 0)
        }
    }
    
    // Score a group of songs within a specific range
    private func scoreGroup(_ songs: [Song], scoreRange: (Double, Double)) -> [Song] {
        let count = songs.count
        let (minScore, maxScore) = scoreRange
        let scoreSpread = maxScore - minScore
        
        return songs.enumerated().map { index, song in
            var updatedSong = song
            if count == 1 {
                // If only one song in this sentiment group
                updatedSong.score = (maxScore * 10).rounded() / 10
            } else {
                // Calculate score within the specified range
                let rawScore = maxScore - (Double(index) / Double(count - 1)) * scoreSpread
                updatedSong.score = (rawScore * 10).rounded() / 10
            }
            return updatedSong
        }
    }
    
    // Get default score based on sentiment
    private func scoreBasedOnSentiment(_ sentiment: SongSentiment, isTop: Bool = false) -> Double {
        switch sentiment {
        case .love:
            return isTop ? 10.0 : 8.5
        case .fine:
            return isTop ? 6.5 : 5.5
        case .dislike:
            return isTop ? 3.0 : 2.0
        }
    }
    
    // Reset ranking state at end or when cancelled
    func finishRanking() {
        currentSong = nil
        comparisonSong = nil
        comparisonIndex = 0
        isRanking = false
        isReranking = false  // Reset the reranking flag
        showComparison = false
        showSentimentPicker = false
        lowerBound = 0
        upperBound = 0
        comparedIndices.removeAll()
        saveRankedSongs() // Save after ranking is finished
    }
    
    // Cancel ranking process (from any stage)
    func cancelRanking() {
        finishRanking()
    }
    
    // Remove a song from the ranked list
    func removeSong(_ song: Song) {
        if let index = rankedSongs.firstIndex(where: { $0.id == song.id }) {
            rankedSongs.remove(at: index)
            updateScores()
            saveRankedSongs() // Save after removing a song
        }
    }

    // Save songs to persistence
    private func saveRankedSongs() {
        PersistenceManager.shared.saveRankedSongs(rankedSongs)
    }

    // Subscribe to data change notifications from other parts of the app
    private func setupDataChangeSubscription() {
        PersistenceManager.shared.dataChangePublisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] in
                self?.loadSavedSongs()
            }
            .store(in: &cancellables)
    }

    // Load songs from persistence
    private func loadSavedSongs() {
        let savedSongs = PersistenceManager.shared.loadRankedSongs()
        if (!savedSongs.isEmpty && savedSongs != rankedSongs) {
            rankedSongs = savedSongs
            updateScores()
        }
    }
}
