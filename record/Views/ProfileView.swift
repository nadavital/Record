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
                    
                    // Sync status
                    CloudSyncStatusView()
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
            .background(Color(.systemGroupedBackground).ignoresSafeArea())
            .navigationTitle("Profile")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        showSettings = true
                    } label: {
                        Image(systemName: "gearshape")
                    }
                }
                
                ToolbarItem(placement: .navigationBarLeading) {
                    if persistenceManager.isSyncing {
                        ProgressView()
                            .tint(.accentColor)
                    } else {
                        Button {
                            syncUserData()
                        } label: {
                            Image(systemName: "arrow.triangle.2.circlepath")
                        }
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
            .alert("Sync Error", isPresented: $showingSyncAlert) {
                Button("OK", role: .cancel) { }
            } message: {
                Text("Failed to sync your data. Please try again later.")
            }
            .onAppear {
                // Update profile with username from auth if needed
                if let username = authManager.username, !username.isEmpty {
                    profileManager.username = username
                }
            }
        }
    }
    
    private func syncUserData() {
        guard let userId = authManager.userId else { return }
        
        persistenceManager.syncWithCloudKit { error in
            if error != nil {
                showingSyncAlert = true
            }
        }
    }
}

// A reusable component to show CloudKit sync status
struct CloudSyncStatusView: View {
    @ObservedObject private var persistenceManager = PersistenceManager.shared
    
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Image(systemName: "icloud")
                    .foregroundColor(.accentColor)
                Text("Cloud Sync")
                    .font(.headline)
                
                Spacer()
                
                if persistenceManager.isSyncing {
                    HStack(spacing: 4) {
                        ProgressView()
                            .scaleEffect(0.8)
                        Text("Syncing...")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                } else {
                    Button {
                        if let userId = AuthManager.shared.userId {
                            persistenceManager.syncWithCloudKit()
                        }
                    } label: {
                        Text("Sync Now")
                            .font(.caption)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 4)
                            .background(Color.accentColor)
                            .foregroundColor(.white)
                            .cornerRadius(8)
                    }
                    .disabled(persistenceManager.isSyncing)
                }
            }
            
            HStack {
                if let lastSyncDate = persistenceManager.lastSyncDate {
                    Text("Last sync: \(formatDate(lastSyncDate))")
                        .font(.caption)
                        .foregroundColor(.secondary)
                } else {
                    Text("Not synced yet")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                Text("Sync your data across devices")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.secondarySystemGroupedBackground))
        )
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .short
        return formatter.localizedString(for: date, relativeTo: Date())
    }
}

#Preview {
    let rankingManager = MusicRankingManager()
    rankingManager.rankedSongs = [        Song(id: UUID(), title: "Bohemian Rhapsody", artist: "Queen", albumArt: "A Night at the Opera", sentiment: .love, score: 9.5),        Song(id: UUID(), title: "Hotel California", artist: "Eagles", albumArt: "Hotel California", sentiment: .love, score: 8.5),        Song(id: UUID(), title: "Sweet Child O' Mine", artist: "Guns N' Roses", albumArt: "Appetite for Destruction", sentiment: .fine, score: 7.0)    ]
    
    return ProfileView()
        .environmentObject(UserProfileManager())
        .environmentObject(rankingManager)
        .environmentObject(MusicAPIManager())
        .environmentObject(AuthManager.shared)
}
