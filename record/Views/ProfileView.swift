//
//  ProfileView.swift
//  record
//
//  Created by Nadav Avital on 2/24/25.
//

import SwiftUI

// Profile View
struct ProfileView: View {
    @EnvironmentObject var profileManager: UserProfileManager
    @State private var isEditing = false
    
    var body: some View {
        ZStack {
            // Background
            Color.black.opacity(0.2).ignoresSafeArea()
            
            ScrollView {
                VStack(spacing: 20) {
                    // Profile header
                    VStack {
                        // Profile image
                        ZStack {
                            Circle()
                                .fill(
                                    LinearGradient(
                                        gradient: Gradient(colors: [
                                            profileManager.accentColor.opacity(0.3),
                                            profileManager.accentColor.opacity(0.1)
                                        ]),
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                                .frame(width: 120, height: 120)
                                .overlay(
                                    Circle()
                                        .stroke(
                                            LinearGradient(
                                                gradient: Gradient(colors: [
                                                    profileManager.accentColor,
                                                    profileManager.accentColor.opacity(0.5)
                                                ]),
                                                startPoint: .top,
                                                endPoint: .bottom
                                            ),
                                            lineWidth: 2
                                        )
                                )
                                .shadow(color: profileManager.accentColor.opacity(0.5), radius: 10)
                            
                            Text(profileManager.username.prefix(1))
                                .font(.largeTitle)
                                .fontWeight(.bold)
                                .foregroundColor(.white)
                        }
                        
                        // Username
                        Text(profileManager.username)
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                            .padding(.top, 5)
                        
                        // Bio
                        Text(profileManager.bio)
                            .font(.subheadline)
                            .foregroundColor(.white.opacity(0.8))
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)
                            .padding(.top, 2)
                        
                        // Edit button
                        Button(action: {
                            isEditing.toggle()
                        }) {
                            Text(isEditing ? "Done" : "Edit Profile")
                                .font(.footnote)
                                .foregroundColor(.white)
                                .padding(.horizontal, 20)
                                .padding(.vertical, 8)
                                .background(
                                    Capsule()
                                        .fill(profileManager.accentColor.opacity(0.3))
                                        .overlay(
                                            Capsule()
                                                .stroke(profileManager.accentColor.opacity(0.5), lineWidth: 1)
                                        )
                                )
                        }
                        .padding(.top, 10)
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
                    
                    // Theme color chooser (visible when editing)
                    if isEditing {
                        VStack(alignment: .leading, spacing: 10) {
                            Text("Profile Theme")
                                .font(.headline)
                                .foregroundColor(.white)
                            
                            HStack(spacing: 15) {
                                ForEach([
                                    Color(red: 0.94, green: 0.3, blue: 0.9),   // Neon Pink
                                    Color(red: 0.3, green: 0.85, blue: 0.9),   // Cyan
                                    Color(red: 0.9, green: 0.4, blue: 0.4),    // Coral
                                    Color(red: 0.5, green: 0.9, blue: 0.3),    // Lime
                                    Color(red: 0.9, green: 0.7, blue: 0.2)     // Gold
                                ], id: \.self) { color in
                                    Button(action: {
                                        profileManager.accentColor = color
                                    }) {
                                        Circle()
                                            .fill(color.opacity(0.7))
                                            .frame(width: 35, height: 35)
                                            .overlay(
                                                Circle()
                                                    .stroke(Color.white, lineWidth: profileManager.accentColor == color ? 2 : 0)
                                            )
                                            .shadow(color: color.opacity(0.7), radius: 5)
                                    }
                                }
                            }
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
                    
                    // Featured Section
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
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Favorite Albums")
                                .font(.subheadline)
                                .foregroundColor(.white.opacity(0.7))
                            
                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: 15) {
                                    ForEach(profileManager.pinnedAlbums) { album in
                                        VStack {
                                            // Album artwork
                                            ZStack {
                                                RoundedRectangle(cornerRadius: 10)
                                                    .fill(
                                                        LinearGradient(
                                                            gradient: Gradient(colors: [
                                                                profileManager.accentColor.opacity(0.3),
                                                                profileManager.accentColor.opacity(0.1)
                                                            ]),
                                                            startPoint: .topLeading,
                                                            endPoint: .bottomTrailing
                                                        )
                                                    )
                                                    .frame(width: 120, height: 120)
                                                    .overlay(
                                                        RoundedRectangle(cornerRadius: 10)
                                                            .stroke(Color.white.opacity(0.1), lineWidth: 0.5)
                                                    )
                                                
                                                // Vinyl record effect
                                                Circle()
                                                    .fill(Color.black.opacity(0.7))
                                                    .frame(width: 40, height: 40)
                                                    .overlay(
                                                        Circle()
                                                            .stroke(Color.white.opacity(0.2), lineWidth: 1)
                                                    )
                                            }
                                            
                                            Text(album.title)
                                                .font(.caption)
                                                .fontWeight(.medium)
                                                .foregroundColor(.white)
                                                .lineLimit(1)
                                            
                                            Text(album.artist)
                                                .font(.caption2)
                                                .foregroundColor(.white.opacity(0.7))
                                                .lineLimit(1)
                                        }
                                        .frame(width: 120)
                                    }
                                    
                                    if isEditing {
                                        // Add new album button
                                        Button(action: {
                                            // Show album picker
                                        }) {
                                            ZStack {
                                                RoundedRectangle(cornerRadius: 10)
                                                    .stroke(Color.white.opacity(0.3), style: StrokeStyle(lineWidth: 1, dash: [5]))
                                                    .frame(width: 120, height: 120)
                                                
                                                Image(systemName: "plus")
                                                    .font(.title)
                                                    .foregroundColor(.white.opacity(0.7))
                                            }
                                        }
                                        .frame(width: 120)
                                    }
                                }
                                .padding(.horizontal, 2)
                            }
                        }
                        
                        // Top Songs
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Top Songs")
                                .font(.subheadline)
                                .foregroundColor(.white.opacity(0.7))
                                .padding(.top, 10)
                            
                            ForEach(profileManager.pinnedSongs) { song in
                                HStack {
                                    // Album art placeholder
                                    RoundedRectangle(cornerRadius: 6)
                                        .fill(Color.gray.opacity(0.3))
                                        .frame(width: 50, height: 50)
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 6)
                                                .stroke(Color.white.opacity(0.1), lineWidth: 0.5)
                                        )
                                    
                                    VStack(alignment: .leading) {
                                        Text(song.title)
                                            .font(.subheadline)
                                            .foregroundColor(.white)
                                        
                                        Text(song.artist)
                                            .font(.caption)
                                            .foregroundColor(.white.opacity(0.7))
                                    }
                                    
                                    Spacer()
                                    
                                    if isEditing {
                                        Button(action: {
                                            // Remove pinned song
                                        }) {
                                            Image(systemName: "xmark.circle.fill")
                                                .foregroundColor(.white.opacity(0.6))
                                        }
                                    }
                                }
                                .padding(.vertical, 5)
                            }
                            
                            if isEditing {
                                // Add song button
                                Button(action: {
                                    // Show song picker
                                }) {
                                    HStack {
                                        Image(systemName: "plus.circle")
                                        Text("Add Song")
                                    }
                                    .font(.subheadline)
                                    .foregroundColor(profileManager.accentColor)
                                    .padding(.vertical, 10)
                                }
                            }
                        }
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
                .padding()
            }
        }
    }
}

#Preview("Profile View") {
    ProfileView()
        .environmentObject(UserProfileManager())
}
