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

// Simplified search view without Combine
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
                        // Simple search bar
                        HStack {
                            Image(systemName: "magnifyingglass")
                                .foregroundColor(.secondary)
                                .padding(.leading, 8)
                            
                            TextField(searchType.placeholder, text: $searchText)
                                .onChange(of: searchText) { newValue in
                                    performSearch(query: newValue)
                                }
                                .padding(.vertical, 8)
                            
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
                            }
                        }
                        .background(Color(.secondarySystemBackground))
                        .cornerRadius(10)
                        .padding(.horizontal)
                        
                        // Results view
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
                    }
                }
            }
        }
        .task {
            await musicAPI.checkMusicAuthorizationStatus()
            // Set the ranking manager reference to check for already ranked songs
            musicAPI.setRankingManager(rankingManager)
        }
    }
    
    // Search results view
    private var searchResultsView: some View {
        Group {
            if musicAPI.searchResults.isEmpty && searchText.isEmpty {
                Text("Start typing to search")
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if musicAPI.searchResults.isEmpty && isSearching {
                ProgressView()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if musicAPI.searchResults.isEmpty && !searchText.isEmpty && !isSearching {
                Text("No results found")
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                ScrollView {
                    LazyVStack(spacing: 12) {
                        ForEach(musicAPI.searchResults) { item in
                            // Check if song is already ranked when rendering item
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
    
    // Simple debounced search with Task
    private func performSearch(query: String) {
        // Cancel any existing search
        searchTask?.cancel()
        
        // Handle empty query
        if query.isEmpty {
            isSearching = false
            musicAPI.searchResults = []
            return
        }
        
        // Skip if query hasn't changed
        if query == lastSearchTerm {
            return
        }
        
        // Update state
        isSearching = true
        lastSearchTerm = query
        
        // Start new search task
        searchTask = Task {
            // Add small delay for debouncing
            try? await Task.sleep(nanoseconds: 300_000_000) // 300ms delay
            
            // Exit if cancelled during delay
            if Task.isCancelled { return }
            
            // Print debug info
            print("Performing search for: \(query)")
            
            // Perform search based on type
            switch searchType {
            case .song:
                await musicAPI.searchMusic(query: query)
            case .album:
                await musicAPI.searchAlbums(query: query)
            case .artist:
                await musicAPI.searchArtists(query: query)
            }
            
            // Update UI state after search completes
            await MainActor.run {
                print("Search completed for: \(query), results: \(musicAPI.searchResults.count)")
                // Only update if this query is still relevant
                if query == searchText {
                    isSearching = false
                }
            }
        }
    }
}
