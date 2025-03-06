//
//  StatsTopAlbumsSection.swift
//  record
//
//  Created by Nadav Avital on 3/5/25.
//

import SwiftUI

struct StatsTopAlbumsSection: View {
    @EnvironmentObject var musicAPI: MusicAPIManager
    
    // Derived statistics
    private var listeningHistory: [ListeningHistoryItem] {
        musicAPI.listeningHistory
    }
    
    private var topAlbums: [(album: String, artist: String, count: Int)] {
        let albumCounts = Dictionary(grouping: listeningHistory, by: { "\($0.albumName)||\($0.artist)" })
            .map { key, value in
                let components = key.components(separatedBy: "||")
                return (
                    album: components.first ?? "",
                    artist: components.last ?? "",
                    count: value.reduce(0) { $0 + $1.playCount }
                )
            }
            .filter { !$0.album.isEmpty }
            .sorted { $0.count > $1.count }
        return albumCounts
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Top Albums").font(.headline).fontWeight(.semibold)
                Spacer()
                NavigationLink {
                    TopAlbumsListView(albums: topAlbums)
                } label: {
                    Text("See All").font(.subheadline).foregroundColor(Color.accentColor)
                }
            }
            .padding(.horizontal, 4)
            
            if topAlbums.isEmpty {
                Text("No album data available")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .italic()
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.vertical, 16)
            } else {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 16) {
                        ForEach(topAlbums.prefix(10), id: \.album) { item in
                            StatsAlbumTile(album: item.album, artist: item.artist, count: item.count)
                        }
                    }
                    .padding(.horizontal, 4)
                    .padding(.vertical, 8)
                }
            }
        }
        .padding()
        .background(RoundedRectangle(cornerRadius: 16).fill(Color(.secondarySystemGroupedBackground)))
    }
}

#Preview {
    StatsTopAlbumsSection()
        .environmentObject(MusicAPIManager())
}
