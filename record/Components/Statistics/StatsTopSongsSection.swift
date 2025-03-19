//
//  TopSongsSection.swift
//  record
//
//  Created by Nadav Avital on 3/5/25.
//
import SwiftUI
import MediaPlayer

struct StatsTopSongsSection: View {
    @EnvironmentObject var mediaPlayerManager: MediaPlayerManager
    
    private var topSongs: [(song: MPMediaItem, count: Int)] {
        let sortedSongs = mediaPlayerManager.topSongs
            .map { (song: $0, count: $0.playCount) }
            .sorted { $0.count > $1.count }
        return sortedSongs
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Top Songs").font(.headline).fontWeight(.semibold)
                Spacer()
                NavigationLink(destination: TopSongsListView(songs: topSongs)) {
                    Text("See All")
                        .font(.subheadline)
                        .foregroundColor(.accentColor)
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
                        ForEach(topSongs.prefix(10), id: \.song.persistentID) { item in
                            StatsSongTile(song: item.song, count: item.count)
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
        .environmentObject(MediaPlayerManager())
}
