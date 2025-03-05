import SwiftUI
import MusicKit

enum SearchType {
    case song
    case album
    case artist
    
    var placeholder: String {
        switch self {
        case .song: return "Search for a song..."
        case .album: return "Search for an album..."
        case .artist: return "Search for an artist..."
        }
    }
    
    var title: String {
        switch self {
        case .song: return "Add Song"
        case .album: return "Add Album"
        case .artist: return "Add Artist"
        }
    }
}

struct UnifiedSearchView: View {
    @Environment(\.presentationMode) var presentationMode
    @EnvironmentObject var profileManager: UserProfileManager
    @EnvironmentObject var rankingManager: MusicRankingManager
    @StateObject private var musicAPI = MusicAPIManager()
    
    @State private var searchText = ""
    @State private var isSearching = false
    @State private var searchTask: Task<Void, Never>?
    @State private var lastSearchTerm = ""
    
    let searchType: SearchType
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color(.systemBackground)
                    .ignoresSafeArea()
                
                VStack(spacing: 16) {
                    if musicAPI.authorizationStatus != .authorized {
                        MusicAuthBannerView(
                            authorizationStatus: musicAPI.authorizationStatus,
                            requestAuthAction: {
                                Task {
                                    await musicAPI.checkMusicAuthorizationStatus()
                                }
                            }
                        )
                    }
                    
                    VStack(spacing: 12) {
                        HStack {
                            Image(systemName: "magnifyingglass")
                                .foregroundColor(.secondary)
                                .padding(.leading, 8)
                            
                            TextField(searchType.placeholder, text: $searchText)
                                .onChange(of: searchText) {
                                    performSearch(query: searchText)
                                }
                                .padding(.vertical, 8)
                                .accentColor(.accentColor) // Set cursor color
                            
                            if !searchText.isEmpty {
                                Button(action: {
                                    searchText = ""
                                    musicAPI.searchResults = []
                                }) {
                                    Image(systemName: "xmark.circle.fill")
                                        .foregroundColor(.secondary)
                                }
                                .padding(.trailing, 8)
                            }
                            
                            if isSearching {
                                ProgressView()
                                    .padding(.trailing, 8)
                                    .tint(.accentColor) // Set spinner color
                            }
                        }
                        .background(Color(.secondarySystemBackground))
                        .cornerRadius(10)
                        .padding(.horizontal)
                        
                        searchResultsView
                    }
                }
                .navigationTitle(searchType.title)
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .navigationBarLeading) {
                        Button(action: {
                            presentationMode.wrappedValue.dismiss()
                        }) {
                            Image(systemName: "xmark.circle.fill")
                                .font(.system(size: 22))
                                .foregroundStyle(Color(.tertiaryLabel))
                        }
                        .tint(Color.accentColor) // Ensure button uses accent color
                    }
                }
            }
        }
        .tint(Color.accentColor) // Set navigation tint color
        .task {
            await musicAPI.checkMusicAuthorizationStatus()
            musicAPI.setRankingManager(rankingManager)
            await musicAPI.fetchRecentSongs() // Fetch all recent items from songs
        }
    }
    
    private var searchResultsView: some View {
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
        case .album:
            let album = musicAPI.convertToAlbum(item)
            profileManager.pinnedAlbums.append(album)
        case .artist:
            let artist = Artist(
                name: item.artist,
                artworkURL: musicAPI.getArtworkURL(for: item.artworkID)
            )
            profileManager.addPinnedArtist(artist)
        }
        presentationMode.wrappedValue.dismiss()
    }
    
    private func performSearch(query: String) {
        searchTask?.cancel()
        
        if query.isEmpty {
            isSearching = false
            musicAPI.searchResults = []
            return
        }
        
        if query == lastSearchTerm {
            return
        }
        
        isSearching = true
        lastSearchTerm = query
        
        searchTask = Task {
            try? await Task.sleep(nanoseconds: 300_000_000) // 300ms delay
            if Task.isCancelled { return }
            
            print("Performing search for: \(query)")
            
            switch searchType {
            case .song:
                await musicAPI.searchMusic(query: query)
            case .album:
                await musicAPI.searchAlbums(query: query)
            case .artist:
                await musicAPI.searchArtists(query: query)
            }
            
            await MainActor.run {
                print("Search completed for: \(query), results: \(musicAPI.searchResults.count)")
                if query == searchText {
                    isSearching = false
                }
            }
        }
    }
}
