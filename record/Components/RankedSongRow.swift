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
    
    var body: some View {
        HStack(spacing: 15) {
            // Rank number
            Text("\(rank)")
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(.white)
                .frame(width: 35, height: 35)
                .background(
                    Circle()
                        .fill(Color.black.opacity(0.3))
                        .overlay(
                            Circle()
                                .stroke(song.sentiment.color, lineWidth: 1.5)
                        )
                )
            
            // Album art
            RoundedRectangle(cornerRadius: 8)
                .fill(Color.gray.opacity(0.3))
                .frame(width: 50, height: 50)
                .overlay(
                    Text(song.albumArt.prefix(1))
                        .foregroundColor(.white)
                )
            
            // Song details
            VStack(alignment: .leading) {
                Text(song.title)
                    .font(.headline)
                    .foregroundColor(.white)
                Text(song.artist)
                    .font(.subheadline)
                    .foregroundColor(.white.opacity(0.8))
            }
            
            Spacer()
            
            // Sentiment indicator
            Circle()
                .fill(song.sentiment.color.opacity(0.3))
                .frame(width: 12, height: 12)
                .overlay(
                    Circle()
                        .stroke(song.sentiment.color, lineWidth: 1)
                )
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 15)
                .fill(Color.white.opacity(0.05))
                .overlay(
                    RoundedRectangle(cornerRadius: 15)
                        .stroke(Color.white.opacity(0.1), lineWidth: 0.5)
                )
        )
        .shadow(color: song.sentiment.color.opacity(0.1), radius: 5)
    }
}
