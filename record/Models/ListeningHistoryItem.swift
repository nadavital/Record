//
//  ListeningHistoryItem.swift
//  record
//
//  Created by Nadav Avital on 3/4/25.
//

import Foundation
import MusicKit

struct ListeningHistoryItem: Identifiable {
    let id: String
    let title: String
    let artist: String
    let albumName: String
    let artworkID: String
    let lastPlayedDate: Date?
    let playCount: Int
    let musicKitId: MusicItemID? // MusicKit identifier instead of MediaPlayer item
}
