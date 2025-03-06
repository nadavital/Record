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
                        
                        SearchResultsView(musicAPI: musicAPI, searchText: $searchText, isSearching: $isSearching, searchType: searchType)
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

#Preview {
    UnifiedSearchView(searchType: .song)
    .environmentObject(UserProfileManager())
    .environmentObject(MusicRankingManager())
}
