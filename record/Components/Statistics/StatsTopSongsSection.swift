//
//  TopSongsSection.swift
//  record
//
//  Created by Nadav Avital on 3/5/25.
//
import SwiftUI
import MusicKit

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
                        // Convert the ArraySlice to Array before using in ForEach
                        ForEach(Array(topSongs.prefix(10)), id: \.song.id) { item in
                            // Create a NavigationLink that doesn't depend on MediaItem but uses
                            // the song title and artist to search in MusicKit
                            NavigationLink {
                                // Create a wrapper view that searches and loads the song info
                                SongSearchAndInfoView(title: item.song.title, artist: item.song.artist)
                                    .environmentObject(musicAPI)
                                    .environmentObject(rankingManager)
                            } label: {
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

// This view handles searching for a song in MusicKit and then loading the song info view
struct SongSearchAndInfoView: View {
    let title: String
    let artist: String
    
    @EnvironmentObject var musicAPI: MusicAPIManager
    @EnvironmentObject var rankingManager: MusicRankingManager
    @State private var isSearching = true
    @State private var searchResult: MusicKit.Song?
    @State private var errorMessage: String?
    
    var body: some View {
        Group {
            if isSearching {
                ProgressView("Searching for song...")
            } else if let song = searchResult {
                SongInfoView(
                    musicKitSong: song,
                    musicAPI: musicAPI,
                    rankingManager: rankingManager
                )
            } else {
                // Fallback if song cannot be found
                VStack(spacing: 20) {
                    Text("Couldn't find song in Apple Music")
                        .font(.headline)
                    
                    Text("\(title) by \(artist)")
                        .foregroundColor(.secondary)
                    
                    if let error = errorMessage {
                        Text(error)
                            .foregroundColor(.red)
                            .font(.caption)
                    }
                    
                    Button("Try Again") {
                        searchForSong()
                    }
                    .buttonStyle(.bordered)
                }
                .padding()
            }
        }
        .onAppear {
            searchForSong()
        }
    }
    
    private func searchForSong() {
        isSearching = true
        errorMessage = nil
        
        Task {
            do {
                var request = MusicCatalogSearchRequest(term: "\(title) \(artist)", types: [MusicKit.Song.self])
                request.limit = 5
                
                let response = try await request.response()
                
                // Try to find an exact match
                let exactMatch = response.songs.first { song in
                    song.title.lowercased() == title.lowercased() &&
                    song.artistName.lowercased() == artist.lowercased()
                }
                
                // Use the exact match or the first result
                let song = exactMatch ?? response.songs.first
                
                await MainActor.run {
                    searchResult = song
                    isSearching = false
                }
            } catch {
                await MainActor.run {
                    errorMessage = error.localizedDescription
                    isSearching = false
                }
            }
        }
    }
}

#Preview {
    StatsTopSongsSection()
        .environmentObject(MusicAPIManager())
        .environmentObject(MusicRankingManager())
}
