//
//  SongSentiment.swift
//  record
//
//  Created by Nadav Avital on 2/24/25.
//

import SwiftUI

enum SongSentiment: String, CaseIterable, Codable {
    case love = "Love It"
    case fine = "It's Fine"
    case dislike = "Dislike"
    
    // Get system-appropriate color that works in both light and dark modes
    var color: Color {
        switch self {
        case .love: return .pink
        case .fine: return .blue
        case .dislike: return .gray
        }
    }
    
    // System style icon (SF Symbols)
    var icon: String {
        switch self {
        case .love: return "heart.fill"
        case .fine: return "hand.thumbsup"
        case .dislike: return "hand.thumbsdown"
        }
    }
    
    // Score ranges for each sentiment
    var scoreRange: (min: Double, max: Double) {
        switch self {
        case .love: return (7.0, 10.0)
        case .fine: return (4.0, 6.9)
        case .dislike: return (1.0, 3.9)
        }
    }
}
