//
//  SongComparisonView.swift
//  record
//
//  Created by Nadav Avital on 2/24/25.
//

import SwiftUI

struct SongComparisonView: View {
    @EnvironmentObject var rankingManager: MusicRankingManager
    
    var body: some View {
        ZStack {
            // Dim background
            Color.black.opacity(0.7)
                .edgesIgnoringSafeArea(.all)
            
            // Comparison card
            VStack(spacing: 25) {
                Text("Which song do you prefer?")
                    .font(.title3)
                    .fontWeight(.semibold)
                    .foregroundColor(.white)
                
                // Songs comparison
                HStack(spacing: 30) {
                    // New song
                    if let song = rankingManager.currentSong {
                        SongComparisonCard(song: song, isNew: true)
                    }
                    
                    Text("OR")
                        .font(.headline)
                        .foregroundColor(.white.opacity(0.6))
                    
                    // Existing ranked song
                    if let song = rankingManager.comparisonSong {
                        SongComparisonCard(song: song, isNew: false)
                    }
                }
                
                // Comparison buttons
                HStack(spacing: 20) {
                    // Prefer left (new song)
                    Button(action: {
                        rankingManager.comparePreferred(currentSongIsBetter: true)
                    }) {
                        HStack {
                            Image(systemName: "arrow.left")
                            Text("This One")
                        }
                        .fontWeight(.semibold)
                        .foregroundColor(.white)
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(
                            RoundedRectangle(cornerRadius: 15)
                                .fill(Color.pink.opacity(0.3))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 15)
                                        .stroke(Color.pink.opacity(0.5), lineWidth: 1)
                                )
                        )
                    }
                    
                    // Prefer right (existing song)
                    Button(action: {
                        rankingManager.comparePreferred(currentSongIsBetter: false)
                    }) {
                        HStack {
                            Text("That One")
                            Image(systemName: "arrow.right")
                        }
                        .fontWeight(.semibold)
                        .foregroundColor(.white)
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(
                            RoundedRectangle(cornerRadius: 15)
                                .fill(Color.blue.opacity(0.3))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 15)
                                        .stroke(Color.blue.opacity(0.5), lineWidth: 1)
                                )
                        )
                    }
                }
                
                // Cancel button
                Button("Cancel") {
                    rankingManager.finishRanking()
                }
                .foregroundColor(.white.opacity(0.6))
                .padding(.top)
            }
            .padding(30)
            .background(
                RoundedRectangle(cornerRadius: 25)
                    .fill(Color.black.opacity(0.5))
                    .background(
                        VisualEffectBlur(blurStyle: .systemUltraThinMaterialDark)
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 25)
                            .stroke(
                                LinearGradient(
                                    gradient: Gradient(colors: [
                                        Color.white.opacity(0.3),
                                        Color.white.opacity(0.1)
                                    ]),
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                lineWidth: 1
                            )
                    )
            )
            .shadow(color: Color(red: 0.94, green: 0.3, blue: 0.9).opacity(0.3), radius: 20)
            .frame(maxWidth: 350)
            .padding()
        }
    }
}
