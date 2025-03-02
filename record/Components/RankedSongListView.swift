//
//  RankedSongListView.swift
//  record
//
//  Created by Nadav Avital on 2/24/25.
//

import SwiftUI

struct RankedSongListView: View {
    @EnvironmentObject var rankingManager: MusicRankingManager
    var filteredSongs: [Song]
    var searchText: String
    var onAddSong: () -> Void
    
    var body: some View {
        List {
            if filteredSongs.isEmpty {
                EmptySongsView(searchText: searchText, onAddSong: onAddSong)
                    .listRowBackground(Color.clear)
                    .listRowInsets(EdgeInsets())
            } else {
                ForEach(filteredSongs) { song in
                    RankedSongRow(
                        rank: (rankingManager.rankedSongs.firstIndex(where: { $0.id == song.id }) ?? -1) + 1,
                        song: song,
                        onDelete: { song in
                            rankingManager.removeSong(song)
                        },
                        onChangeSentiment: { song in
                            rankingManager.addNewSong(song: song)
                        }
                    )
                    .listRowSeparator(.hidden)
                    .listRowBackground(Color.clear)
                }
            }
        }
        .listStyle(.plain)
        .animation(.easeOut(duration: 0.2), value: filteredSongs)
    }
}

#Preview {
    let rankingManager = MusicRankingManager()
    return RankedSongListView(
        filteredSongs: rankingManager.rankedSongs,
        searchText: "",
        onAddSong: {}
    )
    .environmentObject(rankingManager)
}
