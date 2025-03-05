//
//  ProfileView.swift
//  record
//
//  Created by Nadav Avital on 2/25/25.
//

import SwiftUI

struct ProfileView: View {
    @EnvironmentObject var profileManager: UserProfileManager
    @EnvironmentObject var rankingManager: MusicRankingManager
    @EnvironmentObject var authManager: AuthManager
    @State private var isEditingAlbums = false
    @State private var isEditingArtists = false
    @State private var showAlbumPicker = false
    @State private var showArtistPicker = false
    @State private var showSettings = false
    @State private var editingBio = false
    @State private var tempBio = ""
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    // Profile header
                    ProfileHeader()
                        .padding(.horizontal) // Add horizontal padding to match other sections
                    
                    // Album section
                    AlbumSection(
                        isEditingAlbums: $isEditingAlbums,
                        showAlbumPicker: $showAlbumPicker)
                        .padding(.horizontal)
                    // Top artists section
                    ArtistSection(
                        isEditingArtists: $isEditingArtists,
                        showArtistPicker: $showArtistPicker)
                        .padding(.horizontal)
                    // Songs section
                    TopSongsSection()
                        .padding(.horizontal)
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
            .onAppear {
                // Update profile with username from auth if needed
                if let username = authManager.username, !username.isEmpty {
                    profileManager.username = username
                }
            }
        }
    }
}

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
