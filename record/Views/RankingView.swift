//
//  RankingView.swift
//  record
//
//  Created by Nadav Avital on 2/24/25.
//

import SwiftUI

struct RankingView: View {
    @EnvironmentObject var rankingManager: MusicRankingManager
    @EnvironmentObject var musicAPI: MusicAPIManager
    @EnvironmentObject private var authManager: AuthManager
    @ObservedObject private var persistenceManager = PersistenceManager.shared
    @State private var showAddSongSheet = false
    @State private var selectedFilter = FilterOption.all
    @State private var searchText = ""
    @Environment(\.colorScheme) private var colorScheme
    
    enum FilterOption {
        case all, loved, fine, disliked
        
        var label: String {
            switch self {
            case .all: return "All Songs"
            case .loved: return "Loved"
            case .fine: return "Fine"
            case .disliked: return "Disliked"
            }
        }
        
        var icon: String {
            switch self {
            case .all: return "music.note.list"
            case .loved: return "heart.fill"
            case .fine: return "hand.thumbsup"
            case .disliked: return "hand.thumbsdown"
            }
        }
    }
    
    var filteredSongs: [Song] {
        let songs = rankingManager.rankedSongs
        
        let sentimentFiltered: [Song]
        switch selectedFilter {
        case .loved: sentimentFiltered = songs.filter { $0.sentiment == .love }
        case .fine: sentimentFiltered = songs.filter { $0.sentiment == .fine }
        case .disliked: sentimentFiltered = songs.filter { $0.sentiment == .dislike }
        case .all: sentimentFiltered = songs
        }
        
        if !searchText.isEmpty {
            return sentimentFiltered.filter {
                $0.title.localizedCaseInsensitiveContains(searchText) ||
                $0.artist.localizedCaseInsensitiveContains(searchText)
            }
        }
        
        return sentimentFiltered
    }
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 8) {
                // Search bar
                HStack {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(.secondary)
                        .padding(.leading, 8)
                    TextField("Search songs or artists", text: $searchText)
                        .padding(.vertical, 8)
                    if !searchText.isEmpty {
                        Button(action: { searchText = "" }) {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundColor(.secondary)
                        }
                        .padding(.trailing, 8)
                    }
                }
                .background(Color(.secondarySystemBackground))
                .cornerRadius(10)
                .padding(.horizontal)
                
                RankedSongListView(
                    filteredSongs: filteredSongs,
                    searchText: searchText,
                    onAddSong: { showAddSongSheet = true }
                )
            }
            .navigationTitle("Ranked Songs")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    HStack(spacing: 12) {
                        Menu {
                            ForEach([FilterOption.all, .loved, .fine, .disliked], id: \.self) { option in
                                Button {
                                    selectedFilter = option
                                } label: {
                                    Label {
                                        Text(option.label)
                                    } icon: {
                                        Image(systemName: selectedFilter == option ? "checkmark" : option.icon)
                                    }
                                }
                            }
                        } label: {
                            Label("Filter", systemImage: "line.3.horizontal.decrease")
                        }

                        Button {
                            showAddSongSheet = true
                        } label: {
                            Label("Add Song", systemImage: "plus")
                        }
                    }
                }
                
                ToolbarItem(placement: .navigationBarLeading) {
                    if persistenceManager.isSyncing {
                        ProgressView()
                    }
                }
            }
            .sheet(isPresented: $showAddSongSheet) {
                UnifiedSearchView(searchType: .song)
            }
            .refreshable {
                if let userId = authManager.userId {
                    await withCheckedContinuation { continuation in
                        persistenceManager.syncWithCloudKit { _ in
                            continuation.resume()
                        }
                    }
                }
            }
        }
    }
}

#Preview("Ranking View") {
    RankingView()
        .environmentObject(MusicRankingManager())
        .environmentObject(MusicAPIManager())
}
