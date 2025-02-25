//
//  SongComparisonCard.swift
//  record
//
//  Created by Nadav Avital on 2/24/25.
//

import SwiftUI

struct SongComparisonCard: View {
    let song: Song
    let isNew: Bool
    
    var body: some View {
        VStack {
            // Album art placeholder
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            gradient: Gradient(colors: [
                                isNew ? Color.pink.opacity(0.3) : Color.blue.opacity(0.3),
                                isNew ? Color(red: 0.9, green: 0.3, blue: 0.6).opacity(0.3) : Color(red: 0.3, green: 0.4, blue: 0.9).opacity(0.3)
                            ]),
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 100, height: 100)
                
                if isNew {
                    Circle()
                        .stroke(Color.pink.opacity(0.5), lineWidth: 2)
                        .frame(width: 100, height: 100)
                } else {
                    Circle()
                        .stroke(Color.blue.opacity(0.5), lineWidth: 2)
                        .frame(width: 100, height: 100)
                }
                
                // Vinyl effect
                Circle()
                    .fill(Color.clear)
                    .frame(width: 30, height: 30)
                    .overlay(
                        Circle()
                            .stroke(Color.white.opacity(0.3), lineWidth: 1)
                    )
            }
            
            VStack(spacing: 4) {
                Text(song.title)
                    .font(.headline)
                    .foregroundColor(.white)
                    .multilineTextAlignment(.center)
                
                Text(song.artist)
                    .font(.subheadline)
                    .foregroundColor(.white.opacity(0.7))
                    .multilineTextAlignment(.center)
                
                // Sentiment badge
                HStack {
                    Circle()
                        .fill(song.sentiment.color.opacity(0.3))
                        .frame(width: 8, height: 8)
                    
                    Text(song.sentiment.rawValue)
                        .font(.caption)
                        .foregroundColor(song.sentiment.color.opacity(0.8))
                }
                .padding(.vertical, 5)
            }
        }
        .padding(.vertical)
        .frame(width: 120)
    }
}
