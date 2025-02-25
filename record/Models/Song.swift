//
//  Song.swift
//  record
//
//  Created by Nadav Avital on 2/24/25.
//

import Foundation

struct Song: Identifiable, Equatable {
    let id: UUID // Define as property without initializer
    let title: String
    let artist: String
    let albumArt: String
    var sentiment: SongSentiment = .neutral
    
    init(id: UUID = UUID(), title: String, artist: String, albumArt: String, sentiment: SongSentiment = .neutral) {
        self.id = id
        self.title = title
        self.artist = artist
        self.albumArt = albumArt
        self.sentiment = sentiment
    }
    
    static func == (lhs: Song, rhs: Song) -> Bool {
        return lhs.id == rhs.id
    }
}
