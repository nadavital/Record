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
        ScrollView(showsIndicators: false) {
            VStack(spacing: 0) {
                if filteredSongs.isEmpty {
                    EmptySongsView(searchText: searchText, onAddSong: onAddSong)
                        .listRowBackground(Color.clear)
                        .listRowInsets(EdgeInsets())
                } else {
                    ForEach(filteredSongs) { song in
                        VStack(spacing: 0) {
                            RankedSongRow(
                                rank: (rankingManager.rankedSongs.firstIndex(where: { $0.id == song.id }) ?? -1) + 1,
                                song: song,
                                onDelete: { song in
                                    withAnimation {
                                        rankingManager.removeSong(song)
                                    }
                                },
                                onChangeSentiment: { song in
                                    rankingManager.addNewSong(song: song)
                                }
                            )
                            .padding(.horizontal)
                            
                            if song.id != filteredSongs.last?.id {
                                Divider()
                                    .padding(.leading)
                            }
                        }
                        .background(Color(UIColor.systemBackground))
                    }
                    
                    // Padding at the bottom for now playing bar
                    Color.clear
                        .frame(height: 80)
                }
            }
        }
        .background(Color(UIColor.systemGroupedBackground))
        .animation(.easeOut(duration: 0.2), value: filteredSongs)
        .scrollIndicators(.hidden)
    }
}

#Preview("Three Songs") {
    let rankingManager = MusicRankingManager()
    rankingManager.rankedSongs = [
        Song(id: UUID(), title: "Bohemian Rhapsody", artist: "Queen", albumArt: "A Night at the Opera", sentiment: .love, score: 9.5),
        Song(id: UUID(), title: "Hotel California", artist: "Eagles", albumArt: "Hotel California", sentiment: .love, score: 8.5),
        Song(id: UUID(), title: "Sweet Child O' Mine", artist: "Guns N' Roses", albumArt: "Appetite for Destruction", sentiment: .fine, score: 7.0)
    ]
    
    return RankedSongListView(
        filteredSongs: rankingManager.rankedSongs,
        searchText: "",
        onAddSong: {}
    )
    .environmentObject(rankingManager)
    .environmentObject(MusicAPIManager())
}

#Preview("No Songs") {
    let rankingManager = MusicRankingManager()
    rankingManager.rankedSongs = [
        Song(id: UUID(), title: "Bohemian Rhapsody", artist: "Queen", albumArt: "A Night at the Opera", sentiment: .love, score: 9.5),
        Song(id: UUID(), title: "Hotel California", artist: "Eagles", albumArt: "Hotel California", sentiment: .love, score: 8.5),
        Song(id: UUID(), title: "Sweet Child O' Mine", artist: "Guns N' Roses", albumArt: "Appetite for Destruction", sentiment: .fine, score: 7.0)
    ]
    
    return RankedSongListView(
        filteredSongs: [],
        searchText: "",
        onAddSong: {}
    )
    .environmentObject(rankingManager)
    .environmentObject(MusicAPIManager())
}

#Preview("Empty Search") {
    let rankingManager = MusicRankingManager()
    rankingManager.rankedSongs = [
        Song(id: UUID(), title: "Bohemian Rhapsody", artist: "Queen", albumArt: "A Night at the Opera", sentiment: .love, score: 9.5),
        Song(id: UUID(), title: "Hotel California", artist: "Eagles", albumArt: "Hotel California", sentiment: .love, score: 8.5),
        Song(id: UUID(), title: "Sweet Child O' Mine", artist: "Guns N' Roses", albumArt: "Appetite for Destruction", sentiment: .fine, score: 7.0)
    ]
    
    return RankedSongListView(
        filteredSongs: [],
        searchText: "Search",
        onAddSong: {}
    )
    .environmentObject(rankingManager)
    .environmentObject(MusicAPIManager())
}

