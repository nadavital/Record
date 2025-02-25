//
//  SongSentiment.swift
//  record
//
//  Created by Nadav Avital on 2/24/25.
//

import SwiftUI

enum SongSentiment: String, CaseIterable {
    case love = "Love It"
    case fine = "It's Fine"
    case dislike = "Dislike"
    case neutral = "Not Rated"
    
    var color: Color {
        switch self {
        case .love: return .pink
        case .fine: return .blue
        case .dislike: return .gray
        case .neutral: return .white
        }
    }
}
