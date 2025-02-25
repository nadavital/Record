//
//  ProfileView.swift
//  record
//
//  Created by Nadav Avital on 2/24/25.
//

import SwiftUI

struct ProfileView: View {
    @EnvironmentObject var profileManager: UserProfileManager
    @EnvironmentObject var rankingManager: MusicRankingManager
    @EnvironmentObject var authManager: AuthenticationManager
    @State private var isEditing = false
    @State private var showAlbumPicker = false
    @State private var showSongPicker = false
    @State private var showSignOutConfirmation = false
    
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
                    
                    // Account Section
                    accountSection
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
        .confirmationDialog(
            "Sign Out",
            isPresented: $showSignOutConfirmation,
            titleVisibility: .visible
        ) {
            Button("Sign Out", role: .destructive) {
                authManager.signOut()
            }
            
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("Are you sure you want to sign out of Record?")
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
    
    private var accountSection: some View {
        VStack(alignment: .leading, spacing: 15) {
            Text("Account")
                .font(.headline)
                .foregroundColor(.white)
            
            // Account info
            VStack(spacing: 15) {
                accountRow(icon: "person.fill", label: "Username", value: profileManager.username)
                
                Divider()
                    .background(Color.white.opacity(0.1))
                
                if let email = authManager.currentUser?.email {
                    accountRow(icon: "envelope.fill", label: "Email", value: email)
                    
                    Divider()
                        .background(Color.white.opacity(0.1))
                }
                
                // Sign out button
                Button(action: {
                    showSignOutConfirmation = true
                }) {
                    HStack {
                        Image(systemName: "arrow.right.square")
                            .font(.system(size: 18))
                            .foregroundColor(.red.opacity(0.8))
                            .frame(width: 30)
                        
                        Text("Sign Out")
                            .foregroundColor(.red.opacity(0.8))
                        
                        Spacer()
                        
                        Image(systemName: "chevron.right")
                            .font(.caption)
                            .foregroundColor(.white.opacity(0.5))
                    }
                    .contentShape(Rectangle())
                }
            }
            .padding()
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
    
    private func accountRow(icon: String, label: String, value: String) -> some View {
        HStack {
            Image(systemName: icon)
                .font(.system(size: 18))
                .foregroundColor(profileManager.accentColor)
                .frame(width: 30)
            
            Text(label)
                .foregroundColor(.white)
            
            Spacer()
            
            Text(value)
                .foregroundColor(.white.opacity(0.7))
        }
    }
}

#Preview("Profile View") {
    ProfileView()
        .environmentObject(UserProfileManager())
        .environmentObject(MusicRankingManager())
        .environmentObject(AuthenticationManager())
}
