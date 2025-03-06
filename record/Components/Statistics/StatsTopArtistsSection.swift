//
//  StatsTopArtistsSection.swift
//  record
//
//  Created by Nadav Avital on 3/5/25.
//

import SwiftUI

struct StatsTopArtistsSection: View {
    @EnvironmentObject var musicAPI: MusicAPIManager
    
    private var listeningHistory: [ListeningHistoryItem] {
        musicAPI.listeningHistory
    }
    
    private var topArtists: [(artist: String, count: Int)] {
        let artistCounts = Dictionary(grouping: listeningHistory, by: { $0.artist })
            .map { (artist: $0.key, count: $0.value.reduce(0) { $0 + $1.playCount }) }
            .sorted { $0.count > $1.count }
        return artistCounts
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Top Artists").font(.headline).fontWeight(.semibold)
                Spacer()
                NavigationLink {
                    TopArtistsListView(artists: topArtists)
                } label: {
                    Text("See All").font(.subheadline).foregroundColor(Color.accentColor)
                }
            }
            .padding(.horizontal, 4)
            
            if topArtists.isEmpty {
                Text("No artist data available")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .italic()
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.vertical, 16)
            } else {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 16) {
                        ForEach(topArtists.prefix(10), id: \.artist) { item in
                            StatsArtistTile(artist: item.artist, count: item.count)
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
        .environmentObject(MusicAPIManager())
}
