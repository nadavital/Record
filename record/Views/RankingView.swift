//
//  RankingView.swift
//  record
//
//  Created by Nadav Avital on 2/24/25.
//

import SwiftUI

struct RankingView: View {
    @EnvironmentObject var rankingManager: MusicRankingManager
    @State private var showAddSongSheet = false
    
    var body: some View {
        ZStack {
            // Background
            Color.black.opacity(0.2).ignoresSafeArea()
            
            VStack {
                // Header
                Text("Your Ranked Songs")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                    .padding()
                
                // Ranked songs list
                ScrollView {
                    VStack(spacing: 10) {
                        ForEach(Array(rankingManager.rankedSongs.enumerated()), id: \.element.id) { index, song in
                            RankedSongRow(rank: index + 1, song: song)
                        }
                    }
                    .padding()
                }
                
                // Add song button
                Button(action: {
                    showAddSongSheet = true
                }) {
                    HStack {
                        Image(systemName: "plus.circle.fill")
                        Text("Add Song")
                    }
                    .font(.headline)
                    .foregroundColor(.white)
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(
                        RoundedRectangle(cornerRadius: 15)
                            .fill(Color(red: 0.94, green: 0.3, blue: 0.9).opacity(0.3))
                            .overlay(
                                RoundedRectangle(cornerRadius: 15)
                                    .stroke(Color(red: 0.94, green: 0.3, blue: 0.9), lineWidth: 1)
                            )
                            .shadow(color: Color(red: 0.94, green: 0.3, blue: 0.9).opacity(0.5), radius: 5)
                    )
                }
                .padding(.horizontal)
                .padding(.bottom, 20)
            }
            
            // Overlays for ranking process
            if rankingManager.showSentimentPicker {
                SentimentPickerView()
                    .transition(.opacity)
                    .zIndex(2)
            }
            
            if rankingManager.showComparison {
                SongComparisonView()
                    .transition(.opacity)
                    .zIndex(3)
            }
        }
        .sheet(isPresented: $showAddSongSheet) {
            AddSongView()
        }
    }
}

#Preview("Ranking View") {
    RankingView()
        .environmentObject(MusicRankingManager())
}
