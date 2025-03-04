//
//  MusicItemTileView.swift
//  record
//
//  Created by Nadav Avital on 2/24/25.
//

import SwiftUI
import MusicKit

struct MusicItemTileView: View {
    var title: String
    var artist: String
    var albumName: String?
    var artworkID: String
    var onSelect: () -> Void
    @ObservedObject var musicAPI = MusicAPIManager()
    
    // Add properties for tracking if a song is already ranked
    var isAlreadyRanked: Bool = false
    var currentRank: Int = 0
    var currentScore: Double = 0.0
    
    var body: some View {
        Button(action: {
            onSelect()
        }) {
            HStack(spacing: 12) {
                // Album art from Apple Music
                RemoteArtworkView(
                    artworkURL: musicAPI.getArtworkURL(for: artworkID),
                    placeholderText: title,
                    size: CGSize(width: 60, height: 60)
                )
                .clipShape(RoundedRectangle(cornerRadius: 6))
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(.system(size: 16, weight: .medium))
                    
                    Text(artist)
                        .font(.system(size: 14))
                        .foregroundColor(Color(.secondaryLabel))
                    
                    if let albumName = albumName, albumName != title {
                        Text(albumName)
                            .font(.system(size: 12))
                            .foregroundColor(Color(.tertiaryLabel))
                    }
                }
                
                Spacer()
                
                // Show ranking information or add button
                if isAlreadyRanked {
                    HStack(spacing: 8) {
                        // Ranking info
                        VStack(alignment: .trailing, spacing: 2) {
                            Text("#\(currentRank)")
                                .font(.system(size: 16, weight: .bold))
                                .foregroundColor(.accentColor)
                            
                            Text(String(format: "%.1f", currentScore))
                                .font(.system(size: 14))
                                .foregroundColor(Color(.secondaryLabel))
                        }
                        
                        // Re-rank button that matches the plus button style
                        Image(systemName: "arrow.counterclockwise.circle.fill")
                            .font(.system(size: 22))
                            .foregroundColor(Color.accentColor)
                    }
                } else {
                    Image(systemName: "plus.circle.fill")
                        .font(.system(size: 22))
                        .foregroundColor(Color.accentColor)
                }
            }
            .padding()
            .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 12))
        }
        .buttonStyle(PlainButtonStyle())
    }
}

#Preview {
    let mockMusicAPI = MusicAPIManager()
    
    VStack(spacing: 20) {
        MusicItemTileView(
            title: "Song Title",
            artist: "Artist Name",
            albumName: "Album Name",
            artworkID: "1234",
            onSelect: {},
            musicAPI: mockMusicAPI
        )
        
        MusicItemTileView(
            title: "Ranked Song",
            artist: "Ranked Artist",
            albumName: "Ranked Album",
            artworkID: "5678",
            onSelect: {},
            musicAPI: mockMusicAPI,
            isAlreadyRanked: true,
            currentRank: 3,
            currentScore: 8.5
        )
    }
    .padding()
}
