//
//  RankingView.swift
//  record
//
//  Created by Nadav Avital on 2/24/25.
//

import SwiftUI

struct RankingView: View {
    @EnvironmentObject var rankingManager: MusicRankingManager
    @State private var showAddSongSheet = false
    @State private var selectedSegment = 0
    @State private var searchText = ""
    @Environment(\.colorScheme) private var colorScheme
    
    private var segmentTitles = ["All", "Loved", "Fine", "Disliked"]
    
    var filteredSongs: [Song] {
        let songs = rankingManager.rankedSongs
        
        // First, apply sentiment filter based on selected segment
        let sentimentFiltered: [Song]
        switch selectedSegment {
        case 1:
            sentimentFiltered = songs.filter { $0.sentiment == .love }
        case 2:
            sentimentFiltered = songs.filter { $0.sentiment == .fine }
        case 3:
            sentimentFiltered = songs.filter { $0.sentiment == .dislike }
        default:
            sentimentFiltered = songs
        }
        
        // Then apply search text filter if needed
        if (!searchText.isEmpty) {
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
                // Custom filter bar component
                CustomFilterBarView(selectedSegment: $selectedSegment, segmentTitles: segmentTitles)
                
                // Custom search bar component
                SearchBarView(
                    searchText: $searchText,
                    placeholder: "Search songs or artists",
                    onTextChange: { },
                    onClearText: { }
                )
                .padding(.vertical, 4)
                
                // Using the extracted RankedSongListView component
                RankedSongListView(
                    filteredSongs: filteredSongs,
                    searchText: searchText,
                    onAddSong: { showAddSongSheet = true }
                )
            }
            .navigationTitle("Ranked Songs")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        showAddSongSheet = true
                    } label: {
                        Label("Add Song", systemImage: "plus")
                    }
                }
            }
            .sheet(isPresented: $showAddSongSheet) {
                AddSongView()
            }
            .overlay {
                // Overlays for ranking process
                if rankingManager.showSentimentPicker {
                    Color(.systemBackground)
                        .opacity(0.95)
                        .ignoresSafeArea()
                        .zIndex(1)
                    
                    SentimentPickerView()
                        .transition(.opacity)
                        .zIndex(2)
                }
                
                if rankingManager.showComparison {
                    Color(.systemBackground)
                        .opacity(0.95)
                        .ignoresSafeArea()
                        .zIndex(1)
                    
                    SongComparisonView()
                        .transition(.opacity)
                        .zIndex(3)
                }
            }
        }
        .accentColor(.pink)
    }
}

#Preview("Ranking View") {
    RankingView()
        .environmentObject(MusicRankingManager())
}
