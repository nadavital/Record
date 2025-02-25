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
    
    // Get system-appropriate color that works in both light and dark modes
    var color: Color {
        switch self {
        case .love: return .pink
        case .fine: return Color.blue
        case .dislike: return Color.gray
        case .neutral: return Color(.systemGray)
        }
    }
    
    // Light mode colors
    var lightModeColor: Color {
        switch self {
        case .love: return Color(red: 1.0, green: 0.2, blue: 0.5)    // Bright pink
        case .fine: return Color(red: 0.0, green: 0.6, blue: 1.0)    // Bright blue
        case .dislike: return Color(red: 0.5, green: 0.5, blue: 0.5) // Medium gray
        case .neutral: return Color(red: 0.7, green: 0.7, blue: 0.7) // Light gray
        }
    }
    
    // Dark mode colors (more vibrant to show better in dark mode)
    var darkModeColor: Color {
        switch self {
        case .love: return Color(red: 1.0, green: 0.4, blue: 0.7)    // Lighter pink
        case .fine: return Color(red: 0.4, green: 0.7, blue: 1.0)    // Lighter blue
        case .dislike: return Color(red: 0.65, green: 0.65, blue: 0.65) // Lighter gray
        case .neutral: return Color(red: 0.8, green: 0.8, blue: 0.8) // Very light gray
        }
    }
    
    // System style icon (SF Symbols)
    var icon: String {
        switch self {
        case .love: return "heart.fill"
        case .fine: return "hand.thumbsup"
        case .dislike: return "hand.thumbsdown"
        case .neutral: return "questionmark.circle"
        }
    }
    
    // Returns preferred initial position for binary search
    // as a fraction (0.0 - 1.0) of the ranked list
    var initialSearchPosition: Double {
        switch self {
        case .love: return 0.15    // Top 15%
        case .fine: return 0.5     // Middle
        case .dislike: return 0.85 // Bottom 15%
        case .neutral: return 0.5  // Middle (fallback)
        }
    }
    
    // Score ranges for each sentiment
    var scoreRange: (min: Double, max: Double) {
        switch self {
        case .love: return (7.0, 10.0)
        case .fine: return (4.0, 6.9)
        case .dislike: return (1.0, 3.9)
        case .neutral: return (5.0, 5.0)
        }
    }
}
