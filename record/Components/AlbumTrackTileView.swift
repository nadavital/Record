//
//  AlbumTrackTileView.swift
//  record
//
//  Created by Nadav Avital on 3/7/25.
//


import SwiftUI
import MusicKit

import SwiftUI

struct AlbumTrackTileView: View {
    let track: Track
    let rankedSong: Song?
    let onRank: () -> Void
    let onSelect: () -> Void
    
    var body: some View {
        Button(action: onSelect) {
            HStack(spacing: 12) {
                Text("\(track.trackNumber ?? 0)")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .frame(width: 30, alignment: .center)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(track.title)
                        .font(.system(size: 16, weight: .medium))
                    Text(track.artistName)
                        .font(.system(size: 14))
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                if let rankedSong = rankedSong {
                    HStack(spacing: 8) {
                        Image(systemName: rankedSong.sentiment.icon)
                            .font(.system(size: 16))
                            .foregroundColor(rankedSong.sentiment.color)
                        Text("#\(rankingManagerRank(for: rankedSong))")
                            .font(.system(size: 16, weight: .bold))
                            .foregroundColor(.accentColor)
                        Text(String(format: "%.1f", rankedSong.score))
                            .font(.system(size: 14))
                            .foregroundColor(.secondary)
                        Button(action: onRank) {
                            Image(systemName: "arrow.counterclockwise.circle.fill")
                                .font(.system(size: 22))
                                .foregroundColor(.accentColor)
                        }
                    }
                } else {
                    Button(action: onRank) {
                        Image(systemName: "plus.circle.fill")
                            .font(.system(size: 22))
                            .foregroundColor(.accentColor)
                    }
                }
            }
            .padding(.vertical, 8)
            .padding(.horizontal, 12)
            .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 12))
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    private func rankingManagerRank(for song: Song) -> Int {
        (rankingManager.rankedSongs.firstIndex(of: song) ?? -1) + 1
    }
    
    @EnvironmentObject private var rankingManager: MusicRankingManager
}
