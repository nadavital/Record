//
//  UnifiedSong.swift
//  record
//
//  Created by Nadav Avital on 3/4/25.
//

import Foundation

struct UnifiedSong {
    let title: String
    let artist: String
    let album: String
    let playCount: Int
    let lastPlayedDate: Date?
    let releaseDate: Date?
    let genre: String?
    let artworkURL: URL?
    let isRanked: Bool
    let rank: Int?
    let score: Double?
    let sentiment: SongSentiment?
}
