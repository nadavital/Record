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
        ZStack {
            // Card content
            VStack(spacing: 24) {
                // Header
                VStack(spacing: 8) {
                    Image(systemName: "music.note")
                        .font(.system(size: 18))
                        .foregroundColor(Color.accentColor)
                    
                    Text("How do you feel about this song?")
                        .font(.headline)
                        .foregroundColor(Color(.label))
                }
                
                // Song info with artwork
                if let song = rankingManager.currentSong {
                    VStack(spacing: 14) {
                        // Album artwork
                        CircleRemoteArtworkView(
                            artworkURL: song.artworkURL,
                            placeholderText: song.albumArt,
                            size: 120
                        )
                        .shadow(radius: 3)
                        
                        // Song title and artist
                        VStack(spacing: 4) {
                            Text(song.title)
                                .font(.title3)
                                .fontWeight(.bold)
                                .foregroundColor(Color(.label))
                                .multilineTextAlignment(.center)
                                .padding(.horizontal)
                            
                            Text(song.artist)
                                .font(.subheadline)
                                .foregroundColor(Color(.secondaryLabel))
                        }
                    }
                    .padding(.vertical, 10)
                }
                
                // Sentiment buttons in a grid
                VStack(spacing: 16) {
                    Text("Select a rating")
                        .font(.subheadline)
                        .foregroundColor(Color(.secondaryLabel))
                    
                    HStack(spacing: 20) {
                        ForEach(SongSentiment.allCases.filter { $0 != .neutral }, id: \.self) { sentiment in
                            Button(action: {
                                withAnimation(.spring()) {
                                    rankingManager.setSentiment(sentiment)
                                }
                            }) {
                                VStack(spacing: 8) {
                                    // Icon in a circle with adaptive colors
                                    ZStack {
                                        Circle()
                                            .fill(
                                                colorScheme == .dark ? 
                                                    sentiment.darkModeColor.opacity(0.2) : 
                                                    sentiment.lightModeColor.opacity(0.15)
                                            )
                                            .frame(width: 60, height: 60)
                                        
                                        Image(systemName: sentiment.icon)
                                            .font(.system(size: 26))
                                            .foregroundColor(
                                                colorScheme == .dark ? 
                                                    sentiment.darkModeColor : 
                                                    sentiment.lightModeColor
                                            )
                                    }
                                    
                                    // Label
                                    Text(sentiment.rawValue)
                                        .font(.caption)
                                        .fontWeight(.medium)
                                        .foregroundColor(Color(.secondaryLabel))
                                }
                                .frame(width: 70)
                            }
                            .buttonStyle(PlainButtonStyle())
                        }
                    }
                }
                .padding(.vertical, 10)
                
                // Cancel button in standard iOS style
                Button(action: {
                    withAnimation(.easeOut(duration: 0.2)) {
                        rankingManager.cancelRanking()
                    }
                }) {
                    Text("Cancel")
                        .foregroundColor(.accentColor)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(
                            RoundedRectangle(cornerRadius: 10)
                                .fill(Color(.systemBackground))
                                .shadow(color: Color(.systemGray4).opacity(0.3), radius: 2, y: 1)
                        )
                }
                .padding(.top, 10)
            }
            .padding(24)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color(.systemGroupedBackground))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(Color(.separator).opacity(0.3), lineWidth: 0.5)
            )
            .shadow(color: Color(.sRGBLinear, white: 0, opacity: 0.2), radius: 15)
            .frame(maxWidth: 350)
        }
    }
}
