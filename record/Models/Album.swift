//
//  Album.swift
//  record
//
//  Created by GitHub Copilot on 3/11/25.
//

import Foundation

struct Album: Identifiable, Codable {
    let id: UUID
    let title: String
    let artist: String
    let albumArt: String
    var artworkURL: URL?
    
    init(id: UUID = UUID(), title: String, artist: String, albumArt: String, artworkURL: URL? = nil) {
        self.id = id
        self.title = title
        self.artist = artist
        self.albumArt = albumArt
        self.artworkURL = artworkURL
    }
    
    // Custom coding for handling URL optionals
    enum CodingKeys: String, CodingKey {
        case id, title, artist, albumArt
        case artworkURLString
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        id = try container.decode(UUID.self, forKey: .id)
        title = try container.decode(String.self, forKey: .title)
        artist = try container.decode(String.self, forKey: .artist)
        albumArt = try container.decode(String.self, forKey: .albumArt)
        
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
        
        // Handle URL conversion
        if let url = artworkURL {
            try container.encode(url.absoluteString, forKey: .artworkURLString)
        }
    }
}