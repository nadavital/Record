//
//  StatsSongTile.swift
//  record
//
//  Created by Nadav Avital on 3/5/25.
//

import SwiftUI
import Foundation
import MediaPlayer

struct StatsSongTile: View {
    @EnvironmentObject private var musicAPI: MusicAPIManager
    let song: ListeningHistoryItem
    let count: Int
    
    var body: some View {
        VStack(alignment: .center, spacing: 8) {
            Group {
                if let artworkImage = musicAPI.getArtworkImage(for: song) {
                    Image(uiImage: artworkImage).resizable().scaledToFill()
                } else {
                    RemoteArtworkView(artworkURL: nil, placeholderText: song.title, size: CGSize(width: 110, height: 110))
                }
            }
            .frame(width: 110, height: 110)
            .cornerRadius(8)
            .shadow(radius: 2)
            
            VStack(spacing: 2) {
                Text(song.title).font(.callout).fontWeight(.medium).lineLimit(1).multilineTextAlignment(.center)
                Text(song.artist).font(.caption).foregroundColor(.secondary).lineLimit(1)
                Text("\(count) plays").font(.caption2).foregroundColor(.secondary).padding(.top, 2)
            }
            .frame(width: 110)
        }
    }
}

#Preview {
    let song = ListeningHistoryItem(id: "",
                                title: "LIFETIMES",
                                artist: "Katy Perry",
                                albumName: "143",
                                artworkID: "",
                                lastPlayedDate: Date.now,
                                playCount: 143,
                                mediaItem: MPMediaItem())
    StatsSongTile(song: song, count: song.playCount)
        .environmentObject(MusicAPIManager())
}
