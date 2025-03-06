//
//  TopSongsListView.swift
//  record
//
//  Created by Nadav Avital on 3/5/25.
//

import SwiftUI

struct TopSongsListView: View {
    @EnvironmentObject var musicAPI: MusicAPIManager
    @EnvironmentObject var rankingManager: MusicRankingManager
    
    let songs: [(song: ListeningHistoryItem, count: Int)]
    
    var body: some View {
        List {
            ForEach(Array(songs.enumerated()), id: \.element.song.id) { index, item in
                NavigationLink(destination: SongInfoView(mediaItem: item.song.mediaItem, musicAPI: musicAPI, rankingManager: rankingManager)) {
                    HStack(spacing: 12) {
                        Text("#\(index + 1)")
                            .foregroundStyle(.secondary)
                            .frame(width: 40, alignment: .leading)
                            .font(.subheadline)
                        songRowView(song: item.song, count: item.count)
                    }
                }
            }
        }
        .navigationTitle("Top Songs")
        .navigationBarTitleDisplayMode(.inline)
    }
    
    private func songRowView(song: ListeningHistoryItem, count: Int) -> some View {
        HStack(spacing: 12) {
            Group {
                if let artworkImage = musicAPI.getArtworkImage(for: song) {
                    Image(uiImage: artworkImage).resizable().scaledToFill()
                } else {
                    RemoteArtworkView(artworkURL: nil, placeholderText: song.title, size: CGSize(width: 16, height: 16))
                }
            }
            .frame(width: 50, height: 50)
            .cornerRadius(6)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(song.title).font(.body).lineLimit(1)
                Text(song.artist).font(.subheadline).foregroundColor(.secondary).lineLimit(1)
            }
            Spacer()
            Text("\(count) plays").font(.caption).foregroundColor(.secondary)
        }
    }
}
