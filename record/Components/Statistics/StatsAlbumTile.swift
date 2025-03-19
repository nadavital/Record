//
//  StatsAlbumView.swift
//  record
//
//  Created by Nadav Avital on 3/5/25.
//

import SwiftUI
import MediaPlayer

struct StatsAlbumTile: View {
    @EnvironmentObject var mediaPlayerManager: MediaPlayerManager
    let album: String
    let artist: String
    let count: Int
    var body: some View {
        VStack(alignment: .center, spacing: 8) {
            Group {
                if let artworkURL = mediaPlayerManager.topAlbums.first(where: { $0.representativeItem?.albumTitle == album && $0.representativeItem?.artist == artist })?.representativeItem?.artwork?.image(at: CGSize(width: 110, height: 110)) {
                    Image(uiImage: artworkURL).resizable().scaledToFill()
                } else {
                    RemoteArtworkView(artworkURL: nil, placeholderText: album, size: CGSize(width: 110, height: 110))
                }
            }
            .frame(width: 110, height: 110)
            .cornerRadius(8)
            .shadow(radius: 2)
            
            VStack(spacing: 2) {
                Text(album).font(.callout).fontWeight(.medium).lineLimit(1).multilineTextAlignment(.center)
                Text(artist).font(.caption).foregroundColor(.secondary).lineLimit(1)
                Text("\(count) plays").font(.caption2).foregroundColor(.secondary).padding(.top, 2)
            }
            .frame(width: 110)
        }
    }
}

#Preview {
    StatsAlbumTile(album: "Sweetener", artist: "Ariana Grande", count: 999)
        .environmentObject(MediaPlayerManager())
}
