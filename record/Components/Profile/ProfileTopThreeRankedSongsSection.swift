//
//  TopSongsSection.swift
//  record
//
//  Created by Nadav Avital on 3/4/25.
//

import SwiftUI
    // Top Songs from rankings section

struct ProfileTopThreeRankedSongsSection: View {
    @EnvironmentObject var rankingManager: MusicRankingManager
    private var topSongs: [Song] {
        return Array(rankingManager.rankedSongs.prefix(3))
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Top Songs")
                    .font(.headline)
                
                Spacer()
            }
            .padding(.horizontal, 4)
            
            if topSongs.isEmpty {
                Text("Add songs to your rankings to display here")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .italic()
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.vertical, 16)
            } else {
                // Songs list - limited to top 3
                VStack(spacing: 12) {
                    ForEach(Array(zip(topSongs.indices, topSongs)), id: \.1.id) { index, song in
                        RankedSongRow(
                            rank: index + 1,
                            song: song,
                            onDelete: { _ in /* No deletion from profile view */ },
                            onChangeSentiment: { _ in /* No sentiment change from profile view */ }
                        )
                    }
                }
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.secondarySystemGroupedBackground))
        )
    }
}

#Preview {
    let rankingManager = MusicRankingManager()
    rankingManager.rankedSongs = [
        Song(id: UUID(), title: "Bohemian Rhapsody", artist: "Queen", albumArt: "A Night at the Opera", sentiment: .love, score: 9.5),
        Song(id: UUID(), title: "Hotel California", artist: "Eagles", albumArt: "Hotel California", sentiment: .love, score: 8.5),
        Song(id: UUID(), title: "Sweet Child O' Mine", artist: "Guns N' Roses", albumArt: "Appetite for Destruction", sentiment: .fine, score: 7.0)
    ]
    return ProfileTopThreeRankedSongsSection()
        .environmentObject(rankingManager)
        .environmentObject(MusicAPIManager())
}
