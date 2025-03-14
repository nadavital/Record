//
//  SearchResultsView.swift
//  record
//
//  Created by Nadav Avital on 3/5/25.
//

import SwiftUI

//
//  SearchResultsView.swift - Corrected Update
//

import SwiftUI

struct SearchResultsView: View {
    @Environment(\.presentationMode) var presentationMode
    @ObservedObject var musicAPI: MusicAPIManager
    @EnvironmentObject var rankingManager: MusicRankingManager
    @EnvironmentObject var profileManager: UserProfileManager
    @EnvironmentObject var albumRatingManager: AlbumRatingManager
    @Binding var searchText: String
    @Binding var isSearching: Bool
    let searchType: SearchType
    
    var body: some View {
        Group {
            if musicAPI.searchResults.isEmpty && searchText.isEmpty {
                // Select recent items based on searchType
                let recentItems = searchType == .song ? musicAPI.recentSongs :
                searchType == .album ? musicAPI.recentAlbums :
                musicAPI.recentArtists
                
                if !recentItems.isEmpty {
                    ScrollView {
                        VStack(alignment: .leading) {
                            Text("Recent")
                                .font(.headline)
                                .foregroundColor(.secondary)
                                .padding(.horizontal)
                                .padding(.top, 4)
                            
                            LazyVStack(spacing: 12) {
                                ForEach(recentItems) { item in
                                    let rankInfo = searchType == .song ?
                                    musicAPI.checkIfSongIsRanked(title: item.title, artist: item.artist) : nil
                                    
                                    MusicItemTileView(
                                        title: item.title,
                                        artist: item.artist,
                                        albumName: searchType == .song ? item.albumName : nil,
                                        artworkID: item.artworkID,
                                        onSelect: {
                                            handleSelection(item)
                                        },
                                        musicAPI: musicAPI,
                                        isAlreadyRanked: rankInfo?.isRanked ?? false,
                                        currentRank: rankInfo?.rank ?? 0,
                                        currentScore: rankInfo?.score ?? 0.0
                                    )
                                    .padding(.horizontal)
                                }
                            }
                            .padding(.vertical, 8)
                        }
                    }
                } else {
                    VStack(spacing: 12) {
                        Image(systemName: "magnifyingglass")
                            .font(.system(size: 32))
                            .foregroundColor(.accentColor.opacity(0.7))
                            .padding(.bottom, 8)
                        
                        Text("Start typing to search")
                            .font(.headline)
                            .foregroundColor(.secondary)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                }
            } else if musicAPI.searchResults.isEmpty && isSearching {
                ProgressView()
                    .tint(.accentColor)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if musicAPI.searchResults.isEmpty && !searchText.isEmpty && !isSearching {
                Text("No results found")
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                ScrollView {
                    LazyVStack(spacing: 12) {
                        ForEach(musicAPI.searchResults) { item in
                            let rankInfo = searchType == .song ?
                            musicAPI.checkIfSongIsRanked(title: item.title, artist: item.artist) : nil
                            
                            MusicItemTileView(
                                title: item.title,
                                artist: item.artist,
                                albumName: searchType == .song ? item.albumName : nil,
                                artworkID: item.artworkID,
                                onSelect: {
                                    handleSelection(item)
                                },
                                musicAPI: musicAPI,
                                isAlreadyRanked: rankInfo?.isRanked ?? false,
                                currentRank: rankInfo?.rank ?? 0,
                                currentScore: rankInfo?.score ?? 0.0
                            )
                            .padding(.horizontal)
                        }
                    }
                    .padding(.vertical, 8)
                }
            }
        }
    }
    
    private func handleSelection(_ item: MusicItem) {
        switch searchType {
        case .song:
            let song = musicAPI.convertToSong(item)
            rankingManager.addNewSong(song: song)
            presentationMode.wrappedValue.dismiss()
            
        case .album:
            let album = musicAPI.convertToAlbum(item)
            // Instead of adding to pinned albums, we'll start the rating process
            albumRatingManager.rateAlbum(album)
            presentationMode.wrappedValue.dismiss()
            
        case .artist:
            let artist = Artist(
                name: item.artist,
                artworkURL: musicAPI.getArtworkURL(for: item.artworkID)
            )
            profileManager.addPinnedArtist(artist)
            presentationMode.wrappedValue.dismiss()
        }
    }
}

#Preview("No Results") {
    @Previewable @StateObject var musicAPI = MusicAPIManager()
    @Previewable @State var searchText = "No Tears Left To Cry"
    @Previewable @State var isSearching = false
    SearchResultsView(musicAPI: musicAPI,
                      searchText: $searchText,
                      isSearching: $isSearching,
                      searchType: .song)
    .environmentObject(MusicRankingManager())
    .environmentObject(UserProfileManager())
}

#Preview("Nothing Typed") {
    @Previewable @StateObject var musicAPI = MusicAPIManager()
    @Previewable @State var searchText = ""
    @Previewable @State var isSearching = false
    SearchResultsView(musicAPI: musicAPI,
                      searchText: $searchText,
                      isSearching: $isSearching,
                      searchType: .song)
    .environmentObject(MusicRankingManager())
    .environmentObject(UserProfileManager())
}

#Preview("Searching Indicator") {
    @Previewable @StateObject var musicAPI = MusicAPIManager()
    @Previewable @State var searchText = "No Tears Left To Cry"
    @Previewable @State var isSearching = true
    SearchResultsView(musicAPI: musicAPI,
                      searchText: $searchText,
                      isSearching: $isSearching,
                      searchType: .song)
    .environmentObject(MusicRankingManager())
    .environmentObject(UserProfileManager())
}
