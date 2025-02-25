//
//  UserProfileManager.swift
//  record
//
//  Created by Nadav Avital on 2/24/25.
//

import SwiftUI


class UserProfileManager: ObservableObject {
    @Published var username: String = "VinylLover"
    @Published var bio: String = "Music enthusiast with eclectic taste."
    @Published var profileImage: String = "profile_image" 
    @Published var accentColor: Color = Color(red: 0.94, green: 0.3, blue: 0.9)
    @Published var pinnedSongs: [Song] = []
    @Published var pinnedAlbums: [Album] = []
    
    struct Album: Identifiable {
        let id = UUID()
        let title: String
        let artist: String
        let albumArt: String
    }
    
    init() {
        // Sample data
        pinnedSongs = [
            Song(title: "Blinding Lights", artist: "The Weeknd", albumArt: "blinding_lights", sentiment: .love),
            Song(title: "Levitating", artist: "Dua Lipa", albumArt: "levitating", sentiment: .love)
        ]
        
        pinnedAlbums = [
            Album(title: "Future Nostalgia", artist: "Dua Lipa", albumArt: "future_nostalgia"),
            Album(title: "After Hours", artist: "The Weeknd", albumArt: "after_hours")
        ]
    }
}
