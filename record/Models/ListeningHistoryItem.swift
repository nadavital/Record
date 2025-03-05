//
//  ListeningHistoryItem.swift
//  record
//
//  Created by Nadav Avital on 3/4/25.
//

import Foundation
import MediaPlayer

struct ListeningHistoryItem: Identifiable {
    let id: String
    let title: String
    let artist: String
    let albumName: String
    let artworkID: String
    let lastPlayedDate: Date?
    let playCount: Int
    let mediaItem: MPMediaItem // Added to store the full MPMediaItem
}
