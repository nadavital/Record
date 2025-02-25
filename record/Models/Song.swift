//
//  Song.swift
//  record
//
//  Created by Nadav Avital on 2/24/25.
//

import Foundation

struct Song: Identifiable, Equatable {
    let id: UUID
    let title: String
    let artist: String
    let albumArt: String
    var sentiment: SongSentiment = .neutral
    var artworkURL: URL?
    var score: Double = 0.0 // Score from 0-10 based on ranking
    
    init(id: UUID = UUID(), title: String, artist: String, albumArt: String, sentiment: SongSentiment = .neutral, artworkURL: URL? = nil, score: Double = 0.0) {
        self.id = id
        self.title = title
        self.artist = artist
        self.albumArt = albumArt
        self.sentiment = sentiment
        self.artworkURL = artworkURL
        self.score = score
    }
    
    static func == (lhs: Song, rhs: Song) -> Bool {
        return lhs.id == rhs.id
    }
}
