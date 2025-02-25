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
        if !searchText.isEmpty {
            return sentimentFiltered.filter { 
                $0.title.localizedCaseInsensitiveContains(searchText) || 
                $0.artist.localizedCaseInsensitiveContains(searchText)
            }
        }
        
        return sentimentFiltered
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                // Background gradient for glassmorphic effect
                LinearGradient(
                    gradient: Gradient(colors: [
                        colorScheme == .dark ? 
                            Color(red: 0.1, green: 0.05, blue: 0.2) : 
                            Color(red: 0.9, green: 0.9, blue: 0.98),
                        colorScheme == .dark ? 
                            Color(red: 0.05, green: 0.05, blue: 0.1) : 
                            Color(red: 0.98, green: 0.97, blue: 1.0)
                    ]),
                    startPoint: .top,
                    endPoint: .bottom
                )
                .ignoresSafeArea()
                
                // Subtle pattern overlay
                Image(systemName: "music.note")
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .foregroundColor(Color.primary.opacity(0.03))
                    .rotationEffect(Angle(degrees: 15))
                    .ignoresSafeArea()
                
                VStack(spacing: 0) {
                    // Filter tabs with glassmorphic style
                    HStack(spacing: 0) {
                        ForEach(0..<segmentTitles.count, id: \.self) { index in
                            Button(action: {
                                withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                    selectedSegment = index
                                }
                            }) {
                                HStack(spacing: 5) {
                                    if index > 0 {
                                        Image(systemName: sentimentIcon(for: index))
                                            .font(.system(size: 12))
                                    }
                                    Text(segmentTitles[index])
                                        .font(.subheadline)
                                        .fontWeight(selectedSegment == index ? .semibold : .regular)
                                }
                                .padding(.vertical, 10)
                                .padding(.horizontal, 12)
                                .background(
                                    selectedSegment == index ?
                                        Capsule()
                                            .fill(
                                                Color(.systemBackground)
                                                    .opacity(0.7)
                                            )
                                            .overlay(
                                                Capsule()
                                                    .stroke(
                                                        LinearGradient(
                                                            gradient: Gradient(colors: [
                                                                Color.white.opacity(0.6),
                                                                Color.white.opacity(0.2)
                                                            ]),
                                                            startPoint: .topLeading,
                                                            endPoint: .bottomTrailing
                                                        ),
                                                        lineWidth: 0.5
                                                    )
                                            )
                                            .shadow(color: Color.black.opacity(0.1), radius: 3, y: 1)
                                        : nil
                                )
                                .foregroundColor(selectedSegment == index ? Color.accentColor : Color(.secondaryLabel))
                            }
                            .buttonStyle(PlainButtonStyle())
                            
                            if index < segmentTitles.count - 1 {
                                Spacer()
                            }
                        }
                    }
                    .padding(.horizontal, 15)
                    .padding(.top, 10)
                    .padding(.bottom, 5)
                    .background(
                        VisualEffectBlur(
                            blurStyle: colorScheme == .dark ? .systemMaterialDark : .systemMaterial
                        )
                        .ignoresSafeArea(edges: .top)
                    )
                    
                    // Search field with glassmorphic style
                    HStack {
                        Image(systemName: "magnifyingglass")
                            .foregroundColor(Color(.tertiaryLabel))
                        
                        TextField("Search songs or artists", text: $searchText)
                            .font(.system(size: 15))
                    }
                    .padding(10)
                    .background(
                        RoundedRectangle(cornerRadius: 10)
                            .fill(Color(.systemBackground).opacity(0.5))
                            .overlay(
                                RoundedRectangle(cornerRadius: 10)
                                    .stroke(
                                        LinearGradient(
                                            gradient: Gradient(colors: [
                                                Color.white.opacity(0.5),
                                                Color.white.opacity(0.2)
                                            ]),
                                            startPoint: .topLeading,
                                            endPoint: .bottomTrailing
                                        ),
                                        lineWidth: 0.5
                                    )
                            )
                    )
                    .padding(.horizontal)
                    .padding(.top, 5)
                    .padding(.bottom, 10)
                    
                    // Ranked songs list
                    ScrollView {
                        LazyVStack(spacing: 10) {
                            if filteredSongs.isEmpty {
                                VStack(spacing: 16) {
                                    Image(systemName: "music.note.list")
                                        .font(.system(size: 50))
                                        .foregroundColor(Color(.tertiaryLabel))
                                        .padding(.top, 60)
                                    
                                    Text(searchText.isEmpty ? "No songs in this category" : "No matching songs found")
                                        .font(.headline)
                                        .foregroundColor(Color(.secondaryLabel))
                                        .multilineTextAlignment(.center)
                                        .padding(.horizontal)
                                }
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 60)
                            } else {
                                ForEach(filteredSongs) { song in
                                    RankedSongRow(
                                        rank: rankingManager.rankedSongs.firstIndex(where: { $0.id == song.id })! + 1,
                                        song: song
                                    )
                                    .padding(.horizontal)
                                }
                                .padding(.bottom, 80) // Extra padding for floating button
                            }
                        }
                    }
                }
                .navigationTitle("Ranked Songs")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button(action: {
                            showAddSongSheet = true
                        }) {
                            Image(systemName: "plus")
                                .font(.system(size: 17, weight: .semibold))
                        }
                    }
                }
                
                // Floating add song button with glassmorphic style
                VStack {
                    Spacer()
                    
                    Button(action: {
                        showAddSongSheet = true
                    }) {
                        HStack {
                            Image(systemName: "plus")
                                .font(.system(size: 16, weight: .semibold))
                            Text("Add Song")
                                .font(.system(size: 16, weight: .semibold))
                        }
                        .padding(.vertical, 12)
                        .padding(.horizontal, 20)
                        .background(
                            Capsule()
                                .fill(
                                    VisualEffectBlur(
                                        blurStyle: colorScheme == .dark ? .systemMaterialDark : .systemMaterial
                                    )
                                )
                                .overlay(
                                    Capsule()
                                        .stroke(
                                            LinearGradient(
                                                gradient: Gradient(colors: [
                                                    Color.white.opacity(0.9),
                                                    Color.white.opacity(0.5)
                                                ]),
                                                startPoint: .topLeading,
                                                endPoint: .bottomTrailing
                                            ),
                                            lineWidth: 0.5
                                        )
                                )
                        )
                        .overlay(
                            // Accent colored gradient background
                            Capsule()
                                .fill(
                                    LinearGradient(
                                        gradient: Gradient(colors: [
                                            Color.accentColor.opacity(0.7),
                                            Color.accentColor.opacity(0.4)
                                        ]),
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                                .mask(
                                    HStack {
                                        Image(systemName: "plus")
                                            .font(.system(size: 16, weight: .semibold))
                                        Text("Add Song")
                                            .font(.system(size: 16, weight: .semibold))
                                    }
                                    .padding()
                                )
                        )
                        .shadow(color: Color.black.opacity(0.15), radius: 8, y: 4)
                    }
                    .foregroundColor(Color(.label))
                    .padding(.bottom, 25)
                }
                
                // Overlays for ranking process
                if rankingManager.showSentimentPicker {
                    Color.black.opacity(0.3)
                        .ignoresSafeArea()
                        .zIndex(1)
                    
                    SentimentPickerView()
                        .transition(.opacity.combined(with: .scale))
                        .zIndex(2)
                }
                
                if rankingManager.showComparison {
                    Color.black.opacity(0.3)
                        .ignoresSafeArea()
                        .zIndex(1)
                    
                    SongComparisonView()
                        .transition(.opacity.combined(with: .scale))
                        .zIndex(3)
                }
            }
            .sheet(isPresented: $showAddSongSheet) {
                AddSongView()
            }
        }
        // Use the system accent color
        .accentColor(.pink)
    }
    
    // Get icon for sentiment in segment control
    private func sentimentIcon(for index: Int) -> String {
        switch index {
        case 1: return "heart.fill"       // Love
        case 2: return "hand.thumbsup"    // Fine
        case 3: return "hand.thumbsdown"  // Dislike
        default: return "music.note.list" // All
        }
    }
}

#Preview("Ranking View") {
    RankingView()
        .environmentObject(MusicRankingManager())
}
