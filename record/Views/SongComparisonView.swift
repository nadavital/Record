//
//  SongComparisonView.swift
//  record
//
//  Created by Nadav Avital on 2/24/25.
//

import SwiftUI

struct SongComparisonView: View {
    @EnvironmentObject var rankingManager: MusicRankingManager
    @Environment(\.colorScheme) private var colorScheme
    
    var body: some View {
        ZStack {
            // Card content
            VStack(spacing: 20) {
                // Header
                VStack(spacing: 8) {
                    Image(systemName: "arrow.up.arrow.down")
                        .font(.system(size: 18))
                        .foregroundColor(Color.accentColor)
                    
                    Text("Which song do you prefer?")
                        .font(.headline)
                        .foregroundColor(Color(.label))
                }
                
                // Songs comparison with improved layout
                HStack(alignment: .top, spacing: 15) {
                    // New song
                    if let song = rankingManager.currentSong {
                        VStack {
                            CircleRemoteArtworkView(
                                artworkURL: song.artworkURL,
                                placeholderText: song.albumArt,
                                size: 90
                            )
                            .overlay(
                                Circle()
                                    .stroke(Color.accentColor, lineWidth: 2)
                                    .opacity(0.7)
                            )
                            .shadow(radius: 3)
                            
                            Text(song.title)
                                .font(.callout)
                                .fontWeight(.medium)
                                .foregroundColor(Color(.label))
                                .lineLimit(1)
                                .frame(width: 100)
                                .multilineTextAlignment(.center)
                            
                            Text(song.artist)
                                .font(.caption)
                                .foregroundColor(Color(.secondaryLabel))
                                .lineLimit(1)
                                .frame(width: 100)
                                .multilineTextAlignment(.center)
                        }
                    }
                    
                    VStack {
                        Image(systemName: "arrow.left.arrow.right")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(Color(.tertiaryLabel))
                        
                        Text("VS")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundColor(Color(.tertiaryLabel))
                    }
                    .padding(.top, 30)
                    
                    // Existing ranked song
                    if let song = rankingManager.comparisonSong {
                        VStack {
                            CircleRemoteArtworkView(
                                artworkURL: song.artworkURL,
                                placeholderText: song.albumArt,
                                size: 90
                            )
                            .overlay(
                                Circle()
                                    .stroke(Color.blue, lineWidth: 2)
                                    .opacity(0.7)
                            )
                            .shadow(radius: 3)
                            
                            Text(song.title)
                                .font(.callout)
                                .fontWeight(.medium)
                                .foregroundColor(Color(.label))
                                .lineLimit(1)
                                .frame(width: 100)
                                .multilineTextAlignment(.center)
                            
                            Text(song.artist)
                                .font(.caption)
                                .foregroundColor(Color(.secondaryLabel))
                                .lineLimit(1)
                                .frame(width: 100)
                                .multilineTextAlignment(.center)
                        }
                    }
                }
                .padding(.vertical, 10)
                
                // Choice buttons
                VStack(spacing: 12) {
                    Text("Make your choice:")
                        .font(.subheadline)
                        .foregroundColor(Color(.secondaryLabel))
                    
                    // Prefer left button
                    Button(action: {
                        withAnimation(.spring()) {
                            rankingManager.comparePreferred(currentSongIsBetter: true)
                        }
                    }) {
                        HStack {
                            Image(systemName: "arrow.left")
                                .font(.system(size: 14))
                            Text("Prefer Left Song")
                            Spacer()
                        }
                        .padding(.horizontal)
                        .padding(.vertical, 14)
                        .foregroundColor(.white)
                        .background(Color.accentColor)
                        .cornerRadius(10)
                    }
                    
                    // Prefer right button
                    Button(action: {
                        withAnimation(.spring()) {
                            rankingManager.comparePreferred(currentSongIsBetter: false)
                        }
                    }) {
                        HStack {
                            Spacer()
                            Text("Prefer Right Song")
                            Image(systemName: "arrow.right")
                                .font(.system(size: 14))
                        }
                        .padding(.horizontal)
                        .padding(.vertical, 14)
                        .foregroundColor(.white)
                        .background(Color.blue)
                        .cornerRadius(10)
                    }
                    
                    // Too close button with a more subtle design
                    Button(action: {
                        withAnimation(.spring()) {
                            if let currentScore = rankingManager.currentSong?.score, 
                               let comparisonScore = rankingManager.comparisonSong?.score {
                                rankingManager.comparePreferred(
                                    currentSongIsBetter: currentScore >= comparisonScore,
                                    tooClose: true
                                )
                            } else {
                                rankingManager.comparePreferred(currentSongIsBetter: true, tooClose: true)
                            }
                        }
                    }) {
                        HStack {
                            Image(systemName: "equal.circle")
                                .font(.system(size: 14))
                            Text("They're too similar")
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .foregroundColor(Color(.secondaryLabel))
                        .background(Color(.tertiarySystemBackground))
                        .cornerRadius(10)
                        .overlay(
                            RoundedRectangle(cornerRadius: 10)
                                .stroke(Color(.systemGray4), lineWidth: 1)
                        )
                    }
                }
                .padding(.top, 5)
                
                // Cancel button in standard iOS style
                Button(action: {
                    withAnimation(.easeOut(duration: 0.2)) {
                        rankingManager.cancelRanking()
                    }
                }) {
                    Text("Cancel")
                        .foregroundColor(.red)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(
                            RoundedRectangle(cornerRadius: 10)
                                .fill(Color(.systemBackground))
                                .shadow(color: Color(.systemGray4).opacity(0.3), radius: 2, y: 1)
                        )
                }
                .padding(.top, 8)
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
