//
//  Song.swift
//  record
//
//  Created by Nadav Avital on 2/24/25.
//

import Foundation

struct Song: Identifiable, Equatable, Codable {
    let id: UUID
    let title: String
    let artist: String
    let albumArt: String
    var sentiment: SongSentiment = .fine
    var artworkURL: URL?
    var score: Double = 0.0 // Score from 0-10 based on ranking
    
    init(id: UUID = UUID(), title: String, artist: String, albumArt: String, sentiment: SongSentiment = .fine, artworkURL: URL? = nil, score: Double = 0.0) {
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
    
    // Custom coding for handling URL optionals
    enum CodingKeys: String, CodingKey {
        case id, title, artist, albumArt, sentiment, score
        case artworkURLString
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        id = try container.decode(UUID.self, forKey: .id)
        title = try container.decode(String.self, forKey: .title)
        artist = try container.decode(String.self, forKey: .artist)
        albumArt = try container.decode(String.self, forKey: .albumArt)
        sentiment = try container.decode(SongSentiment.self, forKey: .sentiment)
        score = try container.decode(Double.self, forKey: .score)
        
        // Handle URL conversion
        if let urlString = try container.decodeIfPresent(String.self, forKey: .artworkURLString) {
            artworkURL = URL(string: urlString)
        } else {
            artworkURL = nil
        }
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        try container.encode(id, forKey: .id)
        try container.encode(title, forKey: .title)
        try container.encode(artist, forKey: .artist)
        try container.encode(albumArt, forKey: .albumArt)
        try container.encode(sentiment, forKey: .sentiment)
        try container.encode(score, forKey: .score)
        
        // Handle URL conversion
        if let url = artworkURL {
            try container.encode(url.absoluteString, forKey: .artworkURLString)
        }
    }
}
