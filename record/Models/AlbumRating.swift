//
//  AlbumRating.swift
//  record
//
//  Created by Nadav Avital on 3/6/25.
//

import Foundation

struct AlbumRating: Identifiable, Codable, Equatable {
    let id: UUID
    let albumId: String
    let title: String
    let artist: String
    var rating: Double // 0.5 to 5.0 in 0.5 increments
    var review: String
    var dateAdded: Date
    var artworkURL: URL?
    
    init(id: UUID = UUID(), 
         albumId: String, 
         title: String, 
         artist: String, 
         rating: Double = 0.0, 
         review: String = "", 
         dateAdded: Date = Date(), 
         artworkURL: URL? = nil) {
        self.id = id
        self.albumId = albumId
        self.title = title
        self.artist = artist
        self.rating = rating
        self.review = review
        self.dateAdded = dateAdded
        self.artworkURL = artworkURL
    }
    
    // Custom coding for handling URL optionals
    enum CodingKeys: String, CodingKey {
        case id, albumId, title, artist, rating, review, dateAdded
        case artworkURLString
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        id = try container.decode(UUID.self, forKey: .id)
        albumId = try container.decode(String.self, forKey: .albumId)
        title = try container.decode(String.self, forKey: .title)
        artist = try container.decode(String.self, forKey: .artist)
        rating = try container.decode(Double.self, forKey: .rating)
        review = try container.decode(String.self, forKey: .review)
        dateAdded = try container.decode(Date.self, forKey: .dateAdded)
        
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
        try container.encode(albumId, forKey: .albumId)
        try container.encode(title, forKey: .title)
        try container.encode(artist, forKey: .artist)
        try container.encode(rating, forKey: .rating)
        try container.encode(review, forKey: .review)
        try container.encode(dateAdded, forKey: .dateAdded)
        
        // Handle URL conversion
        if let url = artworkURL {
            try container.encode(url.absoluteString, forKey: .artworkURLString)
        }
    }
    
    static func == (lhs: AlbumRating, rhs: AlbumRating) -> Bool {
        return lhs.id == rhs.id
    }
}
