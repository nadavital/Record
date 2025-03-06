//
//  TopSongsSection.swift
//  record
//
//  Created by Nadav Avital on 3/5/25.
//

import SwiftUI

struct StatsTopSongsSection: View {
    @EnvironmentObject var musicAPI: MusicAPIManager
    @EnvironmentObject var rankingManager: MusicRankingManager
    
    private var listeningHistory: [ListeningHistoryItem] {
        musicAPI.listeningHistory
    }
    
    private var topSongs: [(song: ListeningHistoryItem, count: Int)] {
        let sortedSongs = listeningHistory
            .map { (song: $0, count: $0.playCount) }
            .sorted { $0.count > $1.count }
        return sortedSongs
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Top Songs").font(.headline).fontWeight(.semibold)
                Spacer()
                NavigationLink {
                    TopSongsListView(songs: topSongs)
                } label: {
                    Text("See All").font(.subheadline).foregroundColor(Color.accentColor)
                }
            }
            .padding(.horizontal, 4)
            
            if topSongs.isEmpty {
                Text("No listening data available")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .italic()
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.vertical, 16)
            } else {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 16) {
                        ForEach(topSongs.prefix(10), id: \.song.id) { item in
                            NavigationLink(destination: SongInfoView(mediaItem: item.song.mediaItem, musicAPI: musicAPI, rankingManager: rankingManager)) {
                                StatsSongTile(song: item.song, count: item.count)
                            }
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
    StatsTopSongsSection()
        .environmentObject(MusicAPIManager())
        .environmentObject(MusicRankingManager())
}
