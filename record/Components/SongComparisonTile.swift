//
//  SongComparisonTile.swift
//  record
//
//  Created by Nadav Avital on 2/25/25.
//

import SwiftUI

struct SongComparisonTile: View {
    let song: Song
    var body: some View {
        VStack {
            RemoteArtworkView(
                artworkURL: song.artworkURL,
                placeholderText: song.albumArt,
                size: CGSize(width: 90, height: 90)
            )
            .shadow(radius: 3)
            .id(song.id)
            
            Text(song.title)
                .font(.callout)
                .fontWeight(.medium)
                .foregroundColor(Color(.label))
                .lineLimit(2)
                .frame(width: 100)
                .multilineTextAlignment(.center)
            
            Text(song.artist)
                .font(.caption)
                .foregroundColor(Color(.secondaryLabel))
                .lineLimit(1)
                .frame(width: 100)
                .multilineTextAlignment(.center)
        }
    }
}

#Preview("Song Comparison Tile") {
    
    var currentSong = Song(title: "No Tears Left to Cry",
                           artist: "Ariana Grande",
                           albumArt: "sweetener",
                           sentiment: .love)
    
    SongComparisonTile(song: currentSong)
}
