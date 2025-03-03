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
    
    // Top 3 songs from ranking manager
    private var topSongs: [Song] {
        return Array(rankingManager.rankedSongs.prefix(3))
    }
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    // Profile header
                    profileHeader
                        .padding(.horizontal) // Add horizontal padding to match other sections
                    
                    // Album section
                    albumSection
                        .padding(.horizontal)
                    
                    // Top artists section
                    artistsSection
                        .padding(.horizontal)
                    
                    // Songs section
                    topSongsSection
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
        .accentColor(profileManager.accentColor)
    }
    
    // Profile header with avatar and bio
    private var profileHeader: some View {
        VStack(spacing: 16) {
            // Avatar
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            gradient: Gradient(colors: [
                                profileManager.accentColor,
                                profileManager.accentColor.opacity(0.7)
                            ]),
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 110, height: 110)
                    .shadow(color: profileManager.accentColor.opacity(0.5), radius: 5)
                
                Text(profileManager.username.prefix(1).uppercased())
                    .font(.system(size: 42, weight: .bold))
                    .foregroundColor(.white)
            }
            
            // Username
            Text(profileManager.username)
                .font(.title2)
                .fontWeight(.bold)
            
            // Bio
            Text(profileManager.bio.isEmpty ? "Add bio in settings" : profileManager.bio)
                .font(.subheadline)
                .foregroundColor(profileManager.bio.isEmpty ? .secondary : .primary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)
        }
        .padding()
        .frame(maxWidth: .infinity)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.secondarySystemGroupedBackground))
        )
    }
    
    // Albums section with horizontal scroll
    private var albumSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header with edit button
            HStack {
                Text("Favorite Albums")
                    .font(.headline)
                
                Spacer()
                
                Button {
                    isEditingAlbums.toggle()
                } label: {
                    Text(isEditingAlbums ? "Done" : "Edit")
                        .font(.subheadline)
                        .foregroundColor(profileManager.accentColor)
                }
            }
            .padding(.horizontal, 4)
            
            // Albums scroll view
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 16) {
                    // Album items
                    ForEach(profileManager.pinnedAlbums) { album in
                        albumView(album: album)
                    }
                    
                    // Add button
                    if isEditingAlbums || profileManager.pinnedAlbums.isEmpty {
                        addAlbumButton
                    }
                }
                .padding(.horizontal, 4)
                .padding(.vertical, 8)
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.secondarySystemGroupedBackground))
        )
    }
    
    // Artists section with selectable artist tiles
    private var artistsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header with edit button
            HStack {
                Text("Favorite Artists")
                    .font(.headline)
                
                Spacer()
                
                Button {
                    isEditingArtists.toggle()
                } label: {
                    Text(isEditingArtists ? "Done" : "Edit")
                        .font(.subheadline)
                        .foregroundColor(profileManager.accentColor)
                }
            }
            .padding(.horizontal, 4)
            
            if profileManager.pinnedArtists.isEmpty {
                Text("Add favorite artists to display here")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .italic()
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.vertical, 16)
                
                if !isEditingArtists {
                    Button {
                        isEditingArtists = true
                    } label: {
                        Text("Add Artists")
                            .fontWeight(.medium)
                            .foregroundColor(.white)
                            .padding(.horizontal, 20)
                            .padding(.vertical, 8)
                            .background(profileManager.accentColor)
                            .cornerRadius(20)
                    }
                    .frame(maxWidth: .infinity, alignment: .center)
                }
            } else {
                // Artist scroll view with horizontal items
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 16) {
                        ForEach(profileManager.pinnedArtists) { artist in
                            artistView(artist: artist)
                        }
                        
                        // Add button
                        if isEditingArtists {
                            addArtistButton
                        }
                    }
                    .padding(.horizontal, 4)
                    .padding(.vertical, 8)
                }
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.secondarySystemGroupedBackground))
        )
    }
    
    // Top Songs from rankings section
    private var topSongsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Top Songs")
                    .font(.headline)
                
                Spacer()
            }
            .padding(.horizontal, 4)
            
            if topSongs.isEmpty {
                Text("Add songs to your rankings to display here")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .italic()
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.vertical, 16)
            } else {
                // Songs list - limited to top 3
                VStack(spacing: 12) {
                    ForEach(Array(zip(topSongs.indices, topSongs)), id: \.1.id) { index, song in
                        RankedSongRow(
                            rank: index + 1,
                            song: song,
                            onDelete: { _ in /* No deletion from profile view */ },
                            onChangeSentiment: { _ in /* No sentiment change from profile view */ }
                        )
                    }
                }
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.secondarySystemGroupedBackground))
        )
    }
    
    // Individual album view
    private func albumView(album: Album) -> some View {
        VStack(alignment: .center, spacing: 6) {
            // Album artwork
            ZStack(alignment: .topTrailing) {
                RemoteArtworkView(
                    artworkURL: album.artworkURL,
                    placeholderText: album.title,
                    cornerRadius: 8,
                    size: CGSize(width: 100, height: 100)
                )
                .shadow(radius: 2)
                
                // Delete button (only when editing)
                if isEditingAlbums {
                    Button {
                        if profileManager.pinnedAlbums.firstIndex(where: { $0.id == album.id }) != nil {
                            withAnimation {
                                profileManager.removePinnedAlbum(album) // Use manager method for persistence
                            }
                        }
                    } label: {
                        Image(systemName: "minus.circle.fill")
                            .font(.system(size: 22))
                            .foregroundColor(.red)
                            .background(
                                Circle()
                                    .fill(Color.white)
                                    .frame(width: 16, height: 16)
                            )
                    }
                    .offset(x: 6, y: -6)
                }
            }
            
            // Album info
            Text(album.title)
                .font(.caption)
                .fontWeight(.medium)
                .lineLimit(1)
                .frame(width: 100)
                .multilineTextAlignment(.center)
            
            Text(album.artist)
                .font(.caption2)
                .foregroundColor(.secondary)
                .lineLimit(1)
                .frame(width: 100)
                .multilineTextAlignment(.center)
        }
    }
    
    // Artist view for displaying favorite artists
    private func artistView(artist: Artist) -> some View {
        ArtistTileView(
            artist: artist,
            size: 85,
            showDeleteButton: isEditingArtists,
            accentColor: profileManager.accentColor,
            onDelete: { artist in
                profileManager.removePinnedArtist(artist)
            }
        )
    }
    
    // Add album button
    private var addAlbumButton: some View {
        Button {
            showAlbumPicker = true
        } label: {
            VStack {
                ZStack {
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(Color.secondary.opacity(0.5), style: StrokeStyle(lineWidth: 1, dash: [5]))
                        .frame(width: 100, height: 100)
                    
                    Image(systemName: "plus")
                        .font(.system(size: 30))
                        .foregroundColor(profileManager.accentColor)
                }
                
                Text("Add Album")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
    }
    
    // Add artist button
    private var addArtistButton: some View {
        Button {
            showArtistPicker = true
        } label: {
            VStack {
                ZStack {
                    Circle()
                        .stroke(Color.secondary.opacity(0.5), style: StrokeStyle(lineWidth: 1, dash: [5]))
                        .frame(width: 85, height: 85)
                    
                    Image(systemName: "plus")
                        .font(.system(size: 30))
                        .foregroundColor(profileManager.accentColor)
                }
                
                Text("Add Artist")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
    }
}

#Preview {
    ProfileView()
        .environmentObject(UserProfileManager())
        .environmentObject(MusicRankingManager())
        .environmentObject(AuthManager.shared)
}
