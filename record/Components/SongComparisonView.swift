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
                HStack {
                    Spacer()
                    // X button in top corner
                    Button(action: {
                        withAnimation(.easeOut(duration: 0.2)) {
                            rankingManager.cancelRanking()
                        }
                    }) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 22))
                            .foregroundStyle(Color(.tertiaryLabel))
                            .padding(5)
                    }
                }
                .padding(.bottom, -20)
                .padding(.top, -10)
                    
                Text("Which song do you prefer?")
                    .font(.headline)
                    .foregroundColor(Color(.label))
                
                // Songs comparison with improved layout
                HStack(alignment: .top, spacing: 15) {
                    // New song with transition
                    if let song = rankingManager.currentSong {
                        SongComparisonTile(song: song)
                            .transition(.opacity)
                            .id("current-\(song.id)")
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
                    
                    // Existing ranked song with transition
                    if let song = rankingManager.comparisonSong {
                        SongComparisonTile(song: song)
                            .transition(.opacity)
                            .id("comparison-\(song.id)")
                    }
                }
                .padding(.horizontal, 20)
                .animation(.easeInOut(duration: 0.2), value: rankingManager.comparisonSong?.id)
                
                // Choice buttons
                VStack(spacing: 12) {
                    HStack() {
                        // Prefer left button
                        Button(action: {
                            withAnimation(.spring()) {
                                rankingManager.comparePreferred(currentSongIsBetter: true)
                            }
                        }) {
                            Image(systemName: "arrow.left")
                                .font(.system(size: 30))
                                .foregroundStyle(Color.accentColor)
                                .bold()
                                .padding()
                                .background(.ultraThinMaterial)
                                .clipShape(Circle())
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
                            Image(systemName: "equal")
                                .font(.system(size: 15))
                                .foregroundStyle(Color.accentColor)
                                .bold()
                                .padding()
                                .background(.ultraThinMaterial)
                                .clipShape(Circle())
                        }
                        
                        // Prefer right button
                        Button(action: {
                            withAnimation(.spring()) {
                                rankingManager.comparePreferred(currentSongIsBetter: false)
                            }
                        }) {
                            Image(systemName: "arrow.right")
                                .font(.system(size: 30))
                                .foregroundStyle(Color.accentColor)
                                .bold()
                                .padding()
                                .background(.ultraThinMaterial)
                                .clipShape(Circle())
                        }
                    }
                    
                }
                .padding(.top, 5)
            }
            .padding(24)
            .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16))
            .shadow(color: Color(.sRGBLinear, white: 0, opacity: 0.2), radius: 15)
            .frame(maxWidth: 350)
        }
    }
}

#Preview("Song Comparison View") {
    let manager = MusicRankingManager()
    
    manager.currentSong = Song(title: "No Tears Left to Cry", artist: "Ariana Grande", albumArt: "sweetener", sentiment: .love)
    
    manager.comparisonSong = Song(title: "Good 4 U", artist: "Olivia Rodrigo", albumArt: "good_4_u", sentiment: .fine)
    
    return (
        SongComparisonView()
        .environmentObject(manager)
    )
}
