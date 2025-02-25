//
//  SentimentPickerView.swift
//  record
//
//  Created by Nadav Avital on 2/24/25.
//

import SwiftUI

struct SentimentPickerView: View {
    @EnvironmentObject var rankingManager: MusicRankingManager
    
    var body: some View {
        ZStack {
            // Dim background
            Color.black.opacity(0.7)
                .edgesIgnoringSafeArea(.all)
            
            // Glass card
            VStack(spacing: 20) {
                // Current song info
                if let song = rankingManager.currentSong {
                    Text("How do you feel about")
                        .font(.headline)
                        .foregroundColor(.white.opacity(0.8))
                    
                    Text("\"\(song.title)\"")
                        .font(.title)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                        .multilineTextAlignment(.center)
                    
                    Text("by \(song.artist)")
                        .font(.subheadline)
                        .foregroundColor(.white.opacity(0.8))
                }
                
                // Album art placeholder
                Circle()
                    .fill(
                        LinearGradient(
                            gradient: Gradient(colors: [
                                Color(red: 0.94, green: 0.3, blue: 0.9).opacity(0.3), 
                                Color(red: 0.4, green: 0.2, blue: 0.9).opacity(0.3)
                            ]), 
                            startPoint: .topLeading, 
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 150, height: 150)
                    .overlay(
                        Circle()
                            .stroke(Color.white.opacity(0.2), lineWidth: 1)
                    )
                    .shadow(color: Color(red: 0.94, green: 0.3, blue: 0.9).opacity(0.5), radius: 10)
                
                // Sentiment buttons
                VStack(spacing: 15) {
                    ForEach(SongSentiment.allCases.filter { $0 != .neutral }, id: \.self) { sentiment in
                        Button(action: {
                            rankingManager.setSentiment(sentiment)
                        }) {
                            Text(sentiment.rawValue)
                                .font(.headline)
                                .foregroundColor(.white)
                                .padding()
                                .frame(maxWidth: .infinity)
                                .background(
                                    RoundedRectangle(cornerRadius: 15)
                                        .fill(sentiment.color.opacity(0.2))
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 15)
                                                .stroke(sentiment.color.opacity(0.5), lineWidth: 1)
                                        )
                                )
                                .shadow(color: sentiment.color.opacity(0.3), radius: 5)
                        }
                    }
                }
                .padding(.horizontal)
                
                // Cancel button
                Button("Cancel") {
                    rankingManager.finishRanking()
                }
                .foregroundColor(.white.opacity(0.6))
                .padding()
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
