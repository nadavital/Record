//
//  AlbumView.swift
//  record
//
//  Created by Nadav Avital on 3/4/25.
//

import SwiftUI

struct AlbumView: View {
    var album: Album
    @EnvironmentObject var profileManager: UserProfileManager
    @EnvironmentObject var musicAPI: MusicAPIManager
    @Binding var isEditingAlbums: Bool
    
    @State private var navigateToAlbumInfo = false
    
    var body: some View {
        VStack(alignment: .center, spacing: 6) {
            // Album artwork
            ZStack(alignment: .topTrailing) {
                NavigationLink(destination: AlbumInfoView(album: album, musicAPI: musicAPI), isActive: $navigateToAlbumInfo) {
                    EmptyView()
                }
                .opacity(0) // Hide the link
                
                RemoteArtworkView(
                    artworkURL: album.artworkURL,
                    placeholderText: album.title,
                    cornerRadius: 8,
                    size: CGSize(width: 100, height: 100)
                )
                .shadow(radius: 2)
                .onTapGesture {
                    if !isEditingAlbums {
                        navigateToAlbumInfo = true
                    }
                }
                
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
                .onTapGesture {
                    if !isEditingAlbums {
                        navigateToAlbumInfo = true
                    }
                }
            
            Text(album.artist)
                .font(.caption2)
                .foregroundColor(.secondary)
                .lineLimit(1)
                .frame(width: 100)
                .multilineTextAlignment(.center)
                .onTapGesture {
                    if !isEditingAlbums {
                        navigateToAlbumInfo = true
                    }
                }
            
            // Display rating if available
            if let rating = profileManager.getAlbumRating(forAlbumId: album.id.uuidString)?.rating,
               rating > 0 {
                HStack(spacing: 2) {
                    StarRatingView(
                        rating: rating,
                        size: 10,
                        spacing: 1
                    )
                    Text(String(format: "%.1f", rating))
                        .font(.system(size: 9))
                        .foregroundColor(.secondary)
                }
                .padding(.top, 2)
            }
        }
    }
}

#Preview {
    @Previewable @State var isEditingAlbums = false
    let album = Album(title: "Sweetener", artist: "Ariana Grande", albumArt: "Sweetener")
    AlbumView(album: album, isEditingAlbums: $isEditingAlbums)
        .environmentObject(UserProfileManager())
        .environmentObject(MusicAPIManager())
}
