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
                
                Image(systemName: "plus.circle.fill")
                    .font(.system(size: 22))
                    .foregroundColor(Color.accentColor)
            }
            .padding()
            .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 12))
        }
        .buttonStyle(PlainButtonStyle())
    }
}

#Preview {
    let mockMusicAPI = MusicAPIManager()
    
    MusicItemTileView(
        title: "Album Title",
        artist: "Artist Name",
        albumName: "Album Name",
        artworkID: "1234",
        onSelect: {},
        musicAPI: mockMusicAPI
    )
    .padding()
    .sizeThatFits
}
