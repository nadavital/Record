//
//  ProfileView.swift
//  record
//
//  Created by Nadav Avital on 2/25/25.
//  Updated with CloudKit sync status
//

import SwiftUI

struct ProfileView: View {
    @EnvironmentObject var profileManager: UserProfileManager
    @EnvironmentObject var rankingManager: MusicRankingManager
    @EnvironmentObject var authManager: AuthManager
    @State private var isEditing = false
    @State private var showAlbumPicker = false
    @State private var showArtistPicker = false
    @State private var showSettings = false
    @State private var showDetailedStats = false
    @State private var showingSyncAlert = false
    
    // For sync status
    @ObservedObject private var persistenceManager = PersistenceManager.shared
    
    var body: some View {
        NavigationStack {
            ScrollView(showsIndicators: false) {
                VStack(spacing: 20) {
                    // Profile header
                    ProfileHeader(isEditing: $isEditing)
                        .padding(.horizontal)
                    
                    // Album section
                    AlbumSection(
                        isEditingAlbums: .constant(isEditing),
                        showAlbumPicker: $showAlbumPicker)
                        .padding(.horizontal)
                    
                    // Top artists section
                    ArtistSection(
                        isEditingArtists: .constant(isEditing),
                        showArtistPicker: $showArtistPicker)
                        .padding(.horizontal)
                    
                    // Songs section
                    ProfileTopThreeRankedSongsSection()
                        .padding(.horizontal)
                    
                    //Album rating section
                    ProfileAlbumRatingsSection()
                        .padding(.horizontal)
                    
                    // Padding at the bottom for now playing bar
                    Color.clear
                        .frame(height: 80)
                        .listRowInsets(EdgeInsets())
                }
                .padding(.vertical)
            }
            .refreshable {
                if authManager.userId != nil {
                    await withCheckedContinuation { continuation in
                        persistenceManager.syncWithCloudKit { _ in
                            continuation.resume()
                        }
                    }
                }
            }
            .background(Color(.systemGroupedBackground).ignoresSafeArea())
            .navigationTitle("Profile")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    HStack(spacing: 16) {
                        Button {
                            showDetailedStats = true
                        } label: {
                            Image(systemName: "chart.bar")
                        }
                        
                        Button {
                            showSettings = true
                        } label: {
                            Image(systemName: "gearshape")
                        }
                    }
                }
                
                ToolbarItem(placement: .navigationBarLeading) {
                    if persistenceManager.isSyncing {
                        ProgressView()
                    }
                }
            }
            .sheet(isPresented: $showAlbumPicker) {
                UnifiedSearchView(searchType: .album)
            }
            .sheet(isPresented: $showArtistPicker) {
                UnifiedSearchView(searchType: .artist)
            }
            .sheet(isPresented: $showSettings) {
                SettingsView()
            }
            .sheet(isPresented: $showDetailedStats) {
                NavigationStack {
                    StatisticsView()
                        .navigationTitle("Statistics")
                        .navigationBarTitleDisplayMode(.large)
                        .toolbar {
                            ToolbarItem(placement: .cancellationAction) {
                                Button("Done") {
                                    showDetailedStats = false
                                }
                            }
                        }
                }
                .presentationDragIndicator(.visible)
            }
            .alert("Sync Error", isPresented: $showingSyncAlert) {
                Button("OK", role: .cancel) { }
            } message: {
                Text("Failed to sync your data. Please try again later.")
            }
            .onAppear {
                if let username = authManager.username, !username.isEmpty {
                    profileManager.username = username
                }
            }
        }
    }
}

// Remove the CompactStatsSection struct since we're no longer using it

#Preview {
    let rankingManager = MusicRankingManager()
    rankingManager.rankedSongs = [
        Song(id: UUID(), title: "Bohemian Rhapsody", artist: "Queen", albumArt: "A Night at the Opera", sentiment: .love, score: 9.5),
        Song(id: UUID(), title: "Hotel California", artist: "Eagles", albumArt: "Hotel California", sentiment: .love, score: 8.5),
        Song(id: UUID(), title: "Sweet Child O' Mine", artist: "Guns N' Roses", albumArt: "Appetite for Destruction", sentiment: .fine, score: 7.0)
    ]
    
    return ProfileView()
        .environmentObject(UserProfileManager())
        .environmentObject(rankingManager)
        .environmentObject(MusicAPIManager())
        .environmentObject(AuthManager.shared)
}
