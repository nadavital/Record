//
//  StatsTopArtistsSection.swift
//  record
//
//  Created by Nadav Avital on 3/5/25.
//

import SwiftUI
import MediaPlayer

struct StatsTopArtistsSection: View {
    @EnvironmentObject var mediaPlayerManager: MediaPlayerManager
    
    var artistsWithCounts: [(artist: MPMediaItemCollection, count: Int)] {
        return mediaPlayerManager.topArtists.map { collection in
            let totalPlays = collection.items.reduce(0) { $0 + $1.playCount }
            return (artist: collection, count: totalPlays)
        }
    }
    
    // Convert the data to the format expected by TopArtistsListView
    var artistsList: [(artist: String, count: Int)] {
        return artistsWithCounts.map { item in
            return (artist: item.artist.representativeItem?.artist ?? "", count: item.count)
        }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Top Artists").font(.headline).fontWeight(.semibold)
                Spacer()
                NavigationLink(destination: TopArtistsListView(artists: artistsList)) {
                    Text("See All")
                        .font(.subheadline)
                        .foregroundColor(.accentColor)
                }
            }
            .padding(.horizontal, 4)
            
            if artistsWithCounts.isEmpty {
                Text("No artist data available")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .italic()
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.vertical, 16)
            } else {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 16) {
                        ForEach(artistsWithCounts.prefix(10), id: \.artist.representativeItem?.artist) { item in
                            StatsArtistTile(
                                artist: item.artist.representativeItem?.artist ?? "", 
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
    StatsTopArtistsSection()
        .environmentObject(MediaPlayerManager())
}
