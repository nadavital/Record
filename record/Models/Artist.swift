//
//  Artist.swift
//  record
//
//

import Foundation

struct Artist: Identifiable, Codable, Equatable {
    let id: UUID
    let name: String
    var artworkURL: URL?
    
    init(id: UUID = UUID(), name: String, artworkURL: URL? = nil) {
        self.id = id
        self.name = name
        self.artworkURL = artworkURL
    }
    
    // Custom coding for handling URL optionals
    enum CodingKeys: String, CodingKey {
        case id, name
        case artworkURLString
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        id = try container.decode(UUID.self, forKey: .id)
        name = try container.decode(String.self, forKey: .name)
        
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
        try container.encode(name, forKey: .name)
        
        // Handle URL conversion
        if let url = artworkURL {
            try container.encode(url.absoluteString, forKey: .artworkURLString)
        }
    }
    
    static func == (lhs: Artist, rhs: Artist) -> Bool {
        return lhs.name == rhs.name
    }
}
