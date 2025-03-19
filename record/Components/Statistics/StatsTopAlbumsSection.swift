//
//  StatsTopAlbumsSection.swift
//  record
//
//  Created by Nadav Avital on 3/5/25.
//

import SwiftUI
import MediaPlayer

struct StatsTopAlbumsSection: View {
    @EnvironmentObject var mediaPlayerManager: MediaPlayerManager
    
    var albumsWithCounts: [(album: MPMediaItemCollection, count: Int)] {
        return mediaPlayerManager.topAlbums.map { collection in
            let totalPlays = collection.items.reduce(0) { $0 + $1.playCount }
            return (album: collection, count: totalPlays)
        }
    }
    
    // Convert the data to the format expected by TopAlbumsListView
    var albumsList: [(album: String, artist: String, count: Int)] {
        return albumsWithCounts.map { item in
            return (
                album: item.album.representativeItem?.albumTitle ?? "",
                artist: item.album.representativeItem?.artist ?? "",
                count: item.count
            )
        }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Top Albums").font(.headline).fontWeight(.semibold)
                Spacer()
                NavigationLink(destination: TopAlbumsListView(albums: albumsList)) {
                    Text("See All")
                        .font(.subheadline)
                        .foregroundColor(.accentColor)
                }
            }
            .padding(.horizontal, 4)
            
            if albumsWithCounts.isEmpty {
                Text("No album data available")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .italic()
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.vertical, 16)
            } else {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 16) {
                        ForEach(albumsWithCounts.prefix(10), id: \.album.representativeItem?.albumTitle) { item in
                            StatsAlbumTile(
                                album: item.album.representativeItem?.albumTitle ?? "", 
                                artist: item.album.representativeItem?.artist ?? "", 
                                count: item.count
                            )
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
        .environmentObject(MediaPlayerManager())
}
