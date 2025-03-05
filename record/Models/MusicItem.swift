//
//  MusicItemType.swift
//  record
//
//  Created by Nadav Avital on 3/4/25.
//

struct MusicItem:Identifiable {
    let id: String
    let title: String
    let artist: String
    let albumName: String
    let artworkID: String
    let type: MusicItemType
    
    enum MusicItemType {
        case song
        case album
        case artist
    }
}
