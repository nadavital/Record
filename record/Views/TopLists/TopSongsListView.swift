//
//  TopSongsListView.swift
//  record
//
//  Created by Nadav Avital on 3/5/25.
//

import SwiftUI
import MediaPlayer

struct TopSongsListView: View {
    let songs: [(song: MPMediaItem, count: Int)]
    
    var body: some View {
        List {
            ForEach(Array(songs.enumerated()), id: \.element.song.persistentID) { index, item in
                HStack {
                    Text("#\(index + 1)")
                        .foregroundStyle(.secondary)
                        .frame(width: 40, alignment: .leading)
                        .font(.subheadline)
                        
                    VStack(alignment: .leading) {
                        Text(item.song.title ?? "Unknown Title").font(.body)
                        Text(item.song.artist ?? "Unknown Artist").font(.subheadline).foregroundColor(.secondary)
                    }
                    Spacer()
                    Text("\(item.count) plays").font(.subheadline).foregroundColor(.secondary)
                }
            }
            
            // Padding at the bottom for now playing bar
            Color.clear
                .frame(height: 80)
                .listRowInsets(EdgeInsets())
        }
        .navigationTitle("Top Songs")
        .navigationBarTitleDisplayMode(.inline)
        .scrollIndicators(.hidden)
    }
}

#Preview {
    let sampleSongs: [(song: MPMediaItem, count: Int)] = []
    return TopSongsListView(songs: sampleSongs)
}
