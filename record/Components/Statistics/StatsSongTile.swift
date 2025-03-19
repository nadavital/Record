//
//  StatsSongTile.swift
//  record
//
//  Created by Nadav Avital on 3/5/25.
//

import SwiftUI
import MediaPlayer

struct StatsSongTile: View {
    @EnvironmentObject private var mediaPlayerManager: MediaPlayerManager
    let song: MPMediaItem
    let count: Int
    
    var body: some View {
        VStack(alignment: .center, spacing: 8) {
            Group {
                if let artwork = song.artwork?.image(at: CGSize(width: 110, height: 110)) {
                    Image(uiImage: artwork).resizable().scaledToFill()
                } else {
                    RemoteArtworkView(artworkURL: nil, placeholderText: song.title ?? "", size: CGSize(width: 110, height: 110))
                }
            }
            .frame(width: 110, height: 110)
            .cornerRadius(8)
            .shadow(radius: 2)
            
            VStack(spacing: 2) {
                Text(song.title ?? "").font(.callout).fontWeight(.medium).lineLimit(1).multilineTextAlignment(.center)
                Text(song.artist ?? "").font(.caption).foregroundColor(.secondary).lineLimit(1)
                Text("\(count) plays").font(.caption2).foregroundColor(.secondary).padding(.top, 2)
            }
            .frame(width: 110)
        }
    }
}

#Preview {
    let song = MPMediaItem()
    return StatsSongTile(song: song, count: 143)
        .environmentObject(MediaPlayerManager())
}
