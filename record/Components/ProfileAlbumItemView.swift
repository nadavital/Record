//
//  ProfileAlbumItemView.swift
//  record
//
//  Created by Nadav Avital on 2/24/25.
//

import SwiftUI

struct ProfileAlbumItemView: View {
    let album: UserProfileManager.Album
    @EnvironmentObject var profileManager: UserProfileManager
    let isEditing: Bool
    
    var body: some View {
        VStack {
            // Album artwork
            ZStack {
                if let artworkURL = album.artworkURL {
                    RemoteArtworkView(
                        artworkURL: artworkURL,
                        placeholderText: album.title,
                        cornerRadius: 10,
                        size: CGSize(width: 120, height: 120)
                    )
                } else {
                    // Fallback for albums without artwork URL
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
        .contextMenu {
            // Only show menu items when editing
            if isEditing {
                Button(role: .destructive) {
                    if let index = profileManager.pinnedAlbums.firstIndex(where: { $0.id == album.id }) {
                        profileManager.pinnedAlbums.remove(at: index)
                    }
                } label: {
                    Label("Remove", systemImage: "trash")
                }
            }
        }
    }
}
