//
//  StatsArtistTile.swift
//  record
//
//  Created by Nadav Avital on 3/5/25.
//

import SwiftUI

struct StatsArtistTile: View {
    @EnvironmentObject var musicAPI: MusicAPIManager
    let artist: String
    let count: Int
    var body: some View {
        VStack(alignment: .center, spacing: 8) {
            Group {
                if let artworkURL = musicAPI.getArtworkURL(for: artist) {
                    AsyncImage(url: artworkURL)
                } else {
                    RemoteArtworkView(artworkURL: nil, placeholderText: artist, size: CGSize(width: 90, height: 90))
                }
            }
            .frame(width: 90, height: 90)
            .clipShape(Circle())
            .shadow(radius: 2)
            
            VStack(spacing: 2) {
                Text(artist).font(.callout).fontWeight(.medium).lineLimit(1).multilineTextAlignment(.center)
                Text("\(count) plays").font(.caption2).foregroundColor(.secondary).padding(.top, 2)
            }
            .frame(width: 100)
        }
    }
}

#Preview {
    StatsArtistTile(artist: "Taylor Swift", count: 1989)
        .environmentObject(MusicAPIManager())
}
