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
    @State private var isEditing = false
    @State private var showAlbumPicker = false
    @State private var showSongPicker = false
    
    var body: some View {
        ZStack {
            // Background
            Color.black.opacity(0.2).ignoresSafeArea()
            
            ScrollView {
                VStack(spacing: 20) {
                    // Profile header
                    ProfileHeaderView(isEditing: $isEditing)
                    
                    // Theme color chooser (visible when editing)
                    if isEditing {
                        ThemeSelectorView()
                    }
                    
                    // Featured Section
                    pinnedContentSection
                    
                    // Account/Auth section
                    ProfileAuthSection()
                }
                .padding()
            }
        }
        .sheet(isPresented: $showAlbumPicker) {
            AlbumSearchView()
        }
        .sheet(isPresented: $showSongPicker) {
            AddSongView()
        }
        .onAppear {
            // Update profile with username from auth if needed
            if let username = authManager.username, !username.isEmpty {
                profileManager.username = username
            }
        }
    }
    
    private var pinnedContentSection: some View {
        VStack(alignment: .leading, spacing: 15) {
            HStack {
                Text("Pinned to Profile")
                    .font(.headline)
                    .foregroundColor(.white)
                
                Spacer()
                
                if isEditing {
                    Button(action: {
                        // Toggle edit pinned items
                    }) {
                        Text("Change")
                            .font(.footnote)
                            .foregroundColor(profileManager.accentColor)
                    }
                }
            }
            
            // Featured Albums
            ProfileAlbumSection(
                isEditing: $isEditing,
                showAlbumPicker: $showAlbumPicker
            )
            
            // Top Songs
            ProfileSongsSection(
                isEditing: $isEditing,
                showSongPicker: $showSongPicker
            )
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color.white.opacity(0.03))
                .overlay(
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(Color.white.opacity(0.1), lineWidth: 0.5)
                )
        )
    }
}

#Preview {
    ProfileView()
        .environmentObject(UserProfileManager())
        .environmentObject(MusicRankingManager())
        .environmentObject(AuthManager.shared)
}
