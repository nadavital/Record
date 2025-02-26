//
//  SentimentPickerView.swift
//  record
//
//  Created by Nadav Avital on 2/24/25.
//

import SwiftUI

struct SentimentPickerView: View {
    @EnvironmentObject var rankingManager: MusicRankingManager
    @Environment(\.colorScheme) private var colorScheme
    
    var body: some View {
        VStack(spacing: 20) {
            // Header
            VStack(spacing: 6) {
                Image(systemName: "music.note")
                    .font(.system(size: 18))
                    .foregroundColor(.accentColor)
                
                Text("How do you feel about this song?")
                    .font(.headline)
            }
            
            // Song info with artwork
            if let song = rankingManager.currentSong {
                VStack(spacing: 12) {
                    // Album artwork
                    CircleRemoteArtworkView(
                        artworkURL: song.artworkURL,
                        placeholderText: song.albumArt,
                        size: 120
                    )
                    
                    // Song title and artist
                    VStack(spacing: 4) {
                        Text(song.title)
                            .font(.headline)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)
                        
                        Text(song.artist)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                }
                .padding(.vertical, 5)
            }
            
            // Sentiment buttons
            VStack(spacing: 12) {
                Text("Select a rating")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                
                HStack(spacing: 16) {
                    ForEach(SongSentiment.allCases, id: \.self) { sentiment in
                        Button(action: {
                            withAnimation(.spring()) {
                                rankingManager.setSentiment(sentiment)
                            }
                        }) {
                            VStack {
                                Image(systemName: sentiment.icon)
                                    .font(.system(size: 22))
                                    .foregroundColor(.accentColor)
                                    .frame(width: 44, height: 44)
                                    .background(Color(.systemGray6))
                                    .clipShape(Circle())
                                
                                Text(sentiment.rawValue)
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                }
            }
            .padding(.vertical, 5)
            
            // Cancel button
            Button("Cancel") {
                withAnimation(.easeOut(duration: 0.2)) {
                    rankingManager.cancelRanking()
                }
            }
            .buttonStyle(.bordered)
            .padding(.top, 5)
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(10)
        .padding()
    }
}
