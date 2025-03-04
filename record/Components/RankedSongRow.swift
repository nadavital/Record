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
    var onDelete: (Song) -> Void
    var onChangeSentiment: (Song) -> Void
    
    @EnvironmentObject private var musicAPI: MusicAPIManager
    @EnvironmentObject private var rankingManager: MusicRankingManager
    
    var body: some View {
        NavigationLink(destination: SongInfoView(rankedSong: song, musicAPI: musicAPI, rankingManager: rankingManager)) {
            HStack {
                RemoteArtworkView(
                    artworkURL: song.artworkURL,
                    placeholderText: song.title,
                    cornerRadius: 6,
                    size: CGSize(width: 40, height: 40)
                )
                .padding(.trailing, 4)
                
                Text("#\(rank)")
                    .foregroundStyle(.secondary)
                    .fontWeight(.medium)
                    .frame(width: 32)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(song.title).font(.body)
                    Text(song.artist).font(.subheadline).foregroundStyle(.secondary)
                }
                Spacer()
                Text(String(format: "%.1f", song.score))
                    .font(.system(.callout, design: .rounded))
                    .fontWeight(.semibold)
                    .foregroundColor(.secondary)
                    .padding(.trailing, 6)
                sentimentIcon
                    .symbolRenderingMode(.palette)
                    .foregroundStyle(color(for: song.sentiment))
            }
            .padding(.vertical, 8)
            .padding(.horizontal)
            .background(Color(UIColor.tertiarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 10))
        }
        .contextMenu {
            Button(role: .destructive) { withAnimation { onDelete(song) } } label: { Label("Delete", systemImage: "trash") }
            Button { onChangeSentiment(song) } label: { Label("Re-rank", systemImage: "arrow.counterclockwise") }
        }
        .swipeActions(edge: .trailing) {
            Button(role: .destructive) { onDelete(song) } label: { Label("Delete", systemImage: "trash") }
            Button { onChangeSentiment(song) } label: { Label("Re-rank", systemImage: "arrow.counterclockwise") }.tint(.blue)
        }
    }
    
    private var sentimentIcon: some View {
        switch song.sentiment {
        case .love: return Image(systemName: "heart.fill")
        case .fine: return Image(systemName: "hand.thumbsup.fill")
        case .dislike: return Image(systemName: "hand.thumbsdown.fill")
        }
    }
    
    private func color(for sentiment: SongSentiment) -> Color {
        switch sentiment {
        case .love: return .pink
        case .fine: return .blue
        case .dislike: return .gray
        }
    }
}

#Preview {
    let rankingManager = MusicRankingManager()
    return RankedSongRow(
        rank: 1,
        song: rankingManager.rankedSongs[0],
        onDelete: { _ in },
        onChangeSentiment: { _ in }
    )
    .environmentObject(MusicAPIManager()) // Added for preview
    .environmentObject(rankingManager)    // Added for preview
}
