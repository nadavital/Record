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

struct SearchResultsView: View {
    @EnvironmentObject var profileManager: UserProfileManager
    @EnvironmentObject var rankingManager: MusicRankingManager
    let musicAPI: MusicAPIManager
    let searchType: SearchType
    let searchText: String
    let presentationMode: Binding<PresentationMode>
    
    var body: some View {
        ZStack {
            if musicAPI.isSearching {
                ProgressView()
                    .scaleEffect(1.2)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if let errorMessage = musicAPI.errorMessage {
                VStack(spacing: 15) {
                    Text(errorMessage)
                        .foregroundColor(Color(.secondaryLabel))
                        .multilineTextAlignment(.center)
                    
                    Button(action: {
                        Task {
                            switch searchType {
                            case .song:
                                await musicAPI.searchMusic(query: searchText)
                            case .album:
                                await musicAPI.searchAlbums(query: searchText)
                            case .artist:
                                await musicAPI.searchArtists(query: searchText)
                            }
                        }
                    }) {
                        Text("Retry")
                            .foregroundColor(.white)
                            .font(.system(size: 15, weight: .medium))
                            .padding(.horizontal, 16)
                            .padding(.vertical, 8)
                            .background(
                                Capsule()
                                    .fill(Color.accentColor)
                            )
                    }
                }
            } else if musicAPI.searchResults.isEmpty && !searchText.isEmpty {
                Text("No results found")
                    .foregroundColor(Color(.secondaryLabel))
            } else {
                ScrollView {
                    LazyVStack(spacing: 12) {
                        ForEach(musicAPI.searchResults) { item in
                            MusicItemTileView(
                                title: item.title,
                                artist: item.artist,
                                albumName: searchType == .song ? item.albumName : nil,
                                artworkID: item.artworkID,
                                onSelect: {
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
                                },
                                musicAPI: musicAPI
                            )
                            .padding(.horizontal)
                        }
                    }
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

struct UnifiedSearchView: View {
    @Environment(\.presentationMode) var presentationMode
    @EnvironmentObject var profileManager: UserProfileManager
    @EnvironmentObject var rankingManager: MusicRankingManager
    @StateObject private var musicAPI = MusicAPIManager()
    @State private var searchText = ""
    @State private var searchTask: Task<Void, Never>?
    
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
                        SearchBarView(
                            searchText: $searchText,
                            placeholder: searchType.placeholder,
                            onTextChange: performSearch,
                            onClearText: {
                                searchTask?.cancel()
                                musicAPI.searchResults = []
                            }
                        )
                        .padding(.vertical, 4)
                        
                        SearchResultsView(
                            musicAPI: musicAPI,
                            searchType: searchType,
                            searchText: searchText,
                            presentationMode: presentationMode
                        )
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
        }
    }
    
    private func performSearch() {
        searchTask?.cancel()
        
        guard !searchText.isEmpty else {
            musicAPI.searchResults = []
            return
        }
        
        searchTask = Task {
            try? await Task.sleep(nanoseconds: 300_000_000) // 0.3 second debounce
            
            guard !Task.isCancelled else { return }
            
            switch searchType {
            case .song:
                await musicAPI.searchMusic(query: searchText)
            case .album:
                await musicAPI.searchAlbums(query: searchText)
            case .artist:
                await musicAPI.searchArtists(query: searchText)
            }
        }
    }
}

#Preview {
    let profileManager = UserProfileManager()
    let rankingManager = MusicRankingManager()
    
    return NavigationStack {
        UnifiedSearchView(searchType: .song)
            .environmentObject(profileManager)
            .environmentObject(rankingManager)
    }
}
