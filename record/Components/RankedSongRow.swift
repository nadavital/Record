//
//  RankedSongRow.swift
//  record
//
//  Created by Nadav Avital on 2/24/25.
//

import SwiftUI

struct RankedSongRow: View {
    let rank: Int
    let song: Song
    @Environment(\.colorScheme) private var colorScheme
    
    // Score color based on value - adapts to light/dark mode
    private var scoreColor: Color {
        if song.score >= 9.0 {
            return colorScheme == .dark ? 
                Color(red: 1.0, green: 0.85, blue: 0.0) : // Gold (darker)
                Color(red: 0.9, green: 0.65, blue: 0.0)   // Gold (lighter)
        } else if song.score >= 7.0 {
            return colorScheme == .dark ? 
                Color(red: 1.0, green: 0.6, blue: 0.2) : // Orange-gold (darker)
                Color(red: 0.9, green: 0.4, blue: 0.0)   // Orange-gold (lighter)
        } else if song.score >= 5.0 {
            return colorScheme == .dark ? 
                Color(red: 0.0, green: 0.9, blue: 0.9) : // Teal (darker)
                Color(red: 0.0, green: 0.7, blue: 0.7)   // Teal (lighter)
        } else if song.score >= 3.0 {
            return colorScheme == .dark ? 
                Color(red: 0.5, green: 0.5, blue: 1.0) : // Blue-purple (darker)
                Color(red: 0.4, green: 0.4, blue: 0.9)   // Blue-purple (lighter)
        } else {
            return Color(.systemGray)  // System gray - adapts to mode
        }
    }
    
    // Get sentiment-appropriate color based on mode
    private var sentimentColor: Color {
        colorScheme == .dark ? song.sentiment.darkModeColor : song.sentiment.lightModeColor
    }
    
    var body: some View {
        HStack(spacing: 12) {
            // Rank and score circle with glassmorphic effect
            ZStack {
                // Score progress ring
                Circle()
                    .trim(from: 0, to: CGFloat(song.score / 10.0))
                    .stroke(scoreColor, style: StrokeStyle(lineWidth: 2, lineCap: .round))
                    .frame(width: 46, height: 46)
                    .rotationEffect(.degrees(-90))
                
                // Glassmorphic background
                Circle()
                    .fill(Color(.systemBackground).opacity(0.7))
                    .frame(width: 40, height: 40)
                    .overlay(
                        Circle()
                            .strokeBorder(
                                LinearGradient(
                                    gradient: Gradient(colors: [
                                        Color.white.opacity(0.6),
                                        Color.white.opacity(0.2)
                                    ]),
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                lineWidth: 0.5
                            )
                    )
                    .shadow(color: Color(.sRGBLinear, white: 0, opacity: 0.1), radius: 2)
                
                // Content
                VStack(spacing: -1) {
                    // Sentiment icon
                    Image(systemName: song.sentiment.icon)
                        .font(.system(size: 10))
                        .foregroundColor(sentimentColor)
                    
                    // Rank number
                    Text("#\(rank)")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(Color(.label))
                        .minimumScaleFactor(0.8)
                    
                    // Score
                    Text(String(format: "%.1f", song.score))
                        .font(.system(size: 9, weight: .medium))
                        .foregroundColor(scoreColor)
                }
            }
            
            // Album art with glassmorphic effect
            RemoteArtworkView(
                artworkURL: song.artworkURL,
                placeholderText: song.albumArt,
                cornerRadius: 10,
                size: CGSize(width: 54, height: 54),
                glassmorphic: true
            )
            .shadow(color: Color(.sRGBLinear, white: 0, opacity: 0.1), radius: 3)
            
            // Song details
            VStack(alignment: .leading, spacing: 3) {
                Text(song.title)
                    .font(.headline)
                    .foregroundColor(Color(.label))
                    .lineLimit(1)
                
                Text(song.artist)
                    .font(.subheadline)
                    .foregroundColor(Color(.secondaryLabel))
                    .lineLimit(1)
                
                // Sentiment indicator with glassmorphic style
                HStack(spacing: 4) {
                    // Small pill-shaped tag
                    HStack(spacing: 4) {
                        Image(systemName: song.sentiment.icon)
                            .font(.system(size: 9))
                        
                        Text(song.sentiment.rawValue)
                            .font(.system(size: 9, weight: .medium))
                    }
                    .foregroundColor(colorScheme == .dark ? sentimentColor : sentimentColor.opacity(0.8))
                    .padding(.horizontal, 6)
                    .padding(.vertical, 3)
                    .background(
                        Capsule()
                            .fill(sentimentColor.opacity(colorScheme == .dark ? 0.2 : 0.1))
                            .overlay(
                                Capsule()
                                    .strokeBorder(
                                        sentimentColor.opacity(colorScheme == .dark ? 0.4 : 0.3),
                                        lineWidth: 0.5
                                    )
                            )
                    )
                }
            }
            
            Spacer()
        }
        .padding(12)
        .background(
            ZStack {
                // Main background
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color(.systemBackground).opacity(0.7))
                
                // Glassmorphic blur
                VisualEffectBlur(
                    blurStyle: colorScheme == .dark ? .systemThinMaterialDark : .systemThinMaterial
                )
                .clipShape(RoundedRectangle(cornerRadius: 16))
                
                // Border gradient
                RoundedRectangle(cornerRadius: 16)
                    .strokeBorder(
                        LinearGradient(
                            gradient: Gradient(colors: [
                                Color.white.opacity(colorScheme == .dark ? 0.5 : 0.7),
                                Color.white.opacity(colorScheme == .dark ? 0.2 : 0.3)
                            ]),
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 0.5
                    )
            }
        )
        .shadow(color: Color(.sRGBLinear, white: 0, opacity: 0.15), radius: 5, y: 2)
        .contentShape(Rectangle())
    }
}
