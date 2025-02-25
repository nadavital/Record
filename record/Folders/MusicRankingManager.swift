//
//  MusicRankingManager.swift
//  record
//
//  Created by Nadav Avital on 2/24/25.
//

import Foundation
import SwiftUI

class MusicRankingManager: ObservableObject {
    @Published var rankedSongs: [Song] = []
    @Published var currentSong: Song?
    @Published var comparisonSong: Song?
    @Published var comparisonIndex: Int = 0
    @Published var isRanking: Bool = false
    @Published var showSentimentPicker: Bool = false
    @Published var showComparison: Bool = false
    
    // Mock data for initial setup
    init() {
        let sampleSongs = [
            Song(title: "Blinding Lights", artist: "The Weeknd", albumArt: "blinding_lights", sentiment: .love),
            Song(title: "Don't Start Now", artist: "Dua Lipa", albumArt: "dont_start_now", sentiment: .love),
            Song(title: "As It Was", artist: "Harry Styles", albumArt: "as_it_was", sentiment: .fine),
            Song(title: "Levitating", artist: "Dua Lipa", albumArt: "levitating", sentiment: .love),
            Song(title: "Good 4 U", artist: "Olivia Rodrigo", albumArt: "good_4_u", sentiment: .fine)
        ]
        rankedSongs = sampleSongs
    }
    
    func addNewSong(song: Song) {
        currentSong = song
        showSentimentPicker = true
    }
    
    func setSentiment(_ sentiment: SongSentiment) {
        guard var song = currentSong else { return }
        song.sentiment = sentiment
        currentSong = song
        showSentimentPicker = false
        
        // Skip comparison if ranked list is empty
        if rankedSongs.isEmpty {
            rankedSongs.append(song)
            finishRanking()
            return
        }
        
        // Start binary search process based on sentiment
        startComparison()
    }
    
    func startComparison() {
        isRanking = true
        showComparison = true
        
        // Find initial comparison point based on sentiment
        let sentimentGroup = rankedSongs.filter { $0.sentiment == currentSong?.sentiment }
        
        if sentimentGroup.isEmpty {
            // If no songs with same sentiment, place accordingly
            switch currentSong?.sentiment {
            case .love:
                comparisonIndex = 0
            case .fine:
                comparisonIndex = rankedSongs.firstIndex(where: { $0.sentiment == .dislike }) ?? rankedSongs.count
            case .dislike:
                comparisonIndex = rankedSongs.count
            default:
                comparisonIndex = rankedSongs.count / 2
            }
        } else {
            // Start in middle of sentiment group
            let firstIndex = rankedSongs.firstIndex(where: { $0.sentiment == currentSong?.sentiment }) ?? 0
            let lastIndex = rankedSongs.lastIndex(where: { $0.sentiment == currentSong?.sentiment }) ?? 0
            comparisonIndex = (firstIndex + lastIndex) / 2
        }
        
        comparisonSong = rankedSongs[comparisonIndex]
    }
    
    func comparePreferred(currentSongIsBetter: Bool) {
        guard let song = currentSong else { return }
        
        if rankedSongs.count <= 1 {
            // If only one song to compare or empty list
            if currentSongIsBetter {
                rankedSongs.insert(song, at: 0)
            } else {
                rankedSongs.append(song)
            }
            finishRanking()
            return
        }
        
        // Binary search logic
        if currentSongIsBetter {
            // Current song ranks higher than comparison
            if comparisonIndex == 0 {
                // It's better than the top song
                rankedSongs.insert(song, at: 0)
                finishRanking()
            } else {
                // Move up in the list (lower index)
                let newIndex = comparisonIndex / 2
                comparisonIndex = newIndex
                comparisonSong = rankedSongs[newIndex]
            }
        } else {
            // Comparison song ranks higher
            if comparisonIndex == rankedSongs.count - 1 {
                // It's worse than the bottom song
                rankedSongs.append(song)
                finishRanking()
            } else {
                // Move down in the list (higher index)
                let newIndex = comparisonIndex + (rankedSongs.count - comparisonIndex) / 2
                
                if newIndex == comparisonIndex {
                    // We've reached the end of our search
                    rankedSongs.insert(song, at: comparisonIndex + 1)
                    finishRanking()
                } else {
                    comparisonIndex = newIndex
                    comparisonSong = rankedSongs[newIndex]
                }
            }
        }
    }
    
    func finishRanking() {
        currentSong = nil
        comparisonSong = nil
        isRanking = false
        showComparison = false
    }
}
