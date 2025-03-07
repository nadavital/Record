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
            VStack(spacing: 20) {
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
                
                // Header
                Text("How do you feel about this song?")
                    .font(.headline)
                
                // Song info with artwork
                if let song = rankingManager.currentSong {
                    SongComparisonTile(song: song)
                }
                
                // Sentiment buttons
                VStack(spacing: 12) {
                    
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
                                        .foregroundColor(sentiment.color)
                                        .frame(width: 44, height: 44)
                                        .background(.ultraThinMaterial)
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
            }
            .padding(24)
            .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16))
            .shadow(color: Color(.sRGBLinear, white: 0, opacity: 0.2), radius: 15)
            .frame(maxWidth: 350)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
        .padding()
    }
}

#Preview("Sentiment Picker View") {
    let manager = MusicRankingManager()
    
    manager.currentSong = Song(title: "No Tears Left to Cry", artist: "Ariana Grande", albumArt: "sweetener", sentiment: .love)
    
    return (
        SentimentPickerView()
        .environmentObject(manager)
    )
}
